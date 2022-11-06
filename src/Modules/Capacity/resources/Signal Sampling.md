> Contrary to just compression, signal sampling is often used less for storage and more for direction. While single channel sampling is rather simple, complexity can reach extreme levels when exploring things such as [[Source Coding Techniques]]

Sampling process basically involves: 
* Measuring the analog signal at regular discrete intervals 
* Recording the value at these points


![[Pasted image 20221106013341.png]]

The Sampling Frequency is critical to the accurate reproduction of a digital version of an analog waveform

**Nyquist’s Sampling Theorem**
The Sampling frequency for a signal must be at least twice the highest frequency component in the signal.

**Sampling at Signal Frequency:**
![[Pasted image 20221106013435.png]]

**Sampling at Twice Nyquist Frequency**
![[Pasted image 20221106013445.png]]

**Sampling at above Nyquist Frequency**
![[Pasted image 20221106013540.png]]

* Frequency is the number of cycles per second and is measured in Hertz (Hz)
* Wavelength is inversely proportional to frequency i.e. Wavelength varies as $\frac{1}{frequency}$

The general form of the sine wave we shall use (quite a lot of) is as follows:

$$
y = A.sin(\frac{2\pi.n.F_w}{F_s})
$$

where

$A$ is the amplitude of the wave, $F_w$ is the frequency of the wave, $F_s$ is the sample frequency, $n$ is the sample index.

Sine wave amplitude is -1 to 1. To change the amplitude multiply by some gain (amp):

$$
y = amp \times sin(1)
$$

Natural frequency is $2 \times \pi$ radians

* If sample rate is $F_s$ HZ then 1 HZ is $\frac{2 \times \pi}{F_s}$ set n samples steps up to sum duration $nsec \times F_s$ where nsec is the duration in seconds.
* So we get $y = amp \times sin(\frac{2 \times \ pi \times n \times F_w}{F_s})$

### Relationship Between Amplitude, Frequency and Phase
![[Pasted image 20221106014715.png]]

This results in the ability to create very niche curves such as:

![[Pasted image 20221106014910.png]]

* (a) cos()
* (b) square()
* (c) sawtooth()

## Digital Audio Effectse

This allows us to combine visualize and handle curves with different implementations:

![[Pasted image 20221106015012.png]]

* An analog signal, $x(t)$ with signal amplitude contiuous over time, t.
* Following $ADC$ the signal is converted into a discrete-time and quantised amplitude signal, $x(n)$ -- a stream of samples over discrete time index, n
	* The time distance between two consecutive samples, the sample interval, T (or sampling period)
	* The sampling frequency is $f_s = \frac{1}{T}$ -- the number of samples per second measured in Hertz (Hz)
* Next we apply some simple $DAFX$ -- E.g here we multiply the signal by a factor 0.5 to product $y(n) = 0.5.x(n)$
* The signal $y(n)$ is then forwarded to the dAC which reconstruct an analog signal.

## Decibels

When referring to measures of power or intesity, we express these in decibles (db):

$$
X_dB = 10log_10\frac{X}{X_0}
$$

where:
* $X$ is the actual value of the quantity being measured,
* $X_0$ is a specified or implied reference level,
* $X_dB$ is the quantity expressed in units of decibles, relative to $X_0$.
* $X$ and $X_0$ must have the same dimensions -- they must measure the same type of quantity in the same units.
* The reference level itself is always at 0 dB -- as shown by setting $X = X_0$ (note: $log_{10}(1) =0$

### Why use Decibel Scales

* When there is a large range in frequency or magnitude, logarithm units are often used.
* If $X$ is greater than $X_0$ then $X_dB$ is positive (power increase)
* If $X$ is less than $X_0$ then $X_dB$ is negative (power decrease)
* Power magnitude $= |X(i)|^2$ so (with respect to reference level)

$$
\begin{aligned}
X_{d B} &=10 \log _{10}\left(\left|X(i)^2\right|\right) \\
&=20 \log _{10}(|X(i)|)
\end{aligned}
$$

which is an expression of dB we often come across.

![[Pasted image 20221106015751.png]]

* dB is commonly used to quantify sound levels relative to some 0 dB reference.
* The reference level is typically set the threshold of human perception
* Human ear is capable of detecting a very large range of sound pressures

## Signal to Noise

Signal-to-noise ratio is a term for the power ratio between a signal (meaningful information) and the background noise:

$$
S N R=\frac{P_{\text {signal }}}{P_{\text {noise }}}=\left(\frac{A_{\text {signal }}}{A_{\text {noise }}}\right)^2
$$

where $P$ is average power and $A$ is RMS amplitude.

* Both signal and noise power (or amplitude) must be measured at the same or equivalent points in a system, and within the same system bandwidth.

Because many signals have a very wide dynamic range, SNRs are usually expressed in terms of the logarithmic decibel scale:

$$
S N R_{d B}=10 \log _{10}\left(\frac{P_{\text {signal }}}{P_{\text {noise }}}\right)=20 \log _{10}\left(\frac{A_{\text {signal }}}{A_{\text {noise }}}\right)
$$
