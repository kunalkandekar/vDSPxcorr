vDSPxcorr
=========

High performance FFT-based cross-correlation for C/Objective-C/C++ on iOS and 
OSX using the Accelerate framework.


This essentially is equivalent to vDSP_conv with a positive __vDSP_strideFilter 
argument. Being a optimized, vectorized function, vDSP_conv is very fast. 
However, according to [1], it uses the O(N^2) algorithm (shift-and-mul/acc over
the entire delay range) instead of the FFT-based O(N*LogN) one. 

As a brief refresher, correlation of two signal vectors is exactly equivalent to
the Inverse Fourier Transform of the product of the Fourier Transform of one and
the complex conjugate of the Fourier Transform of the other. (Remember that the
FT, even for real signals, is a complex-valued vector.) That is:

    XCORR(A, B) = IFFT( FFT(A) * CONJ( FFT(B) ) )

As FFT is a O(N*LogN) operation, there is potential for further speed up over the 
O(N^2) vDSP_conv function, and this project provides an FFT-based implementation 
that hopes to do so. It uses the vDSP_* routines from the Accelerate framework, 
so it should also be very fast. [2]


Furthermore, often a single given sample sequence is needed to be repeatedly
correlated with a number of other sequences (e.g. for matched filtering, or when
seeking the preamble of a wireless transmission, or template matching in computer
vision.) In that case, it's useful to preprocess that signal (essentially, a FFT
and conjugate) and cache those results for re-use when correlating against other
signals. This code lets you optionally allocate internal buffers that can be 
used to cache and re-use intermediate these FFT results.


Note, however, that the setup and constant costs for FFT can be quite high, so 
for small sequences, vDSP_conv would be the better choice in terms of both, 
performance and ease of use. I still need to figure out exactly how small 
"small" is though [2].

Currently, this is only implemented for real signals.


[1] http://stackoverflow.com/questions/13809552/how-to-check-if-vdsp-function-runs-scalar-or-simd-on-neon

[2] Verification needed; benchmarks coming soon. 
