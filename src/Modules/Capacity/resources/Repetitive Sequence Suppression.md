These methods are fairly straight forward to understand and implement. Their simplicity is their downfall in terms of attaining the best compression ratios. However, the methods have their applications, as mentioned below:

## Simple Repitition Supression

If in a sequence a series on _n_ successive tokens appears we can replace these with a token and a count number of occurences. We usually need to have a special _flag_ to denote when the repated token appears

For example we can replace $89400000000000000000000000000000000$ with $894f32$ where f is the flag for zero. This means, that 894 is leading with 32 zeroes following.

Compression savings depend on the content of the data. Applications of this simple compression technique include:

-   Suppression of zero's in a file (_Zero Length Supression_)
    -   Silence in audio data, Pauses in conversation _etc._
    -   [[Bitmaps]]
    -   Blanks in text or program source files
    -   Backgrounds in images
-   other regular image or data tokens

---

## Run-Length Encoding

This encoding method is frequently applied to images (or pixels in a scan line). It is a small compression component used in JPEG compression (Section [7.6](https://users.cs.cf.ac.uk/Dave.Marshall/Multimedia/node234.html#sec:JPEG)).

In this instance, sequences of image elements $X_{1},X_{2},\ldots,X_{n}$ are mapped to pairs $(c_{1},l_{1}),(c_{2},l_{2}),\ldots,(c_{n},l_{n})$ where $c_i$ represent image intensity or colour and $l_i$ the length of the $i$th run of pixels (Not dissimilar to zero length supression above).

For example if original sequence is $111122233333311112222$, then it can be encoded as $(1,4),(2,3),(3,6),(1,4),(2,4)$

The savings are dependent on the data. In the worst case (Random Noise) encoding is more heavy than original file: 2*integer rather 1* integer if data is represented as integers.

> While this type of encoding can be incredibly popular for traditional implementations, when it comes to imagining a use case for this on the blockchain; it is extremely difficult.