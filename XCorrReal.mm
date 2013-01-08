//
//  XCorrReal.m
//  vDSPxcorr
//
//  Created by Kunal Kandekar on 12/23/12.
//  Copyright (c) 2012 Kunal Kandekar. All rights reserved.
//

#import "float.h"
#import "XCorrReal.h"
#import "FFTReal.h"

//C++ Wrapper over vdspxcorr real xcorr

XCorrReal::XCorrReal(int nSamples1, int nSamples2, XCORR_REAL_PREALLOC preAlloc, float *templateSamples) {
    xcorr = xcr_alloc(nSamples1, nSamples2, preAlloc, templateSamples);
}

XCorrReal::~XCorrReal() {
    xcr_free(xcorr);
}

int XCorrReal::getBufferSize() {
    return xcr_get_buf_size(xcorr);
}

int XCorrReal::getComplexBufferSize() {
    return xcr_get_complexbuf_size(xcorr);
}

int XCorrReal::getResultBufferSize() {
    return xcr_get_result_size(xcorr);
}

// xcorr arbitrary samples using internal buffers
int XCorrReal::crossCorrelate(float *samples1,
                              int nSamples1,
                              float *samples2,
                              int nSamples2,
                              float *coeffs) {
    return xcr_xcorr(xcorr, samples1, nSamples1, samples2, nSamples2, coeffs);
}

int XCorrReal::preprocessTemplate(float *samples1, int nSamples1) {
    return xcr_prep_template(xcorr, samples1, nSamples1);
}

int XCorrReal::preprocessSamples(float *samples1, int nSamples1, float *bufr, float *bufi, bool conj, int zeroCopy) {
    return xcr_prep_samples(xcorr, samples1, nSamples1, bufr, bufi, conj, zeroCopy);
}

int XCorrReal::crossCorrelateTemplateWith(float *samples2, int nSamples2, float *coeffs) {
    return xcr_xcorr_template_with(xcorr, samples2, nSamples2, coeffs);
}


int XCorrReal::crossCorrelatePreprocessed(float *bufnr,
                                          float *bufni,
                                          float *bufhr,
                                          float *bufhi,
                                          float *bufcr,
                                          float *bufci,
                                          float *coeffs) {
    return xcr_xcorr_prepped(xcorr, bufnr, bufni, bufhr, bufhi, bufcr, bufci, coeffs);
}

int XCorrReal::findPeakIndexInBuffer(float *coeffs, int coeffSize, float *maxVal) {
    return xcr_find_peak(xcorr, coeffs, coeffSize, maxVal);
}
