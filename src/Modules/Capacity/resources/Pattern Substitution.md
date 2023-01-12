This is a simple form of statistical encoding.

Here we substitue a frequently repeating pattern(s) with a code. The code is shorter than than pattern giving us compression.

A simple Pattern Substitution scheme could employ predefined code (for example replace all occurrences of `The' with the code '&').

More typically tokens are assigned to according to frequency of occurrenc of patterns:

-   Count occurrence of tokens
-   Sort in Descending order
-   Assign some symbols to highest count tokens

A predefined symbol table may used ie assign code _i_ to token _i_.

However, it is more usual to dynamically assign codes to tokens. The entropy encoding schemes below basically attempt to decide the optimum assignment of codes to achieve the best compression.