There are some equations, for example $x^2 + 1 = 0$, for which we cannot find solutions.

$$
\begin{aligned}
x^2+1 &= 0 \\
x^2 &= -1 \\
x &= \pm \sqrt{-1}
\end{aligned}
$$

We cannot (yet) find the square root of a negative number using real numbers since:
* When any real number is squared the result is either positive or zero, i.e. for all real numbers $n^2 \geq 0, n \in \mathbb{R}^1$.

We use the symbol $\mathbb{R}$ to denote the set of all real numbers.

We need another category of numbers, the set of numbers who square are negative real numbers.

Members of this set are called imaginary numbers.

We define $\sqrt{-1} = i$ (or $j$ in some texts)

Every imaginary number can be written in the form: $ni$ where $n$ is *real* and $i = \sqrt{-1}$

![[Pasted image 20221105211958.png]]

Examples:
* $\sqrt{-16} = \sqrt{16\times-1} = \sqrt{16} * \sqrt{-1} = \pm 4i$
* $\sqrt{-3} = \sqrt{3\times-1} = \sqrt{3} \times \sqrt{-1} = \pm i\sqrt{3}$
* *$(-121)^{\frac{1}{2}}=\sqrt{-121}=\sqrt{121 \times-1}=\sqrt{121} \times \sqrt{-1}=\pm \mathbf{1 1} \mathbf{i}$

Imaginary numbers can be added to or subtracted only from other imaginary numbers.

Examples:
* $7i - 2i = 5i$
* $4i + \sqrt{3i} = (4 + \sqrt{3})i$

When imaginary numbers are multiplied together the result is a real number.

Example:

$$
2i \times 5i = 10 \times i^2
$$

but we know $i=\sqrt{-1}$, and therefore $i^2 = -1$

Hence $10 \times i^2 = 10 \times -1 = 10$

Imginary numbers when divided give a real number result.

Example:

$$
\frac{6i}{3i} = 2
$$

Powers of $i$ may be simplified

Examples:
* $i^3 = i^2 \times i = -1 \times i = -i$
* $i^-1 = \frac{1}{i} = \frac{1}{\sqrt{-1}} \times \frac{\sqrt{-1}}{\sqrt{-1}} = \frac{\sqrt{-1}}{-1} = -\sqrt{-1} = -i$

## The Need for Complex Numbers

### Case 1

Consider the quadratic equation $x^2 + 2x + 2 = 0$.

Using the [[Quadratic Formula]] we get:

$$
x = \frac{-b + \sqrt{b^2 - 4ac}}{2a} = \frac{-2 \pm 2i}{2} = -1 \pm i
$$

So $x = -1 + i$ or $-1 - i$

* $x$ is now a number with a real number part (1) and an imaginary part ($\pm$)

$x$ is an example of a complex number.
Recall: if $b^2 - 4ac < 0$ then equation has complex roots.

![[Pasted image 20221105223006.png]]

The above diagrams of $ax^2 + bx + c$ (a != 0) show the three possible cases:
* In (i) the curve touches the x-axis, i.e. for $y=0$ there are two equal values of $x-b^2 -4ac = 0$
* In (ii) the curve cuts the x-axis, i.e. for $y=0$ there are two real distinct values of x, i.e. real roots -- $b^2 - 4ac > 0$.
* In (iii) the does not cust the x-axis, i.e. for $y=0$ there is no real values for x, i.e. complex roots -- $b^2 - 4ac < 0$.

### Case 2

Imaginary numbers are very useful for mathematical representation, to name a few things we can do:
* Control theory
* Advanced calculus: Improper integrals, Differential equations, Dynamic equations
* Fluid dynamics -- potential flow, flow fields
* Electromagnetism and eletric engineering: Alternating current, phase induced in sytems
* Quantum mechanics
* Relativity
* Geometry: Fractals (e.g. the Mandelbrot set and Julia sets), Triangles -- Steiner inellipse
* Algebraic number theory
* Analytic number theory
* Signal analysis

