
local nesting = paths.dofile('nesting.lua')
local utils = paths.dofile('utils.lua')
local istensor = torch.isTensor
local istable = utils.istable
local istorchclass = utils.istorchclass

local function getTotalGradOutput(node)
   local gradOutput = node.data.gradOutput
   assert(istable(gradOutput), "expecting gradients to sum")
   if #gradOutput > 1 then
      node.data.gradOutputBuffer = node.data.gradOutputBuffer or nesting.cloneNested(gradOutput[1])
      local gobuff = node.data.gradOutputBuffer
      nesting.resizeNestedAs(gobuff, gradOutput[1])
      nesting.fillNested(gobuff, 0)
      for i=1,#gradOutput do
         nesting.addNestedTo(gobuff, gradOutput[i])
      end
      gradOutput = gobuff
   else
      gradOutput = gradOutput[1]
   end
   return gradOutput
end

-- The gModule allows to have a general non-cyclic graph of of modules.
--
-- Each node of the graph can have multiple inputs.
-- The order of inputs is remembered in node.data.mapindex.
--
-- Each node have only one output.
-- The output can be also a table.
-- To route parts of the outputted table to different modules,
-- use the node:split(nOutputs) function.
-- The split will create subnodes with narrowed output.
--
-- Implementation details:
-- The node.data.input holds a list of inputs.
-- If a module expects only one input, the node.data.input[1] is used.
--
-- The node.data.gradOutput holds the to-be-summed gradOutputs.
-- Each node has only one output. So we need only one gradOutput.
local gModule, parent = torch.class('nn.gModule','nn.Module')

