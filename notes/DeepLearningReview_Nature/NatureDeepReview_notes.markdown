
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











