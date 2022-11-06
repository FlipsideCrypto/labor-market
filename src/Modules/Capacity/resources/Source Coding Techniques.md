Source coding is based on the content of the original signal is also called _semantic-based coding_

High compression rates may be high but a price of loss of information. Good compression rates make be achieved with source encoding with _lossless_ or little loss of information.

The 3 key methods of Source Coding are *Transform Coding*, *Frequency Domain Methods* and *Fourier Theory*.

## Transform Coding

### A simple transform coding example

A Simple Transform Encoding procedure maybe described by the following steps for a 2x2 block of monochrome pixels:
1. Take top left pixel as the base value for the block, pixel $A$.
2. Calculate three other transformed values by taking the difference between these (respective) pixels and pixel A, i.e. $B-A, C-A, D-A$.
3. Store the base pixel and the differences as the values of the transform.

Given the above we can easily for the forward transform:

$$
\begin{bmatrix}
A & B \\
C & D
\end{bmatrix}
\rightarrow
\begin{bmatrix}
A & B-A \\
C-A & D-A
\end{bmatrix}
$$

and the inverse transform is:

$$
\begin{bmatrix}
A & B-A \\
C-A & D-A
\end{bmatrix}
\rightarrow
\begin{bmatrix}
A & B \\
C & D
\end{bmatrix}
$$

The above transform scheme may be used to compress data by exploiting redundancy in the data:

Any Redundancy in the data has been transformed to values, $X_i$. So We can compress the data by using fewer bits to represent the differences. I.e if we use 8 bits per pixel then the 2x2 block uses 32 bits/ If we keep 8 bits for the base pixel, $X_0$, and assign 4 bits for each difference then we only use 20 bits. Which is better than an average 5 bits/pixel

For example, consider the following 4x4 image block:

| 120 | 130 |
| --- | --- |
| 125 | 120 |

then we get:

| 120 | 10  |
| --- | --- |
| 5   | -5  | 

The following is a python script that implements the forward and inverse transform:

```python
import numpy as np

def forward_transform(block):
    # Take top left pixel as the base value for the block
    base = block[0, 0]
    # Calculate three other transformed values by taking the difference
    # between these (respective) pixels and pixel A
    block[0, 1] -= base
    block[1, 0] -= base
    block[1, 1] -= base
    return block

def inverse_transform(block):
    # Take top left pixel as the base value for the block
    base = block[0, 0]
    # Calculate three other transformed values by taking the difference
    # between these (respective) pixels and pixel A
    block[0, 1] += base
    block[1, 0] += base
    block[1, 1] += base
    return block
```

We can then compress these values by taking less bits to represent the data. However for practical purposes such a simple scheme as outlined above is not sufficient for compression:

- It is far too simple.
- Needs to operate on larger blocks (typically 8x8 min)
- Calculation is also too simple and from above we see that simple encoding of differences for large values will result in loss of information -- v poor losses possible here 4 bits per pixel = values 0-15 unsigned, -7 - 7 signed so either quantise in multiples of 255/max value or massive overflow!!

---

## Frequency Domain Methods

Frequency domains can be obtained through the transformation from one (Time or Spatial) domain to the other (Frequency) via

-   Discrete Cosine Transform,
-   Fourier Transform etc.

### 1D Example

Lets consider a 1D (e.g. Audio) example to see what the different domains mean:

Consider a complicated sound such as the noise of a car horn. We can describe this sound in two related ways:

-   sample the amplitude of the sound many times a second, which gives an approximation to the sound as a function of time.
-   analyse the sound in terms of the pitches of the notes, or frequencies, which make the sound up, recording the amplitude of each frequency.

In the example below we have a signal that consists of a sinusoidal wave at 8 Hz. 8Hz means that wave is completing 8 cycles in 1 second and is the frequency of that wave. From the frequency domain we can see that the composition of our signal is one wave (one peak) occurring with a frequency of 8Hz with a magnitude/fraction of 1.0 i.e. it is the whole signal.

