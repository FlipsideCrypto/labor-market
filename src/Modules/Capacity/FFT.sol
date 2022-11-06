// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@prb/math/contracts/PRBMathSD59x18.sol";

import { Trigonometry } from "./Trigonometry.sol";

contract FFT { 
    using PRBMathSD59x18 for int256;

    uint256 public constant MAX_UINT256 = 2**256 - 1;

    int256 PI = PRBMathSD59x18.pi();

    function bitReverse(
          uint x
        , uint log2n
    ) 
        public 
        pure 
        returns (
            uint
        ) 
    {
        // Reverse the bits of the index.
        uint n = 0;
        for (uint i = 0; i < log2n; i++) {
            n = (n << 1) | (x & 1);
            x >>= 1;
        }

        return n;
    }

    // Iterative FFT function to compute the DFT
    // of given coefficient vector 'a' of size 'n'
    // with given 'omega' as the root of unity
    function fft(
        int[] memory a,
        uint256 log2n,
        int256 omega
    ) 
        public 
        view 
        returns (
            int256[] memory
        ) 
    {
        uint256 n = 1 << log2n;
        int[] memory y = new int[](n);

        unchecked { 
            // Bit-reverse the input array
            for (
                uint i; 
                i < n; 
                i++
            ) {
                y[bitReverse(i, log2n)] = a[i];
            }

            // // Compute the FFT
            for (
                uint s = 1; 
                s <= log2n; 
                s++
            ) {
                uint m = 1 << s;
                int256 wm = PRBMathSD59x18.pow(omega, int256((n / m)));
                for (
                    uint k = 0; 
                    k < n; 
                    k += m
                ) {
                    int256 w = 1;
                    for (
                        uint j = 0; 
                        j < (m / 2); 
                        j++
                    ) {
                        int256 t = w.mul(y[k + j + (m / 2)]);
                        int256 u = y[k + j];
                        y[k + j] = u + t;
                        y[k + j + (m / 2)] = u - t;
                        w = w.mul(wm);
                    }
                }
            }
        }

        return y;
    }
}