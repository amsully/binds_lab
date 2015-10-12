
#Deep learning

__Deep Learning__ Representation learning methods with multiple layer, obtained by composing simple but non-linear modules that each transofrm the representation at on elevel into a representation at a higher, slightly more abstract layer.

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

![alt tag](https://github.com/github/amsully/binds_lab/notes/DeepLearningReview_Nature/Figure1.png )