![[Pasted image 20221105171040.png]]

### 2D (Image) Example

Now images are no more complex really:

Similarly brightness along a line can be recorded as a set of values measured at equally spaced distances apart, or equivalently, at a set of spatial frequency values.

Each of these frequency values is referred to as a _frequency component_.

An image is a two-dimensional array of pixel measurements on a uniform grid.

This information be described in terms of a two-dimensional grid of spatial frequencies.

A given frequency component now specifies what contribution is made by data which is changing with specified _x_ and _y_ direction spatial frequencies.

### What do frequencies mean in an image?

If an image has large values at _high_ frequency components then the data is changing rapidly on a short distance scale. _e.g._ a page of text

If the image has large _low_ frequency components then the large scale features of the picture are more important. _e.g._ a single fairly simple object which occupies most of the image.

For colour images, The measure (now a 2D matrix) of the frequency content is with regard to colour/chrominance: this shows if values are changing rapidly or slowly. Where the fraction, or value in the frequency matrix is low, the colour is changing gradually. Now the human eye is insensitive to gradual changes in colour and sensitive to intensity. So we can ignore gradual changes in colour and throw away data without the human eye noticing, we hope.

### How can transforms into the Frequency Domain Help?

Any function (signal) can be decomposed into purely sinusoidal components (sine waves of different size/shape) which when added together make up our original signal.

In the example below we have a square wave signal that has been decomposed by the Fourier Transform to render its sinusoidal components. Only the first few sine wave components are shown here. You can see that a the Square wave form will be roughly approximated if you add up the sinusoidal components.

![[Pasted image 20221105172226.png]]

Thus Transforming a signal into the frequency domain allows us to see what sine waves make up our signal e.g. One part sinusoidal wave at 50 Hz and two parts sinusoidal waves at 200 Hz.

More complex signals will give more complex graphs but the idea is exactly the same. The graph of the frequency domain is called the frequency spectrum.

An easy way to visualise what is happening is to think of a graphic equaliser on a stereo.

![[Pasted image 20221105172446.png]]

The bars on the left are the frequency spectrum of the sound that you are listening to. The bars go up and down depending on the type of sound that you are listening to. It is pretty obvious that the accumulation of these make up the whole. The bars on the right are used to increase and decrease the sound at particular frequencies, denoted by the numbers (Hz). The lower frequencies, on the left, are for bass and the higher frequencies on the right are treble.

This is directly related to our example before. The bars show how much of the signal is made up of sinusoidal waves at that frequency. When all the waves are added together in their correct proportions that original sound is regenerated.

---

## Fourier Theory

In order to fully comprehend the DCT will do a basic study of the Fourier theory and the Fourier transform first.

Whilst the DCT is ultimately used in multimedia compression it is easier to perhaps comprehend how such compression methods work by studying Fourier theory, from which the DCT is actually derived.

The tool which converts a spatial (real space) description of an image into one in terms of its frequency components is called the **Fourier transform**

The new version is usually referred to as the **Fourier space description** of the image.

The corresponding _inverse_ transformation which turns a Fourier space description back into a real space one is called the **inverse Fourier transform**.

### 1D Case

Considering a continuous function $f(x)$ of a single variable $x$ representing distance.

The Fourier transform of that function is denoted $F(u)$, where $u$ represents spatial frequency is defined by:

$$
F(u)=\int_{-\infty}^{\infty} f(x) e^{-2 \pi i x u} d x
$$

**Note**: In general $F(u)$ will be a complex quantity _even though_ the original data is purely **real**.

The meaning of this is that not only is the magnitude of each frequency present important, but that its phase relationship is too.

The inverse Fourier transform for regenerating $f(x)$ from $F(u)$ is given by:

$$
f(x)=\int_{-\infty}^{\infty} F(u) e^{2 \pi i x u} d u
$$

which is rather similar, except that the exponential term has the opposite sign.

Let's see how we compute a Fourier Transform: consider a particular function $f(x)$ defined as:

