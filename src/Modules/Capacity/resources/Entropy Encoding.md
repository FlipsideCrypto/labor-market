## Basics of Information Theory
According to [[#The Shannon-Fano Algorithm]], the entropy (the amount of context carried in a piece of data) of an information source _S_ is defined as:

$H(S)= \eta= -\sum_{i} p_i \log _2 \frac{1}{p_i}$

where $p_i$ is the probability that symbol $S_i$ in $S$ will occur.

- $\log_2 \frac{{\textstyle 1}}{{\textstyle p_i}}$ indicates the amount of information contained in $S_i$, i.e., the number of bits needed to code $S_i$.
-   For example, in an image with uniform distribution of gray-level intensity, i.e. $p_i$ = 1/256 (max value of RGB is 256), then the number of bits needed to code each gray level is 8 bits. The entropy of this image is 8.

**How about an image in which 90% of the pixels are white (I = 220) and 10% are black (I = 10)?**

The probability of white is 9/10 and the probability of black is 1/10. The entropy of this image is 0.468 bits. This is calculated by the formula:

$H = -\sum_{i=1}^n p_i \log_2 p_i$

which expands into the following:

$H = -\frac{9}{10} \log_2 \frac{9}{10} - \frac{1}{10} \log_2 \frac{1}{10} = 0.468$

---

## The Shannon-Fano Algorithm

| Symbol | A   | B   | C   | D   | E   |
| ------ | --- | --- | --- | --- | --- |
| Count  | 15  | 7   | 6   | 6   | 5   | 

**Encoding for the Shannon-Fano Algorithm:**
-   A top-down approach

1. Sort symbols according to their frequencies/probabilities, e.g., ABCDE.
2. Recursively divide into two parts, each with approx. same number of counts.

![[Pasted image 20221105150723.png]]

| Symbol | Count | log(1/p) | Code | Subtotal (# of bits) |
| ------ | ----- | -------- | ---- | -------------------- |
| A      | 15    | 1.38     | 00   | 30                   |
| B      | 7     | 2.48     | 01   | 14                   |
| C      | 6     | 2.70     | 10   | 12                   |
| D      | 6     | 2.70     | 110  | 18                   |
| E      | 5     | 2.96     | 111  | 15                   |

Compress:

```python
>>> symbols = ['A', 'B', 'C', 'D', 'E']
>>> counts = [15, 7, 6, 6, 5]
>>> shannon_fano(symbols, counts)

Symbol     A    B    C    D    E
----------------------------------
Count     15    7    6    6    5
Code      0    10    110    111    1110
```

Decompress:

```python
Symbol     A    B    C    D    E
----------------------------------
Count     15    7    6    6    5
Code      0    10    110    111    1110

>>> decompress('0 10 110 111 1110')

Symbol     A    B    C    D    E
----------------------------------
Count     15    7    6    6    5
```

Process:
```python
def shannon_fano(symbols, counts):
    # Sort symbols according to their frequencies/probabilities
    symbols, counts = zip(*sorted(zip(symbols, counts), key=lambda x: x[1]))
    symbols, counts = list(symbols), list(counts)
    # Recursively divide into two parts, each with approx. same number of counts
    codes = _shannon_fano(symbols, counts)
    # Print results
    print('Symbol\t{}\t'.format('\t'.join(symbols)))

    print('-' * 35)

    print('Count\t{}\t'.format('\t'.join(map(str, counts))))

    print('Code\t{}\t'.format('\t'.join(codes)))

def _shannon_fano(symbols, counts):
    if len(symbols) == 1:
        return ['0']
    elif len(symbols) == 2:
        return ['0', '1']
    else:
        # Find the index of the symbol that divides the list into two parts
        # with approx. same number of counts
        index = _find_divider(symbols, counts)
        # Recursively divide into two parts
        codes = _shannon_fano(symbols[:index], counts[:index]) + \
                _shannon_fano(symbols[index:], counts[index:])
        # Add '0' to the first half and '1' to the second half
        return ['0' + code for code in codes[:index]] + \
                ['1' + code for code in codes[index:]]

def _find_divider(symbols, counts):
    # Find the index of the symbol that divides the list into two parts
    # with approx. same number of counts
    total = sum(counts)
    half = total // 2
    index = 0
    count = 0
    while count < half:
        count += counts[index]
        index += 1
    return index

def decompress(code):
    # Split the code into a list of symbols
    symbols = code.split()
    # Print results
    print('Symbol\t{}\t'.format('\t'.join(symbols)))

    print('-' * 35)

    print('Count\t{}\t'.format('\t'.join(map(str, [1] * len(symbols)))))
```

---

## Huffman Coding

> Huffman Coding is a greedy implementation of the [[#The Shannon-Fano Algorithm]] that focuses on optimizing towards the shortest pieces first which allows for bottom-up building.

| Symbol | A   | B   | C   | D   | E   |
| ------ | --- | --- | --- | --- | --- |
| Count  | 15  | 7   | 6   | 6   | 5   |

Huffman coding is based on the frequency of occurance of a data item (pixel in images). The principle is to use a lower number of bits to encode the data that occurs more frequently. Codes are stored in a _Code Book_ which may be constructed for each image or a set of images. In all cases the code book plus encoded data must be transmitted to enable decoding.

The Huffman algorithm is now briefly summarised:
-   A bottom-up approach

1. Initialization: Put all nodes in an OPEN list, keep it sorted at all times (e.g., ABCDE).
2. Repeat until the OPEN list has only one node left:

* *(a) From OPEN pick two nodes having the lowest frequencies/probabilities, create a parent node of them.
* (b) Assign the sum of the children's frequencies/probabilities to the parent node and insert it into OPEN.
* (c) Assign code 0, 1 to the two branches of the tree, and delete the children from OPEN.

![[Pasted image 20221105154411.png]]

| Symbol | Count | log(1/p) | Code | Subtotal (# of bits) |
| ------ | ----- | -------- | ---- | -------------------- |
| A      | 15    | 1.38     | 0    | 15                   |
| B      | 7     | 2.70     | 100  | 21                   |
| C      | 6     | 2.70     | 101  | 18                   |
| D      | 6     | 2.70     | 110  | 18                   |
| E      | 5     | 2.96     | 111  | 15                   | 

The following points are worth noting about the above algorithm:
-   Decoding for the above two algorithms is trivial as long as the coding table (the statistics) is sent before the data. (There is a bit overhead for sending this, negligible if the data file is big.)
-   **Unique Prefix Property**: no code is a prefix to any other code (all symbols are at the leaf nodes) -> great for decoder, unambiguous.
-   If prior statistics are available and accurate, then Huffman coding is very good.

In the above example the number of bits needed for Huffman Coding is: 

$87 (15+21+18+18+15) / 39 (15+24) = 2.23$

$87$ here coming from the total # of bits while the $39$ comes from the top of the tree that represents all the packed data below it. This is why, Huffman Coding is referred to as *bottom-up*.

Compress:
```python
>>> symbols = ['A', 'B', 'C', 'D', 'E']
>>> counts = [15, 7, 6, 6, 5]
>>> huffman(symbols, counts)

Symbol     A    B    C    D    E
----------------------------------
Count     15    7    6    6    5
Code      0    100    101    110    111
```

Decompress:
```python
Symbol     A    B    C    D    E
----------------------------------
Count     15    7    6    6    5
Code      0    100    101    110    111

>>> decompress('0 100 101 110 111')

Symbol     A    B    C    D    E
----------------------------------
Count     15    7    6    6    5
```

Process:
```python
def huffman(symbols, counts):
    # Sort symbols according to their frequencies/probabilities
    symbols, counts = zip(*sorted(zip(symbols, counts), key=lambda x: x[1]))
    symbols, counts = list(symbols), list(counts)
    # Recursively divide into two parts, each with approx. same number of counts
    codes = _huffman(symbols, counts)
    # Print results
    print('Symbol\t{}\t'.format('\t'.join(symbols)))

    print('-' * 35)

    print('Count\t{}\t'.format('\t'.join(map(str, counts))))

    print('Code\t{}\t'.format('\t'.join(codes)))

def _huffman(symbols, counts):
    if len(symbols) == 1:
        return ['0']
    elif len(symbols) == 2:
        return ['0', '1']
    else:
        # Find the index of the symbol that divides the list into two parts
        # with approx. same number of counts
        index = _find_divider(symbols, counts)
        # Recursively divide into two parts
        codes = _huffman(symbols[:index], counts[:index]) + \
                _huffman(symbols[index:], counts[index:])
        # Add '0' to the first half and '1' to the second half

        # Assign the shortest code to the most frequent symbol
        if len(codes[0]) < len(codes[index]):
            return ['0' + code for code in codes[:index]] + \
                    ['1' + code for code in codes[index:]]
        else:
            return ['1' + code for code in codes[:index]] + \
                    ['0' + code for code in codes[index:]]

def _find_divider(symbols, counts):
    # Find the index of the symbol that divides the list into two parts
    # with approx. same number of counts
    total = sum(counts)
    half = total // 2
    index = 0
    count = 0
    while count < half:
        count += counts[index]
        index += 1
    return index

def decompress(code):
    # Split the code into a list of symbols
    symbols = code.split()

    # Print results
    print('Symbol\t{}\t'.format('\t'.join(symbols)))

    print('-' * 35)

    print('Count\t{}\t'.format('\t'.join(map(str, [1] * len(symbols)))))

```

Huffman Coding is extremely powerful for images.

In order to encode images:
-   Divide image up into 8x8 blocks
-   Each block is a symbol to be coded
-   compute Huffman codes for set of block
-   Encode blocks accordingly

--- 

## Adaptive Huffman Coding
The basic Huffman algorithm has been extended, for the following reasons:

* *(a) The previous algorithms require the statistical knowledge which is often not available (e.g., live audio, video).
* *(b) Even when it is available, it could be a heavy overhead especially when many tables had to be sent when a non-order0 model is used, i.e. taking into account the impact of the previous symbol to the probability of the current symbol (e.g., "qu" often come together, ...).

The solution is to use adaptive algorithms. As an example, the Adaptive Huffman Coding is examined below. The idea is however applicable to other adaptive compression algorithms.

The key is to have both encoder and decoder to use exactly the same _initialization_ and _update_model_ routines.

-   `update_model` does two things: (a) increment the count, (b) update the Huffman tree (Fig [7.2](https://users.cs.cf.ac.uk/Dave.Marshall/Multimedia/node212.html#hufftree)).
    -   During the updates, the Huffman tree will be maintained its _sibling property_, i.e. the nodes (internal and leaf) are arranged in order of increasing weights (see figure).
    -   When _swapping_ is necessary, the farthest node with weight W is swapped with the node whose weight has just been increased to W+1. **Note:** If the node with weight W has a subtree beneath it, then the subtree will go with it.
    -   The Huffman tree could look very different after node swapping (Fig [7.2](https://users.cs.cf.ac.uk/Dave.Marshall/Multimedia/node212.html#hufftree)), e.g., in the third tree, node A is again swapped and becomes the #5 node. It is now encoded using only 2 bits.

![[Pasted image 20221105163459.png]]

![[Pasted image 20221105163507.png]]

**Note:** Code for a particular symbol changes during the adaptive coding process.

While extremely highbrow at first glance, essentially all the *Adaptive* piece of this means is that state is actively updated and *swapped* rather than using a recursive model. This enables single-pass encoding.

![[Pasted image 20221105163705.png]]

Encoding "abb" gives 01100001 001100010 11.

**Step 1:**
Start with an empty tree.

For "a" transmit its binary code.

**Step 2:**
NYT spawns two child nodes: 254 and 255, both with weight 0. Increase weight for root and 255. Code for "a", associated with node 255, is 1.

For "b" transmit 0 (for NYT node) then its binary code.

**Step 3:**
NYT spawns two child nodes: 252 for NYT and 253 for leaf node, both with weight 0. Increase weights for 253, 254, and root. To maintain Vitter's invariant that all leaves of weight w precede (in the implicit numbering) all internal nodes of weight w, the branch starting with node 254 should be swapped (in terms of symbols and weights, but not number ordering) with node 255. Code for "b" is 11.

For the second "b" transmit 11.

For the convenience of explanation this step doesn't exactly follow Vitter's algorithm, (https://en.wikipedia.org/wiki/Adaptive_Huffman_coding#cite_note-:0-2) but the effects are equivalent.

**Step 4:**
Go to leaf node 253. Notice we have two blocks with weight 1. Node 253 and 254 is one block (consisting of leaves), node 255 is another block (consisting of internal nodes). For node 253, the biggest number in its block is 254, so swap the weights and symbols of nodes 253 and 254. Now node 254 and the branch starting from node 255 satisfy the SlideAndIncrement condition (https://en.wikipedia.org/wiki/Adaptive_Huffman_coding#cite_note-:0-2) and hence must be swapped. At last increase node 255 and 256's weight.

Future code for "b" is 1, and for "a" is now 01, which reflects their frequency.

***(I cannot wrap my head around this one and it is extremely complex to achieve with code. Not sure?)***

