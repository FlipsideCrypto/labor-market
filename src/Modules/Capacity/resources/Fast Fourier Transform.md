> This paper was spawned as a research into [[Source Coding Techniques]] and [[Signal Sampling]].

FFT is also the computation of **Discrete Fourier Transforms (DFT)** into an algorithmic format. It is a way to compute Fourier Transforms much faster than using the conventional method. Let us take a look at DFT to get some idea of how FFT makes computing results faster.



$$
\left\{\mathbf{x}_n\right\}:=x_0, x_1, \ldots, x_{N-1}
$$

… to a sequence of another set of [[Complex Numbers]]:

$$
\left\{\mathbf{x}_k\right\}:=x_0, x_1, \ldots, x_{N-1}
$$

Without going over the entire theorem, DFT is basically taking any quantity or signal that varies over time and decomposing it into its components (e.g. frequency). This can be the pixels in an image or the pressure of sound in radio waves (used in DSP chips).

The problem with DFT is that it takes more calculations to arrive at an answer. This is because you have to do _N(multiplications)_ with _N(additions)_, which in _Big O Notation_ is **_O(N²)_** in terms of time complexity.

With FFT we save some steps by reducing the number of calculations in DFT. As a result we can reduce a domain of size N from **_O(N²)_** to **_O(Nlog2N)._**

DFT using FFT can be written using the following formula:

$$
X(k)=\frac{1}{N} \sum_{n=0}^{N-1} x(n) \cdot e^{-j \frac{2 \pi}{N} k n}
$$


We have the discrete signal **x(n)** multiplied with **e** (raised to a function specified) , with **N** representing the size of the domain for the results of the sum of a value **n**.

As the name implies, it is a _fast or a faster_ way to compute Fourier Transforms. This becomes more noticeable when the size of the domain becomes larger. Take for example this table (taken from [**Towards Data Science**](https://towardsdatascience.com/fast-fourier-transform-937926e591cb) article by Cory Maklin):

```python
import numpy as np
```

We will now specify a function and use matrix operations to arrive at the result of the computation.

```python
def dft(x):  
    x = np.asarray(x, dtype=float)  
    N = x.shape[0]  
    n = np.arange(N)  
    k = n.reshape((N, 1))  
    M = np.exp(-2j * np.pi * k * n / N)  
    return np.dot(M, x)
```

Now let us generate a random array of numbers to use with the calculations.

```python
x = np.random.random(1024)
```

Check the value of x:

```python
>>> x
>>> array([0.2100223 , 0.76314102, 0.45883551, ..., 0.75090954, 0.01397708, 0.66781247])**
```


While functional, a major downside of DFTs is that they are incredibly computationally heavy. However, FTT brings a significant discovery. 

With 8 points, one may assume that you need to measure that on the 8 different waves. That's not the case, though. 

***(only cosines shown)***
![[Pasted image 20221105000115.png]]

At the middle data point, all 4 of the odd frequencies have the same value and all 4 of the same frequencies have the same value. So, instead of doing 8 multiplications you only need to do 2. And this sort of duplication occurs at the other data points as well.

So instead of needing to do 64 calculations, one only needs to do 24. This means that instead of an algorithm that scales at $n^2$, FTT scales at $Nlog_2N$.

![[Pasted image 20221105000212.png]]

> While FTT is much more efficient than DFT, it will still be extremely difficult to get a functional implementation at the blockchain level unless it is extremely rudimentary and I implement every high-level piece of math.
> 
> Currently, while there are math libraries there are not high-level implementations as there just hasn't been the need beyond thinks like PDRxMath and Solmate. Ideally given the mathematical primitives already available, all pieces that are needed already exist.

With FTT, there are two clear options, *iterative* or *recursive*. While the land of recursion can be enjoyed in Python and other traditional languages, on-chain with Ethereum there is a long list of reasons that recursion is rarely the right choice. Namely, there is max recursion depth that is extremely shallow as well as the use of recursion can just be extremely cost heavy.

For the best understanding, both are laid out below. To first understand what is actually happening, let's look at the recursive implementation:

```python
**def fft(x):  
	_"""_  
	_A recursive implementation of_  
	_the 1D Cooley-Tukey FFT, the_  
	_input should have a length of_  
	_power of 2._  
	_"""_  
	N = len(x)  
	  
	if N == 1:  return x  

	X_even = fft(x[::2])  
	X_odd = fft(x[1::2])
	
	factor = \  
	np.exp(-2j*np.pi*np.arange(N)/ N)  
	  
	X = np.concatenate(\  
		[X_even+factor[:int(N/2)]*X_odd,  
		X_even+factor[int(N/2):]*X_odd]
	)
		
	return X**
```

Critically though, the usage of FFT with Solidity becomes extremely difficult due to the existence of complex numbers. To manage that, there are a couple of options:

**Use a FFT configuration that only uses and results in normal numbers.**
If your FFt coefficient for a given frequency $f$ is $x + i y$, you can look at $x$ as the coefficient of a cosine at that frequency, while the $y$ is the coefficient of the sine. If you add these two waves for a particular frequency, you will get a phase-shifted wave at the frequency; the magnitude of this wave is $sqrt(x*x + y*y)$, equal to the magnitude of the complex coefficient.