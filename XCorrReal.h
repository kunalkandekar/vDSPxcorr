//
//  XCorrReal.h
//  vDSPxcorr
//
//  Created by Kunal Kandekar on 12/23/12.
//  Copyright (c) 2012 Kunal Kandekar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>

#import "FFTReal.h"

//C++ Wrapper over vdspxcorr real xcorr

class XCorrReal {
private:
    XCORR_REAL *xcorr;

public:
    XCorrReal(int nSamples1, int nSamples2,
              XCORR_REAL_PREALLOC preAlloc = XCORR_REAL_INTERNAL_ALLOC_NO,
              float *templateSamples = NULL);
    ~XCorrReal();
    
    int getBufferSize();
    
    int getComplexBufferSize();
    
    int getResultBufferSize();
    

    // pre-process (i.e. FFT and conjugate) a "template" of samples into a re-usable buffer for repeat xcorrs
    int preprocessTemplate(float *samples1, int nSamples1);
    
    int crossCorrelateTemplateWith(float *samples2, int nSamples2, float *coeffs);

    // xcorr arbitrary samples using internal buffers
    int crossCorrelate(float *samples1, int nSamples1,
                       float *samples2, int nSamples2,
                       float *coeffs);

    //int normalizedCrossCorrelateWithHaystack(float * x, int lx, float *c, int lc);

    // More efficient methods using pre-zeroed buffers and zero-copy
    int preprocessSamples(float *samples1, int nSamples1,
                          float *bufr, float *bufi,
                          bool conj);
    
    int preprocessSamples(float *samples1, int nSamples1,
                          float *bufr, float *bufi,
                          bool conj, int zero);
    
    int crossCorrelatePreprocessed(float *bufnr, float *bufni,
                                   float *bufhr, float *bufhi,
                                   float *bufcr, float *bufci,
                                   float *coeffs);

    //naive peak finder
    int findPeakIndexInBuffer(float *coeffs, int coeffSize, float *maxVal);
};
