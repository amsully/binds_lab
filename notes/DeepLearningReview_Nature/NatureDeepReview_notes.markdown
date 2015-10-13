
#Deep learning

Nature Paper - doi:10.1038/nature14539

__Deep Learning__ Representation learning methods with multiple layer, obtained by composing simple but non-linear modules that each transform the representation at one level into a representation at a higher, slightly more abstract layer.

### Supervised Learning

Steps

- Categorize images
- Present Images to Algorithm
- Get rank of categories
- Reward/Punish on Accuracy

To Adjust Accuracy

- Algorithm computes gradient vector that, for each weight, indicates by what amount the error would increase or decrease if incremented.
	- Weight vector is then adjusted opposite 

The Objective Function

- Averaged over all training examples. Can be seen as a kind of hilly landscape in the high dimensional space of weight values.
- Negative gradiant vector indicates direction of steepest descent in this landscape. -> takes it closer to a minimum where the output error is low on average.

In Practice


- We use Stochastic Gradient Descent (works very quickly vs other more optimized solutions)
- After training. Performance is measure on a different set of examples called a 'test set'

Many current applications of machine learning use...

- Linear classifiers on top of hand-engineered features
- two-class linear classifier computes a weighted sum of the feature vector components.
- If the weighted sum is above a threshold the input is classified in a category.

Linear classifiers can only carve input space into simple 'half spaces' separated by hyperplace
	- Not good for differences between wold and samoyed (wolf like dog)

### Multilayer neural networks and backpropagation (Figure 1)

![alt tag](https://github.com/amsully/binds_lab/blob/master/notes/DeepLearningReview_Nature/resources/Figure1.png)

**a.** distortion of inputs to make classes of the data

**b.** chain rule of derivatives
	- small change of x on y and that of y on z (this can be done with derivative of vectors on Jacobian Matrices).

**c.** equation used for forward pass on a neural network
	- with 2 hidden layers and one output layers
		- each layer constituting a module through which one can backpropagate gradients

__At Each Layer:__ compute total input z to each unit, which is a weighted sum of the outputs of the units in the layer below.

- Nonlinear function **f(.)** is applied to z to get the output of the unit.

##### Nonlinear Functions Used:

__rectified linear unit__: (ReLU)f(z) = max(0,z)

__hyperbolic tangent__:

	f(z) = (exp(z) - exp(-z)) / (exp(z)+exp(-z))

__logistic function logic__:
	f(z) = 1 / (1+ exp(-z))

**d.**

(compare outputs w/ correct answer to get error derivatives)

@ each hidden layer we compute error derivatives w/ respect to output which is a weighted sum of the error derivatives w/ respeect to total inputs to the units in the layer above.

**Key Insight:** The derivative of Objective w/ respect to input of a module can be computed by working backwords from the gradient with respect of that module.

- This method is then used repeatedly starting from the top output layer.

Many applications use **feed forward neural network architectures**

- these: learn to map a fixed size input to a fixed size output
	- image -> probability for each of several categories

To go from one layer to the next, a set of units compute a weighted sum of their inputs from the previous layer and pass the result through a non linear function


Most popular non-linearfunction is the rectified linear unit (ReLU), which is simply the half-wave rectifier f(z) = max(z,0)

- ReLU typically learns much faster in networks with many layers, allows for training of a deep supervised network without unsupervised pre-training.

One of the fears for neural networks was an infeasibility to extract features. Also with simple stochastic gradient descent, the fear was getting stuck in local minima .. In practice shown not to be a problem

In General, research has shown that these SGD will reside in a saddle point that will generally be of a similar value as other saddle points around... Hence it does not matter much which saddle points the algorithm gets stuck at.

2006 - Canadian Institute for Advanced Research - research paper introduced unsupervised learning procedures that could create layers of feature detectors. -- worked very well with hand written digits.


2012 - One particular type of deep , feedforward network was much easier to train and was much better at generalizing
- Convolutional Neural Network (ConvNet)


### Convolution Neural Networks

ConvNets: designed to process data that come in the form of multiple arrays
- ie: a color image composed of three 2D arrays containing pixel intensities in the three color channels.
- Data Modalities that are in the form of multiple 2D arrays:
	- 1D for signals and sequences
	- 2D for images or audio spectograms
	- 3D for video or volumetric images

#### 4 Main Ideas behind ConvNets

1. Local Connections
2. Shared Weights
3. Pooling
4. Use of many layers

![alt tag](https://github.com/amsully/binds_lab/blob/master/notes/DeepLearningReview_Nature/resources/Figure2.png)

The architecture is a series of stages.

The first few stages are composed of two types of layers:

1. Convolutional layers
	- organized in feature maps. each unit is connected to local patches in the feature maps of the previous layer through a set of weights called a **filter bank**
	- result of this local weighted sum -> passed through a non-linearity such as a ReLU
	- All units in a feature map share the same filter bank. 
	- Different feature maps in a layer use different filter banks.
		- Reasons:
		- in array data (img), local groupd os values are often Highly Correlated .. forming distinctive local motifs that are easily detected
		- Local statistics of images and other signals are invariant to loation

The filtering operation performed by a feature map is a discrete convolution, hence the name.

Because relative positions of the features forming a motif can vary ... reliably detecting the motif can be done by coarse-graining the position of each filter.

A pooling unit computes the maximum of a local patch of units in one feature map (or a few)

Neighboring pooling units take input from patches that are shifted by more than one row or column, thereby reducing the dimension of the representation and creating an invariance to small shifts and distortions.

2-3 of these stages of convolution, non-linearity, and pooling are stacked, followed by more convolutional and fully connected layers.

Backpropagating gradients through a ConvNet is as simple as through a regular deep network, allowing all the weights in all the filter banks to be trained.


2. Pooling layers

(example) In images, local combinations of edges form motifs, motifs assemble into parts, and parts form objects.

convolutional and pooling layers are directly inspired by simple cells and complex cells in visual neuroscience, and the overall architecture is reminiscent of the LGN-V1-V2-V4-IT (?) hierarchy in the visual cortex ventral pathway.


### Image Understanding with Deep Convolutional Networks

Recent ConvNet architectures have 10-20 layers of ReLUs, hundreds of millions of weights, and billions of connections between units 

Two years ago this would take years to train, now it takes a few hours.

### Distributed representations and language processing

- Learning distributed representations enable generalization to new combinations of the values of learned features beyond those seen during training. 
- Composing layers of representation in a deep net brings the potential for another exponential advantage.
	- The hidden layers of a multilayer neural network learn to represent the networks inputs in a way that makes it easy to predict the target outputs -- example of word prediction

Issue of representation lies at the heart of the debate between log-inspired and neural-network-inspired paradigms for cognition

- Logic inspired: an instance of a symbol is something for which the only property is that it is either identical or non-identical to other symbol instances. It has no internal structure that is relevant to its use, and to reason with symnols, they must be bound to the vairables in judiciously chosen rules of inference.

- neural-network inspired: use big activity vectors, big weight matrices, and scalar non-linearities to perform the type of fast 'intuitive' inferenct that underpins effortless common sense reasoning.

N-Grams vs Neural Language models

N-Grams count the frequency of words, neural language models associate each word with a vector of real valued features, and semantically related words end up close to each other in the vector space.

### Recurrent Neural Networks