$$
f(x)= \begin{cases}1 & \text { if }|x| \leq 1 \\ 0 & \text { otherwise }\end{cases}
$$

![[Pasted image 20221105173236.png]]

So it's Fourier Transform is:

$$
\begin{aligned}
F(\omega) &=\int_{-\infty}^{\infty} f(x) e^{-2 \pi i x \omega} d x \\
&=\int_{-\infty}^{\infty} \begin{cases}1 & \text { if }|x| \leq 1 \\ 0 & \text { otherwise }\end{cases} e^{-2 \pi i x \omega} d x \\
&=\int_{-1}^{1} e^{-2 \pi i x \omega} d x \\
&=\frac{e^{-2 \pi i \omega}-1}{-2 \pi i \omega}
\end{aligned}
$$


In this case $F(u)$ is purely real, which is a consequence of the original data being symmetric in $x$ and $-x$. A graph of $F(u)$ is shown below. This function is often referred to as the Sinc function.

![[Pasted image 20221105173323.png]]

The following is a python script that computes the Fourier Transform of a function taking advantage of the symmetric properties of Fourier Transforms:

```python
def fourier_transform(f, n):
    # Compute the Fourier Transform of a function f
    # using symetric properties of the Fourier Transform
    # f: function
    # n: number of points
    # return: Fourier Transform of f

    # Compute the Fourier Transform of f
    F = []
    for k in range(n):
        # Compute the Fourier Transform of f at point k
        F.append(0)
        for x in range(n):
            F[k] += f(x) * np.exp(-2j * np.pi * k * x / n)
        F[k] /= n
    return F

def inverse_fourier_transform(F, n):
    # Compute the inverse Fourier Transform of a function F
    # using symetric properties of the Fourier Transform
    # F: Fourier Transform of a function
    # n: number of points
    # return: inverse Fourier Transform of F

    # Compute the inverse Fourier Transform of F
    f = []
    for x in range(n):
        # Compute the inverse Fourier Transform of F at point x
        f.append(0)
        for k in range(n):
            f[x] += F[k] * np.exp(2j * np.pi * k * x / n)
    return f

```

### 2D Case

If _f_(_x_,_y_) is a function, for example the brightness in an image, its Fourier transform is given by:

$$
F(u, v)=\int_{-\infty}^{\infty} \int_{-\infty}^{\infty} f(x, y) e^{-2 \pi i(x u+y v)} d x d y
$$

and the inverse transform, as might be expected, is:

$$
f(x, y)=\int_{-\infty}^{\infty} \int_{-\infty}^{\infty} F(u, v) e^{2 \pi i(x u+y v)} d u d v
$$

***(This is outside of my scope and not something I am going to spend time implementing unless needed in the future.)***

### The Discrete Fourier Transform (DFT)

**Images and Digital Audio are digitised !!**
Thus, we need a _discrete_ formulation of the Fourier transform, which takes such regularly spaced data values, and returns the value of the Fourier transform for a set of values in frequency space which are equally spaced.

This is done quite naturally by replacing the integral by a summation, to give the _discrete Fourier transform_ or DFT for short.

In 1D it is convenient now to assume that _x_ goes up in steps of 1, and that there are _N_ samples, at values of _x_ from _0_ to _N_-1.

So the DFT takes the form as:

$$
F(u)=\frac{1}{N} \sum_{x=0}^{N-1} f(x) e^{-2 \pi i x u / N},
$$

while the inverse DFT is:

$$
f(x)=\sum_{u=0}^{N-1} F(u) e^{2 \pi i x u / N}
$$

**NOTE:** Minor changes from the continuous case are a factor of 1/_N_ in the exponential terms, and also the factor 1/_N_ in front of the forward transform which does not appear in the inverse transform.

The 2D DFT works is similar. So for an $N\times M$ grid in $x$ and $y$ we have:

$$
F(u, v)=\frac{1}{N M} \sum_{x=0}^{N-1} \sum_{y=0}^{M-1} f(x, y) e^{-2 \pi i(x u / N+y v / M)}
$$

