> This paper was spawned by the realization that Solidity does not have support for [[Complex Numbers]] and thus cannot easily support [[Fast Fourier Transform]] without first building the ability to support complex numbers.


```python
def dct(f, n):
    # Compute the Discrete Cosine Transform of a function f
    # using symetric properties of the Fourier Transform
    # f: function
    # n: number of points
    # return: Discrete Cosine Transform of f

    # Compute the Discrete Cosine Transform of f
    F = []
    for k in range(n):
        # Compute the Discrete Cosine Transform of f at point k
        F.append(0)
        for x in range(n):
            F[k] += f(x) * np.cos(np.pi * k * (x + 0.5) / n)
        F[k] *= np.sqrt(2 / n)
    return F

def idct(F, n):
    # Compute the inverse Discrete Cosine Transform of a function F
    # using symetric properties of the Fourier Transform
    # F: Discrete Cosine Transform of a function
    # n: number of points
    # return: inverse Discrete Cosine Transform of F

    # Compute the inverse Discrete Cosine Transform of F
    f = []
    for x in range(n):
        # Compute the inverse Discrete Cosine Transform of F at point x
        f.append(0)
        for k in range(n):
            f[x] += F[k] * np.cos(np.pi * k * (x + 0.5) / n)
        f[x] *= np.sqrt(2 / n)
    return f
```