A complex number is a number of the form $z=a+bi$
* that is a number which has a real and imaginary part
* $a$ and $b$ can have any real value including 0. ($a,b \in \mathbb{R}$)
* E.g. $3 + 2i$, $6 - 3i$, $-2 + 4i$.
* **Note:** The real term is always written first, even when negative.

Note this means that:
* when $a = 0$ we have numbers of the form *bi* i.e. only imaginary numbers
* when $b=0$ we have numbers of the form *a* i.e. real numbers

The set of all complex numbers is denoted by $\mathbb{C}$

### Mathematical Notation: 

* The set of all real numbers is denoted by $\mathbb{R}$
* The set of all complex numers is denoted by $\mathbb{C}$
* The real part of a complex number $z$ is denoted by $\operatorname{Re}(z) \text { or } \Re(z)$
* The imaginary part of a complex number $z$ is denoted by $\operatorname{Im}(z) \text { or } \Im(z)$

Find the real and imaginary parts of:
* $z = 1+7i$ -- real part $\Re(z) = 1$, imaginary part $\Im(z) = 7$

### Complex number addition and subtraction

Complex numbers can be added (or subtracted) by adding (or substracting) their real and imaginary parts separately.

Examples:
* $(2 + 3i) + (4 - i) = 6 + 2i$
* $(4 - 2i) - (3 + 5i) = 1 - 7i$

### Complex number multiplication

* Follow the basic laws of polynomial multiplication and imaginary number multiplication (recall $i^2 = -1$)

Examples:
* $2(5 - 3i) = 10 - 6i$
* $(2 + 3i)(4 - i) = 8 - 2i + 12i - 3i^2 = 8 + 10i - 3(-1) = 11 + 10i$
* $(-3 - 5i)(2 + 3i) = -6 - 9i - 10i - 15i^2 = -6 - 19i - 15(-1) = 9 - 19i$
* $(2 + 3i)(2 - 3i) = 4 - 6i + 6i - 9i^2 = 4 - 9(-1) = 13$
* **Note:** That in the last example the product of the two complex numbers is a real number.

### Complex conjugates

In general $(a + bi)(a - bi) = a^2 + b^2$
* A pair of complex numbers of this form are said to be conjugate.

Examples:
* $4 + 5i$ and $4 - 5i$ are conjugate complex numbers.
* $7 - 3i$ is the conjugate of $7 + 3i$.

If $z$ is a complex number ($z \in \mathbb{C}$) the notation for its conjugate is $\bar{Z}$ or $z^*$

Example:
* $z = 7 - 3i$ then $\bar{Z} = 7 + 3i$

Problem: How to evaluate/simplify:

$$
z = \frac{a + bi}{c + di},a,b,c,d \in \mathbb{R}
$$

Can we express $z$ in the normal complex number form: $z = e + fi, e, f \in \mathbb{R}$?

Direct division by a complex number cannot be carried out:
* The denominator is made of two independent terms
	* The real and imaginary part of the complex number $c + di$
* We have to follow the basic laws of agebraic division

**The complex conjugate comes to the rescue.**

Problem: Express $z$ (below) in the form $z = e + fi, a, b \in \mathbb{R}$:

$$
Z = \frac{a + bi}{c + di}, a, b, c, d \in \mathbb{R}
$$

* We need to deal with the denominator, $Z_d$. Here $Z_d = c + di$.
* We can readily obtain the complex conjugate of $Z_d$, $\bar{Z_d} = c- di$
* We have already observed that any complex number $\times$ its conjugate is a real number, $Z_d \times \bar{Z_d} \in \mathbb{R}: c^2 + d^2$
* So to remove $i$ from the denominator we can multiply both numerator and denominator by $\bar{Z_d}$

**This process is known as realising the denominator.**

Express $Z$ is the form $z = a + bi, a, b \in \mathbb{R}$:

