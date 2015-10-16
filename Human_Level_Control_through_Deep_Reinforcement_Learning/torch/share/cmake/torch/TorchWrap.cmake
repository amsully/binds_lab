MACRO(ADD_TORCH_WRAP target luafile)
  INCLUDE_DIRECTORIES("${CMAKE_CURRENT_BINARY_DIR}")
  GET_FILENAME_COMPONENT(_file_ "${luafile}" NAME_WE)
  SET(cfile "${_file_}.c")
  ADD_CUSTOM_COMMAND(
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${cfile}"
    COMMAND /home/ams/Dropbox/GitHub/binds_lab/Human_Level_Control_through_Deep_Reinforcement_Learning/torch/bin/luajit ARGS "${CMAKE_CURRENT_SOURCE_DIR}/${luafile}" "${CMAKE_CURRENT_BINARY_DIR}/${cfile}"
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    DEPENDS "${luafile}")
  ADD_CUSTOM_TARGET(${target} DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/${cfile}")
ENDMACRO(ADD_TORCH_WRAP)
