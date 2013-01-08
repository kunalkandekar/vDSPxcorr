//
//  FFTReal.m
//  vDSPxcorr
//
//  Created by Kunal Kandekar on 12/23/12.
//  Copyright (c) 2012 Kunal Kandekar. All rights reserved.
//

#import "FFTReal.h"

//C++ Wrapper over vdspxcorr real fft

FFTWindow::FFTWindow(int sz, FFT_WINDOW_TYPE wt) {
    fftwin = fftwin_alloc(sz, wt);
}

float FFTWindow::getGainOffset() {
    return fftwin_gain_offset(fftwin);
}

FFTWindow::~FFTWindow() {
    fftwin_free(fftwin);
}

FFTReal::FFTReal(uint32_t N, bool alloc) {
    fftr = fftreal_alloc(N, alloc);
    NSLog(@"1D real FFT of length log2 ( %d ) = %d\n\n", fftr->n, fftr->log2n);
    if (fftr->setupReal == NULL) {
        NSLog(@"\nFFT_Setup failed to allocate enough memory  for the real FFT.\n");
    }
}

FFTReal::~FFTReal() {
    fftreal_free(fftr);
}

uint32_t FFTReal::getFFTSize() {
    return fftreal_get_fft_size(fftr);
}

uint32_t FFTReal::getComplexBufferSize() {
    return fftreal_get_complexbuf_size(fftr);
}

COMPLEX_SPLIT* FFTReal::getComplexBuffer() {
    return fftreal_get_complexbuf(fftr);
}

void FFTReal::conjugateComplexBuffer() {
    fftreal_conj_complexbuf(fftr);
}


void FFTReal::applyWindow(FFTWindow *window, float *samples, int size, int numChannels) {
    fftreal_apply_win(fftr, window->fftwin, samples, size, numChannels);
}

void FFTReal::applyGainOffset(FFTWindow *window, float *samples, int size) {
    fftreal_apply_gain_offset(fftr, window->fftwin, samples, size);
}

int FFTReal::fftFwd(float *input) {
    return fftreal_fft_fwd(fftr, input);
}

int FFTReal::fftFwd(float *input, float *real, float *imag) {
    return fftreal_fft_fwdtos(fftr, input, 1, real, imag);
}

int FFTReal::fftFwd(float *input, int stride, float *real, float *imag) {
    return fftreal_fft_fwdtos(fftr, input, stride, real, imag);
}

int FFTReal::fftInv(float *output) {
    return fftreal_fft_inv(fftr, output);
}

int FFTReal::fftInv(float *real, float *imag, float *output) {
    return fftreal_fft_invints(fftr, real, imag, output, 1);
}

int FFTReal::fftInv(COMPLEX_SPLIT *C, float *output) {
    return fftreal_fft_invcs(fftr, C, output, 1);
}

int FFTReal::fftInv(float *real, float *imag, float *output, int stride) {
    return fftreal_fft_invints(fftr, real, imag, output, stride);
}

int FFTReal::fftInv(COMPLEX_SPLIT *C, float *output, int str) {
    return fftreal_fft_invcs(fftr, C, output, 1);
}

void FFTReal::scaleFFTComplexToMag(float *mag) {
    fftreal_scale_fft_complex_mag(fftr, mag);    
}

void FFTReal::complexBufferToMagnitude(float *mag, int size) {
    fftreal_complexbuf_to_mag(fftr, mag, size);
}