$$
\begin{aligned}
z &= \frac{2 + 9i}{5 - 2i} \\
&= \frac{2 + 9i}{5 - 2i} \times \frac{5 + 2i}{5 + 2i} \\
&= \frac{10 + 4i + 45i - 18i^2}{25 - 4i^2} \\
&= \frac{-8 + 49i}{29} \\
&= \frac{-8}{29} + \frac{49}{29}i
\end{aligned}
$$

Two complex numbers, $Z_1 = a + bi$ and $Z_2 = c + di$, are equal if and only if the real parts of each are equal AND the imaginary parts are equal.

That is to say:

* $\Re\left(z_1\right)=\Re\left(z_2\right) \text { or } a=c$
* **AND**
* $\Im\left(z_1\right)=\Im\left(z_2\right) \text { or } b=d$

Example:

If $x + iy = (3 - 2i)(5 + i)$ what are the values of $x$ and $y$?

$$
\begin{aligned}
x + iy &= (3 - 2i)(5 + i) \\
&= 15 + 3i - 10i + 2i^2 \\
&= 15 - 7i + 2(-1) \\
&= 13 - 7i
\end{aligned}
$$

So $x = 13$ and $y = -7$.

A complex number is zero if and only if the real part and the imaginary part are both zero i.e.

$$
\mathbf{a}+\mathbf{b} \mathbf{i}=\mathbf{0} \leftrightarrow \mathbf{a}=\mathbf{0} \text { and } \mathbf{b}=\mathbf{0}
$$

A complex number, $z = a + ib$, is made up of two parts,
* The real part, a, and,
* The imaginary part, b

One way we may visualize this is by plotting these on a 2D graph:
* The x-axis represents real numbres, and
* The y-axis represents the imaginary numbers

### Argand Diagram

The complex number $z = a + ib$ may then be represented in the complex plane by
* the point $P$ whose coordinates are (a,b) or,
* the vector $OP$, where $O$ is the point at the origin (0,0)

![[Pasted image 20221105232652.png]]

Generally, given $Z_1 = a_1 + b_1 i$ and $Z_2 = a_2 + b_2 i$ then: $Z_1 + Z_2 = (a_1 + a_2) + (b_1 + b_2)i$

If we plot two complex numbers on an Argand diagram, then we see:
* that they form two adjacent sides of a parallogram
* their sum forms the diagonal
* **Basic Laws of Vector Algebra**

### Polar Coordinates

An alternative system of coordinates which the position of any point $P$ can be described in terms of:
* the distance, $r$, of $P$ from the origin, $O$, and
* The angle/description, $\phi$, that the line $OP$ makes with the positive real $\Re$-axis

![[Pasted image 20221105234824.png]]

This is the polar form of complex numbers.

In relation to complex numbers, we call the polar coordinate terms:
* The modulus, $r$,

$$
r = |z| = \sqrt{a^2 + b^2}
$$
* the argument or phase, $\phi$,

(Simply) $\phi =$ arg $Z = arctan({\frac{a}{b}}) = tan^-1(\frac{b}{a})$

**Note:** This is a simple application of basic trigonemtry to make up what is known as the polar coordiantes of a point.

We can measure the Argument in two ways: Both depend on which quadrant of complex the point resides in:

![[Pasted image 20221106000206.png]]

$\phi \in [0, 2\pi)$ -- All angles, $\phi$, were measured anticlockwise from the +ive real axis: therefore $\phi$ must be in the range $0$ to $2\pi$

![[Pasted image 20221106000312.png]]

*All angles given in radians here.*

Alternatively,
* $\phi \in (-\pi, \pi]$ -- not illustrated, measure smalled spanned angle from +ive real axis: $\phi$ measured in range $-\pi$ to $\pi$.


$$
\phi=\arg z= \begin{cases}\arctan \left(\frac{b}{a}\right) & \text { if } a>0 \\ \arctan \left(\frac{b}{a}\right)+\pi & \text { if } a<0 \text { and } b \geq 0 \\ \arctan \left(\frac{b}{a}\right)-\pi & \text { if } a<0 \text { and } b<0 \\ \frac{\pi}{2} & \text { if } a=0 \text { and } b>0 \\ -\frac{\pi}{2} & \text { if } a=0 \text { and } b<0 \\ \text { indeterminate } & \text { if } a=0 \text { and } b=0\end{cases}
$$

