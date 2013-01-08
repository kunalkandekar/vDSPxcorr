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
so it should also be very fast. (Verified by benchmarks below.)


Furthermore, often a single given sample sequence is needed to be repeatedly
correlated with a number of other sequences (e.g. for matched filtering, or when
seeking the preamble of a wireless transmission, or template matching in computer
vision.) In that case, it's useful to preprocess that signal (essentially, a FFT
and conjugate) and cache those results for re-use when correlating against other
signals. This code lets you optionally allocate internal buffers that can be 
used to cache and re-use intermediate these FFT results.


Note, however, that the setup and constant costs for FFT can be quite high, so 
for small and infrequently processed sequences, vDSP_conv would be the better 
choice in terms of both, performance and ease of use.

Currently, this is only implemented for real samples.


Preliminary Benchmarks
======================
Unless I've made a silly timing mistake somewhere -- please verify my TestXCorr
class implementation! -- the speed-up is stupendous.

Run on MacBook Pro 2.53 GHz Intel Core 2 Duo (4GB RAM, though it does not 
matter here. Results in microseconds, averaged over runs with 100 reps each.

    +-------+-------+------------+-----------+
    |   N1  |   N2  |  vDSP_conv | vDSPxcorr |
    +-------+-------+------------+-----------+
    |     5 |    20 |      0.613 |     0.000 |
    |    10 |    32 |      0.670 |     0.010 |
    |    32 |   128 |      1.303 |     0.010 |
    |   128 |   512 |     27.230 |     0.120 |
    |   256 |  1024 |     92.197 |     0.229 |
    |   256 |  2048 |    207.713 |     0.487 |
    |  1024 |  2048 |    698.617 |     0.450 |
    |  1024 |  4096 |   1398.340 |     1.156 |
    +-------+-------+------------+-----------+

You may notice the vDSPxcorr latencies don't increase linearly. That is because 
the "N" in O(N*LogN) for FFT-based correlation does not increase smoothly with 
N1 and N2. Rather, because of the requirements of the FFT, the N is actually the 
next power of 2 greater than N1 + N2 - 1. Hence N for N1=256, N2=2048 is the 
same as for N1=1024, N2=2048, which is 4096. 

However, for vDSP_conv, the "N" is essentially (N1 + N2). So even though the
operations implemented in vDSP_conv are simple (multiply/add/shift) and very 
fast and vectorized and all, the algorithmic complexity makes it much slower 
than the FFT-based implementation (which, to be fair, internally also uses very
fast, optimized, vectorized instructions for its FFT routines.)


RAW DATA (CSV)
==============
In case anyone is interested…
    Method, N1, N2, Run #1, Run #2, Run #3, 
    vDSPxcorr, 5, 20, 0.000, 0.000, 0.000,
    vDSP_conv, 5, 20, 1.030, 0.400, 0.410,
    vDSPxcorr, 10, 32, 0.010, 0.010, 0.010,
    vDSP_conv, 10, 32, 0.610, 0.710, 0.690,
    vDSPxcorr, 32, 128, 0.010, 0.010, 0.010,
    vDSP_conv, 32, 128, 1.020, 1.460, 1.430,
    vDSPxcorr, 128, 512, 0.100, 0.120, 0.140,
    vDSP_conv, 128, 512, 25.620, 27.480, 28.590,
    vDSPxcorr, 256, 1024, 0.250, 0.210, 0.230,
    vDSP_conv, 256, 1024, 92.910, 91.270, 92.410,
    vDSPxcorr, 256, 2048, 0.530, 0.460, 0.470,
    vDSP_conv, 256, 2048, 187.560, 198.260, 237.320,
    vDSPxcorr, 1024, 2048, 0.450, 0.450, 0.450,
    vDSPxcorr, 1024, 2048, 693.780, 707.230, 694.840,
    vDSPxcorr, 1024, 4096, 1.300, 1.110, 1.060,
    vDSPxcorr, 1024, 4096, 1402.910, 1392.700, 1399.410,

REFERENCES
==========
[1] http://stackoverflow.com/questions/13809552/how-to-check-if-vdsp-function-runs-scalar-or-simd-on-neon