and

$$
f(x, y)=\sum_{u=0}^{N-1} \sum_{v=0}^{M-1} F(u, v) e^{2 \pi i(x u / N+y v / M)} .
$$

Often $N=M$, and it is then it is more convenient to redefine $F(u,v)$ by multiplying it by a factor of $N$, so that the forward and inverse transforms are more symmetrical:

$$
F(u, v)=\frac{1}{N} \sum_{x=0}^{N-1} \sum_{y=0}^{N-1} f(x, y) e^{-2 \pi i(x u+y v) / N}
$$

and

$$
f(x, y)=\frac{1}{N} \sum_{u=0}^{N-1} \sum_{v=0}^{N-1} F(u, v) e^{2 \pi i(x u+y v) / N}
$$

### Compression

How do we achieve compression:

-   Low pass filter -- ignore high frequency noise components
-   Only store lower frequency components
-   High Pass Filter -- Spot Gradual Changes
-   If changes to low Eye does not respond so ignore?

**Where do put threshold to cut off?**

### Relationship between DCT and FFT

DCT (Discrete Cosine Transform) is actually a _cut-down_ version of the FFT:

-   Only the **real** part of FFT
-   Computationally simpler than FFT
-   DCT -- Effective for Multimedia Compression
-   DCT **MUCH** more commonly used.

---

## The Discrete Cosine Transform (DCT)

