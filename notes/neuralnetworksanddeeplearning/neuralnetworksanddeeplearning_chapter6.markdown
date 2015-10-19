http://neuralnetworksanddeeplearning.com/chap6.html


# Deep Learning 

#### Chapter 6

Sections

- Deep convolutional networks
- 

## Introducing convolutional networks

Adjacent networks (every node is connected to every node in output layer) does not take into account 

Convolutional networks create a spatial architecture that allows the training of deep, many-layer networks, which are very good at classifying images.

#### Local receptive fields

In the fully-connected layers shown earlier, the inputs were depicted as a vertical line of neurons.

In a convNet, it'll help to think of inputs as a square 2D array of neurons.


In the fully-connected layers shown earlier, the inputs were depicted as a vertical line of neurons.

In a convNet, it'll help to think of inputs as a square 2D array of neurons.

In the fully-connected layers shown earlier, the inputs were depicted as a vertical line of neurons.

In a convNet, it'll help to think of inputs as a square 2D array of neurons.

![2D input](../resources/2D_input.png)

Next we connect input pixels to a layer of hidden neurons (but not every input pixel to every hidden neuron).

Instead, we only make connections in small localized regions of the input image.

~~local receptive field~~ for hidden neuron is the region in the input image. Each connection learns a weight and the hidden neuron learns an overall bias as well.

'learning to analyze its particular local receptive field.'

![local receptive field](../resources/local_receptive_field.png)


![initial local receptive field](../resources/local_receptive_field_00.png)

![initial local receptive field shifted 1](../resources/local_receptive_field_01.png)

Here we have a 28x28 input image and we shrink it to 24x24 neurons.

This shift is called the **stride length** and can be larger than one (Atari deep network is).

#### Shared weights and biases

We are using the ~~same weights~~ and bias for each of the 24x24 neurons.

![same weight sum](../resources/same_weight_sum.png)


Here, sigma is the neural activation function (sigmoid function)

b is the shared value for the bias.

w\_(l,m) is a 5x5 array of shared weights

a\_(x,y) to denote the input activation at position x,y

**All neurons in the first hidden layer detect exactly the same feature** - just at different locations in the input image.

This allows us to be well adapted to the translation invariance of images.

We call the map from the input layer to the hidden layer a **feature map**.

We call the weigts defining the feature map **shared weights**.

Shared bias is **shared bias**

Shared weights and bias define a ~~kernel~~ or ~~filter~~.

#### Tying it together

The network structure described can detect a single localized feature. We need more than one feature map.

**A complete convolutional layer consists of several different feature maps**

![different feature maps](../resources/different_feature_maps.png)

An early ConvNet, LeNet-5, used 6 feature maps to recognize MNIST digits.

Some of the features that are learned:

![feature maps](../resources/feature_maps.png)

We see many of these feature maps have sub-regions of light and dark. These are the spacial structures.

- Matthew Zeiler and Rob Fergus paper 
http://arxiv.org/abs/1311.2901 - paper on understanding feature maps results

- Big advantage of sharing weights and biases: reduces number of parameters.

Example

For each feature map we have 25 = (5 x 5) shared weights, plus a bias. If we have 20 feature maps the total = 520 = (20 x 26).

By comparison - fully connected fist layer has 784 = 28 x 28 input neurons and a 'relatively modest' 30 hidden neurons, we have 784x30 + 30 weights for 23,550 parameters.

Faster training allows us to build deep networks using convolutional layers.

#### Pooling layers

ConvNet also contains ~~pooling layers~~.

Task: Simplify the information in the output from the convolutional layer.

A pooling layer takes each **feature map** output from the convolutional layer and prepares a condensed feature map.

We summarize a region of neurons in previous layer. Commonly, max pooling is used where the maximum activation in the region is output.

![max pooling](../resources/max_pooling.png)

We apply this to each feature map.

![map max pooling](../resources/max_pooling.png)

'max-pooling is asking whether a given feature is found anywhere in a region of the image'

**intuition**: once a feature has been found, the exact location isn't as important as its rough location relative to other features.

#### other pooling used:

- L2 Pooling: take the square root of the sum of the squares
- Use these options for detailed optimization of the network

### Putting it all together:

Because our example is looking at the 10 digits we have 10 output neurons

![output neurons](../resources/output_neurons.png)

The final layer of connections in the networks is a fully-connected layer.

Taining the network using stochastic gradient descent and backpropagation.
































































	