function gModule:__init(inputs,outputs)
   parent.__init(self)
   -- the graph is defined backwards, we have the output modules as input here
   -- we will define a dummy output node that connects all output modules
   -- into itself. This will be the output for the forward graph and
   -- input point for the backward graph
   local outnode = nngraph.Node({input={}})
   for i,n in ipairs(outputs) do
      if torch.typename(n) ~= 'nngraph.Node' then
         error(string.format('what is this in the outputs[%s]? %s',
         i, tostring(n)))
      end
      outnode:add(n,true)
   end
   for i,n in ipairs(inputs) do
      if torch.typename(n) ~= 'nngraph.Node' then
         error(string.format('what is this in the inputs[%s]? %s',
         i, tostring(n)))
      end
   end
   -- We add also a dummy input node.
   -- The input node will be split to feed the passed input nodes.
   local innode = nngraph.Node({input={}})
   assert(#inputs > 0, "no inputs are not supported")
   if #inputs == 1 then
      inputs[1]:add(innode,true)
   else
      local splits = {innode:split(#inputs)}
      for i = 1, #inputs do
         assert(#inputs[i].children == 0, "an input should have no inputs")
      end
      for i = 1, #inputs do
         inputs[i]:add(splits[i],true)
      end
   end

   -- the backward graph (bg) is for gradients
   -- the forward graph (fg) is for function evaluation
   self.bg = outnode:graph()
   self.fg = self.bg:reverse()

   -- the complete graph is constructed
   -- now regenerate the graphs with the additional nodes

   local roots = self.fg:roots()
   -- if there are more than one root in the forward graph, then make sure that
   -- extra roots are parameter nodes
   if #roots > 1 then
      local innodeRoot = nil
      -- first find our innode
      for _, root in ipairs(roots) do
         if root.data == innode.data then
            assert(innodeRoot == nil, 'more than one matching input node found in leaves')
            innodeRoot = root
         else
            assert(root.data.module, 'Expected nnop.Parameters node, module not found in node')
            assert(torch.typename(root.data.module) == 'nnop.Parameters',
                  'Expected nnop.Parameters node, found : ' ..torch.typename(root.data.module))
         end
      end
      assert(innodeRoot ~= nil, 'input node not found among roots')
      self.innode = innodeRoot
   else
      assert(#self.fg:roots() == 1, "expecting only one start")
      self.innode = self.fg:roots()[1]
   end


   assert(self.innode.data == innode.data, "expecting the forward innode")
   self.outnode = outnode
   self.verbose = false
   self.nInputs = #inputs

   -- computation on the graph is done through topsort of forward and backward graphs
   self.forwardnodes = self.fg:topsort()
   self.backwardnodes = self.bg:topsort()
   self.modules = {}
   for _, node in ipairs(self.forwardnodes) do
      if node.data.module then
         table.insert(self.modules, node.data.module)
      end
   end
   -- Checking for unused inputs or unused split() outputs.
   for i,forwardNode in ipairs(self.forwardnodes) do
      if forwardNode.data.nSplitOutputs and forwardNode.data.nSplitOutputs ~=  #forwardNode.children then
         local nUnused = forwardNode.data.nSplitOutputs - #forwardNode.children
         error(string.format("%s of split(%s) outputs are unused", nUnused,
         forwardNode.data.nSplitOutputs))
      end
   end
   -- Adding data.forwardNodeId for nicer node:label() output.
   for i,forwardNode in ipairs(self.forwardnodes) do
      forwardNode.data.forwardNodeId = forwardNode.id
   end

   self.output = nil
   self.gradInput = nil
   if #self.outnode.children > 1 then
      self.output = self.outnode.data.input
   end
end

function gModule:map(gm, func)
   for i,node in ipairs(self.forwardnodes) do
      local gmnode = gm.forwardnodes[i]
      assert(gmnode, 'trying to map another gModule with a different structure')
      if node.data.module then
         assert(gmnode.data.module, 'trying to map another gModule with a different structure')
         func(node.data.module, gmnode.data.module)
      end
   end
end

function gModule:clone(...)
   local f = torch.MemoryFile("rw"):binary()
   f:writeObject(self)
   f:seek(1)
   local clone = f:readObject()
   f:close()
   if select('#', ...) > 0 then
      clone:share(self, ...)
   end
   return clone
end

function gModule:share(gm, ...)
   local args = {...}
   self:map(gm,
   function(subnet1, subnet2)
      subnet1:share(subnet2, unpack(args))
   end)
   return self
end

function gModule:training()
   parent.training(self)
   for _, m in ipairs(self.modules) do
      m:training()
   end
end

function gModule:evaluate()
   parent.evaluate(self)
   for _, m in ipairs(self.modules) do
      m:evaluate()
   end
end

function gModule:applyToModules(func)
   for _, m in ipairs(self.modules) do
      func(m)
   end
end

--[[ Recursively applies type(type_str) to any tensors in the argument. If the
argument is a tensor, type(type_str) is applied; if the argument is an array,
this function recurses into it. ]]
local function recursiveType(param, type_str)
   if torch.type(param) == 'table' then
      for i = 1, #param do
         param[i] = recursiveType(param[i], type_str)
      end
   elseif torch.typename(param) and
      torch.typename(param):find('torch%..+Tensor') then
      param = param:type(type_str)
   end
   return param
end

function gModule:type(type, tensorCache)
   tensorCache = tensorCache or {}

   local function applyTypeToTable(table)
      for key, value in pairs(table) do
         table[key] = recursiveType(table[key], type)
      end
   end

   -- Convert any stored data in self, and in the in and out nodes
   applyTypeToTable(self)
   if self.innode then applyTypeToTable(self.innode.data) end
   if self.outnode then applyTypeToTable(self.outnode.data) end

   -- Loop through modules and convert data
   for _, m in ipairs(self.modules) do
      m:type(type, tensorCache)
   end

   for i,node in ipairs(self.backwardnodes) do
      if node.data.gradOutputBuffer ~= nil then
         node.data.gradOutputBuffer = node.data.gradOutputBuffer:type(type)
      end
   end

   return self
end

function gModule:zeroGradParameters()
   for _, m in ipairs(self.modules) do
      m:zeroGradParameters()
   end
end

function gModule:updateOutput(input)
   return self:runForwardFunction('updateOutput',input)
end

function gModule:runForwardFunction(func,input)
   if type(func) == "string" then
      local func_name = func
      func = function(module,input) return module[func_name](module,input) end
   end
   -- For backward compatibility, we allow self.nInputs to be missing.
   local nInputs = self.nInputs or #self.innode.children
   -- We see the input as a list of inputs.
   if nInputs <= 1 then
      input={input}
   elseif type(input) ~= "table" then
      error(string.format("expecting %s inputs", nInputs))
   end
   local function neteval(node)
      local function propagate(node,x)
         for i,child in ipairs(node.children) do
            child.data.input = child.data.input or {}
            local mapindex = child.data.mapindex[node.data]
            assert(not child.data.input[mapindex], "each input should have one source")
            child.data.input[mapindex] = x
         end
      end
      if node.data.selectindex then
         assert(not node.data.module, "the selectindex-handling nodes should have no module")
         local input = node.data.input
         assert(#input == 1, "only the splitted node should be the input")
         assert(istable(input[1]), "the input for a split should be a table")
         input = input[1][node.data.selectindex]
         propagate(node,input)
      else
         local input = node.data.input

         -- a parameter node is captured
         if input == nil and node.data.module ~= nil then
            input = {}
         end
         if #input == 1 then
            input = input[1]
         end
         -- forward through this node
         -- If no module is present, the node behaves like nn.Identity.
         local output
         if not node.data.module then
            output = input
         else
            output = func(node.data.module,input)
         end
         if node.data.nSplitOutputs and node.data.nSplitOutputs ~= #output then
            error(string.format("split(%s) cannot split %s outputs",
            node.data.nSplitOutputs,
            #output))
         end
         -- propagate the output to children
         propagate(node,output)
      end
      if self.verbose then
         print(' V : ' .. node:label())
      end
   end

   local innode = self.innode
   if #input ~= nInputs then
      error(string.format('Got %s inputs instead of %s', #input, nInputs))
   end
   -- first clear the input states
   for _,node in ipairs(self.forwardnodes) do
      local input = node.data.input
      while input and #input>0 do
         table.remove(input)
      end
   end
   -- Set the starting input.
   -- We do copy instead of modifying the passed input.
   innode.data.input = innode.data.input or {}
   for i, item in ipairs(input) do
      innode.data.input[i] = item
   end

   -- the run forward
   for i,node in ipairs(self.forwardnodes) do
      neteval(node)
   end

   self.output = self.outnode.data.input
   if #self.outnode.children == 1 then
      self.output = self.output[1]
   end
   return self.output
end

function gModule:updateGradInput(input,gradOutput)
   local function neteval(node)
      if node.data.selectindex then
         assert(not node.data.module, "the selectindex-handling nodes should have no module")
         assert(#node.children == 1, "only the splitted node should be the input")
         local child = node.children[1]
         local go = getTotalGradOutput(node)
         child.data.gradOutput = child.data.gradOutput or {}
         assert(#child.data.gradOutput <= 1, "the splitted node should be used only once")
         -- The data.gradOutput holds the to-be-summed gradients.
         child.data.gradOutput[1] = child.data.gradOutput[1] or {}
         assert(not child.data.gradOutput[1][node.data.selectindex], "no gradOutput should be assigned yet")
         child.data.gradOutput[1][node.data.selectindex] = go
      else
         local gradOutput = getTotalGradOutput(node)
         -- updateGradInput through this node
         -- If no module is present, the node behaves like nn.Identity.
         local gradInput
         if not node.data.module then
            gradInput = gradOutput
         else
            local input = node.data.input
            -- a parameter node is captured
            if input == nil and node.data.module ~= nil then
               input = {}
            end
            if #input == 1 then
               input = input[1]
            end
            local module = node.data.module
            gradInput = module:updateGradInput(input,gradOutput)
         end
         -- propagate the output to children
         for i,child in ipairs(node.children) do
            child.data.gradOutput = child.data.gradOutput or {}
            local mapindex = node.data.mapindex[child.data]
            local gi
            if #node.children == 1 then
               gi = gradInput
            else
               gi = gradInput[mapindex]
            end
            table.insert(child.data.gradOutput,gi)
         end
      end
      if self.verbose then
         print(' V : ' .. node:label())
      end
   end
   local outnode = self.outnode
   if #outnode.children > 1 and #gradOutput ~= #outnode.children then
      error(string.format('Got %s gradOutputs instead of %s', #gradOutput, #outnode.children))
   end
   for _,node in ipairs(self.backwardnodes) do
      local gradOutput = node.data.gradOutput
      while gradOutput and #gradOutput >0 do
         table.remove(gradOutput)
      end
   end
   -- Set the starting gradOutput.
   outnode.data.gradOutput = outnode.data.gradOutput or {}
   outnode.data.gradOutput[1] = gradOutput

   for i,node in ipairs(self.backwardnodes) do
      neteval(node)
   end

   assert(#self.innode.data.gradOutput == 1, "expecting the innode to be used only once")
   self.gradInput = self.innode.data.gradOutput[1]
   return self.gradInput
end

function gModule:accGradParameters(input,gradOutput,lr)
   local function neteval(node)
      if node.data.module then
         local module = node.data.module
         local gradOutput = node.data.gradOutput[1]
         if #node.data.gradOutput > 1 then
            gradOutput = node.data.gradOutputBuffer
         end
         local input = node.data.input
         -- a parameter node is captured
         if input == nil and node.data.module ~= nil then
            input = {}
         end
         if #input == 1 then
            input = input[1]
         end
         -- accGradParameters through this node
         module:accGradParameters(input,gradOutput,lr)
      end
      if self.verbose then
         print(' V : ' .. node:label())
      end
   end
   local outnode = self.outnode
   if #outnode.children > 1 and #gradOutput ~= #outnode.children then
      error(string.format('Got %s gradOutputs instead of %s', #gradOutput, #outnode.children))
   end
   for i,node in ipairs(self.backwardnodes) do
      neteval(node)
   end
end

function gModule:parameters()
   local p,gp = {},{}
   for _,node in ipairs(self.forwardnodes) do
      if node.data.module then
         local mp,mgp = node.data.module:parameters()
         if mp and mgp then
            for i = 1,#mp do
               table.insert(p,mp[i])
               table.insert(gp,mgp[i])
            end
         end
      end
   end
   return p,gp
end


function gModule:__tostring__()
   return self.name or torch.type(self)
end