The discrete cosine transform (DCT) helps separate the image into parts (or spectral sub-bands) of differing importance (with respect to the image's visual quality). The DCT is similar to the discrete Fourier transform: it transforms a signal or image from the spatial domain to the frequency domain.

![[Pasted image 20221105181950.png]]

**DCT Encoding**
The general equation for a 1D ($N$ data items) DCT is defined by the following equation:

$$
F(u)=\left(\frac{2}{N}\right)^{\frac{1}{2}} \sum_{i=0}^{N-1} \Lambda(i) \cdot \cos \left[\frac{\pi \cdot u}{2 \cdot N}(2 i+1)\right] f(i)
$$

and the corresponding _inverse_ 1D DCT transform is simple $F^{-1}(u)$, i.e.:

where 

$$
\Lambda(i)= \begin{cases}\frac{1}{\sqrt{2}} & \text { for } \xi=0 \\ 1 & \text { otherwise }\end{cases}
$$

The general equation for a 2D (_N_ by _M_ image) DCT is defined by the following equation:

$$
F(u, v)=\left(\frac{2}{N}\right)^{\frac{1}{2}}\left(\frac{2}{M}\right)^{\frac{1}{2}} \sum_{i=0}^{N-1} \sum_{j=0}^{M-1} \Lambda(i) \cdot \Lambda(j) \cdot \cos \left[\frac{\pi \cdot u}{2 \cdot N}(2 i+1)\right] \cos \left[\frac{\pi \cdot v}{2 \cdot M}(2 j+1)\right] \cdot f(i, j)
$$

and the corresponding _inverse_ 2D DCT transform is simple $F^{-1}(u,v)$, i.e.:

where

$$
\Lambda(\xi)= \begin{cases}\frac{1}{\sqrt{2}} & \text { for } \xi=0 \\ 1 & \text { otherwise }\end{cases}
$$

The basic operation of the DCT is as follows:

- The input image is $N$ by $M$;
- $f(i,j)$ is the intensity of the pixel in row i and column j;
- $F(u,v)$ is the DCT coefficient in row k1 and column k2 of the DCT matrix.
- For most images, much of the signal energy lies at low frequencies; these appear in the upper left corner of the DCT.
- Compression is achieved since the lower right values represent higher frequencies, and are often small - small enough to be neglected with little visible distortion.
- The DCT input is an 8 by 8 array of integers. This array contains each pixel's gray scale level;
- 8 bit pixels have levels from 0 to 255.

Therefore an 8 point DCT would be:

where

$$
\Lambda(\xi)= \begin{cases}\frac{1}{\sqrt{2}} & \text { for } \xi=0 \\ 1 & \text { otherwise }\end{cases}
$$


**Question**: What is $F[0,0]$?
**Answer:** They define DC and AC components.

- The output array of DCT coefficients contains integers; these can range from -1024 to 1023.
- It is computationally easier to implement and more efficient to regard the DCT as a set of **basis functions** which given a known input array size (8 x 8) can be precomputed and stored. This involves simply computing values for a convolution mask (8 x8 window) that get applied (summ values x pixelthe window overlap with image apply window accros all rows/columns of image). The values as simply calculated from the DCT formula. The 64 (8 x 8) DCT basis functions are illustrated below.

![[Pasted image 20221105182205.png]]

### DCT basis functions

> Why DCT not FFT?

DCT is similar to the Fast Fourier Transform (FFT), but can approximate lines well with fewer coefficients.

![[Pasted image 20221105182545.png]]

### DCT/FFT Comparison

Computing the 2D DCT
-   Factoring reduces problem to a series of 1D DCTs:
	-   apply 1D DCT (Vertically) to Columns
	-   apply 1D DCT (Horizontally) to resultant Vertical DCT above.
	-   or alternatively Horizontal to Vertical.

The equations are given by:

![](https://users.cs.cf.ac.uk/Dave.Marshall/Multimedia/Topic5.fig_117.gif)


- Most software implementations use fixed point arithmetic. Some fast implementations approximate coefficients so all multiplies are shifts and adds.
- World record is 11 multiplies and 29 adds. (C. Loeffler, A. Ligtenberg and G. Moschytz, "Practical Fast 1-D DCT Algorithms with 11 Multiplications", Proc. Int'l. Conf. on Acoustics, Speech, and Signal Processing 1989 (ICASSP `89), pp. 988-991)

### Differential Encoding

> While this is quite cool in theory I cannot for the live of me figure out how you would actually apply this or rely on it to any extent.

Simple example of transform coding mentioned earlier and instance of this approach.

Here:
- The difference between the actual value of a sample and a prediction of that values is encoded.
- Also known as _predictive encoding_.
- Example of technique include: differential pulse code modulation, delta modulation and adaptive pulse code modulation -- differ in prediction part.
- Suitable where successive signal samples do not differ much, but are not zero. _E.g._ Video -- difference between frames, some audio signals.
- _Differential pulse code modulation_ (DPCM) simple prediction:

$$
f_{\text {predict }}\left(t_i\right)=f_{\text {actual }}\left(t_{i-1}\right)
$$

_i.e._ a simple Markov model where current value is the predict next value.

So we simply need to encode:

$$
\Delta f\left(t_i\right)=f_{\text {actual }}\left(t_i\right)-f_{\text {actual }}\left(t_{i-1}\right)
$$

If successive sample are close to each other we only need to encode first sample with a large number of bits:

**Actual Data:** 9 10 7 6
**Predicted Data:** 0 9 10 7

| Actual Data    | 9   | 10  | 7   | 6   |
| -------------- | --- | --- | --- | --- |
| Predicted Data | 0   | 9   | 10  | 7   | 

$\Delta f(t)$: +9, +1, -3, -1.

- _Delta modulation_ is a special case of DPCM: Same predictor function, coding error is a single bit or digit that indicates the current sample should be increased or decreased by a step.

Not Suitable for rapidly changing signals.

- _Adaptive pulse code modulation_ -- Fuller Markov model: data is extracted from a function of a series of previous values: _E.g._ Average of last _n_ samples. Characteristics of sample better preserved.

## Vector Quantisation

The basic outline of this approach is:

- Data stream divided into (1D or 2D square) blocks -- _vectors_
- A table or _code book_ is used to find a pattern for each block.
- Code book can be dynamically constructed or predefined.
- Each pattern for block encoded as a look value in table
- Compression achieved as data is effectively subsampled and coded at this level.