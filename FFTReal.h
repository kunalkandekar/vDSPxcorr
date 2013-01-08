//
//  FFTReal.h
//  vDSPxcorr
//
//  Created by Kunal Kandekar on 12/23/12.
//  Copyright (c) 2012 Kunal Kandekar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>

#include "vdspxcorr.h"

//C++ Wrapper over vdspxcorr real fft

class FFTWindow {
public:
    FFT_WINDOW *fftwin;
    FFTWindow(int sz, FFT_WINDOW_TYPE wtype);
    float getGainOffset();
    ~FFTWindow();
};

class FFTReal {
private:
//FFT control block
    FFT_REAL *fftr;
public:

    FFTReal(uint32_t N, bool alloc=FALSE);
    
    ~FFTReal();

    uint32_t getFFTSize();
    uint32_t getComplexBufferSize();

    COMPLEX_SPLIT* getComplexBuffer();
    void conjugateComplexBuffer();
    void applyWindow(FFTWindow *window, float *samples, int size, int numChannels);
    void applyGainOffset(FFTWindow *window, float *samples, int size);
    void scaleFFTComplexToMag(float *mag);
    void complexBufferToMagnitude(float *mag, int size);

    int fftFwd(float *input);
    int fftFwd(float *input, float *real, float *imag);
    int fftFwd(float *input, int stride, float *real, float *imag);
    int fftInv(float *output);
    int fftInv(float *real, float *imag, float *output);
    int fftInv(float *real, float *imag, float *output, int str);
    int fftInv(COMPLEX_SPLIT *C, float *real);
    int fftInv(COMPLEX_SPLIT *C, float *real, int stride);
};