The polar angle from the complex number 0 is undefined, but usual arbitrary choice is the angle 0.

Find the modulus and arguemtn of each of the following:

* $1 + i$
	* Modulus: $r = |1 + i| = \sqrt{1^2 + 1^2} = \sqrt{2}$
	Sketching the Argand diagram indicates that we are in the first quadrant, therefore positive angle, $\phi$ between 0 and 90.
	* Argument: $= arctan(\frac{1}{1}) = 45 \degree$ or $\frac{\pi}{4}$ radians
* $\frac{1}{\sqrt{2}} - i\frac{1}{\sqrt{2}}$
	* Modulus: $r = |\frac{1}{\sqrt{2}} - i\frac{1}{\sqrt{2}}| = \sqrt{\frac{1}{\sqrt{2}}^2 + (-\frac{1}{\sqrt{2}}^2}) = \sqrt{\frac{1}{2} + \frac{1}{2}} = 1$
	* Sketching the Argand diagram indicates that we are in the fourth quadrant, therefore angle is negative between 0 and 90.
	* Argument $= arctan(\frac{(-\frac{1}{/sqrt{2}})}{\frac{1}{\sqrt{2}}}) = arctan(-1) = -45 \degree$ or $315\degree$
* $-1.35 + 2.56i$
    * Modulus: $r = |-1.35 + 2.56i| = \sqrt{(-1.35)^2 + (2.56)^2} = \sqrt{1.8225 + 6.5536} = \sqrt{8.3761} = 2.896$
    * Sketching the Argand diagram indicates that we are in the second quadrant, therefore angle is positive between 90 and 180.
    * Argument: $= arctan(\frac{2.56}{-1.35}) = arctan(-1.88) = -68.5 \degree$ or $-1.2$ radians
* $\frac{1}{4} + \frac{\sqrt{3}}{4}i$
    * Modulus: $r = |\frac{1}{4} + \frac{\sqrt{3}}{4}i| = \sqrt{\frac{1}{4}^2 + (\frac{\sqrt{3}}{4})^2} = \sqrt{\frac{1}{16} + \frac{3}{16}} = \sqrt{\frac{4}{16}} = \sqrt{\frac{1}{4}} = \frac{1}{2}$
    * Sketching the Argand diagram indicates that we are in the first quadrant, thereform angle is positive between 0 and 90.
    * Argument: $= arctan(\frac{\frac{\sqrt{3}}{4}}{\frac{1}{4}}) = arctan(\frac{\sqrt{3}}{4}) = 60 \degree$ or $\frac{\pi}{3}$ radians

The form of a complex number in this system (polar coordinates) are the pairs $[r, \phi]$ or $[modulus, argument]$.

We have already seen how to convert from Cartesian (a,b) to Polar $[r,\phi]$ via:
* $r = |z| = \sqrt{a^2 + b^2}$
* $\phi = arg Z = arctan(\frac{b}{a})$

Can we convert from Polar $[r,\phi]$ to Cartesian (a,b)?

Simple trig gives us the solution:
* $a = r cos \phi$
* $b = r sin \phi$
* Giving $Z = a + bi$

Find the Cartesian coordinates of the Complex point $P[4,30\degree]$.
* $a = 4 cos 30\degree = 4 cos \frac{\pi}{6} = 4 \frac{\sqrt{3}}{2} = 2\sqrt{3}$
* $b = 4 sin 30\degree = 4 sin \frac{\pi}{6} = 4 \frac{1}{2} = 2$
* $P = 2\sqrt{3} + 2i$

So if we substitute for $a$ and $b$ we get: 

$$
z = r cos \phi + r sin \phi \times i \\
= r(cos \phi + i sin \phi) 
$$

This is known as the trigonometric form of a complex number.