//
//  TestXCorr.m
//  vDSPxcorr
//
//  Created by Kunal Kandekar on 1/7/13.
//
//

#import "TestXCorr.h"
#import "XCorrReal.h"

@implementation TestXCorr

+(void)logArray:(float*)buffer ofSize:(int)size andType:(NSString*)stype
{
    //NSArray  *array = [NSArray arrayWithObjects:@"1", @"2", @"3", nil];
    NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity: size];
    for(int i = 0; i < size; i++) {
        [array addObject: [NSString stringWithFormat: @"%f", buffer[i]]];
    }
    
    NSString *joinedString = [array componentsJoinedByString:@","];
    NSLog(@"%@: %@", stype, joinedString);
}

-(int)checkResultsPeakValue:(float)maxCoeff atIndex:(int)peak expectedAt:(int)offset inLength:(int)nSamples
{
    int ret = 0;
    if(peak == offset) {
        NSLog(@"SUCCESS! Found peak %f at index %d == offset %d", maxCoeff, peak, offset);
        ret = 1;
    }
    else {
        int absError = abs(peak - offset);
        float relError = ((100.0 * absError) / nSamples);
        if(relError < 10.0) {
            NSLog(@"CLOSE! Found peak %f at index %d != offset %d, minor error = %d (%f %%)",
                  maxCoeff, peak, offset, absError, relError);
        }
        else {
            NSLog(@"UH-OH! Found peak %f at index %d != offset %d, significant error of %d (%f %%)",
                  maxCoeff, peak, offset, absError, relError);
        }
        ret = 0;
    }
    return ret;
}

-(int) testXCorrNoAllocSampleLength1:(int)nSamples1 seed1:(long)seed1 amplitude1:(float)ampl1
                          andLength2:(int)nSamples2 seed2:(long)seed2 amplitude2:(float)ampl2
                            atOffset:(int)offset
{
    if(nSamples1 >= (nSamples2 - offset)) {
        NSLog(@"Incorrect input: %d >= (%d - %d)", nSamples1, nSamples2, offset);
        return -1;
    }
    XCorrReal *xcorr = new XCorrReal(nSamples1, nSamples2, XCORR_REAL_INTERNAL_ALLOC_NO);

    //over alloc to make space for zeroes
    int inputBufSize    = xcorr->getBufferSize();
    int complexBufSize  = xcorr->getComplexBufferSize();
    int xcorrBufSize    = xcorr->getBufferSize();
    
    float *buf1 = (float*)malloc(inputBufSize * sizeof(float));
    float *buf2 = (float*)malloc(inputBufSize * sizeof(float));

    bzero(buf1, inputBufSize * sizeof(float));
    bzero(buf2, inputBufSize * sizeof(float));
    
    float *buf1Real = (float*)malloc(complexBufSize * sizeof(float));
    float *buf1Imag = (float*)malloc(complexBufSize * sizeof(float));
    float *buf2Real = (float*)malloc(complexBufSize * sizeof(float));
    float *buf2Imag = (float*)malloc(complexBufSize * sizeof(float));
    float *xcorReal = (float*)malloc(complexBufSize * sizeof(float));
    float *xcorImag = (float*)malloc(complexBufSize * sizeof(float));
    
    float *coeffs = (float*)malloc(xcorrBufSize * sizeof(float));
    
    //fill with random samples
    for (int i = 0; i < nSamples1; i++) {
        buf1[i] = ampl1 * (rand() % 100) / 100.0f / 2;
    }
    
    for (int i = 0; i < nSamples2; i++) {
        buf2[i] = ampl2 * (rand() % 100) / 100.0f / 2;
    }
    
    //add template at known offset
    for (int i = 0; i < nSamples1; i++) {
        buf2[offset + i] += buf1[i];
    }
    
    xcorr->preprocessSamples(buf1, nSamples1, buf1Real, buf1Imag, TRUE, 1);
    xcorr->preprocessSamples(buf2, nSamples2, buf2Real, buf2Imag, FALSE, 1);
    
    int xcorrSize = xcorr->crossCorrelatePreprocessed(buf1Real, buf1Imag,
                                                      buf2Real, buf2Imag,
                                                      xcorReal, xcorImag,
                                                      coeffs);
    
//    [TestXCorr logArray:buf1 ofSize:nSamples1 andType:@"buf1"];
//    [TestXCorr logArray:buf2 ofSize:nSamples2 andType:@"buf2"];
//    [TestXCorr logArray:coeffs ofSize:xcorrSize andType:@"xcor"];
    
    float maxCoeff = 0.0;
    int peak = xcorr->findPeakIndexInBuffer(coeffs, xcorrSize, &maxCoeff);
    
    int ret = [self checkResultsPeakValue:maxCoeff atIndex:peak expectedAt:offset inLength:nSamples2];
    
    free(buf1);
    free(buf2);
    
    free(buf1Real);
    free(buf1Imag);
    free(buf2Real);
    free(buf2Imag);
    free(xcorReal);
    free(xcorImag);
    free(coeffs);
    
    delete xcorr;
    
    return ret;
}

-(int) testXCorrInternalAllocSampleLength1:(int)nSamples1 seed1:(long)seed1 amplitude1:(float)ampl1
                                 andLength2:(int)nSamples2 seed2:(long)seed2 amplitude2:(float)ampl2
                                   atOffset:(int)offset
{
    if(nSamples1 >= (nSamples2 - offset)) {
        NSLog(@"Incorrect input: %d >= (%d - %d)", nSamples1, nSamples2, offset);
        return -1;
    }
    XCorrReal *xcorr = new XCorrReal(nSamples1, nSamples2, XCORR_REAL_INTERNAL_ALLOC_YES);
    
    //over alloc to make space for zeroes
    int xcorrBufSize = xcorr->getResultBufferSize();
    
    float *buf1 = (float*)malloc(nSamples1 * sizeof(float));
    float *buf2 = (float*)malloc(nSamples2 * sizeof(float));
    
    float *coeffs = (float*)malloc(xcorrBufSize * sizeof(float));
    
    //fill with random samples
    for (int i = 0; i < nSamples1; i++) {
        buf1[i] = ampl1 * (rand() % 100) / 100.0f / 2;
    }
    
    for (int i = 0; i < nSamples2; i++) {
        buf2[i] = ampl2 * (rand() % 100) / 100.0f / 2;
    }
    
    //add template at known offset
    for (int i = 0; i < nSamples1; i++) {
        buf2[offset + i] += buf1[i];
    }

    xcorr->preprocessTemplate(buf1, nSamples1);
    xcorr->crossCorrelateTemplateWith(buf2, nSamples2, coeffs);

//    [TestXCorr logArray:buf1 ofSize:nSamples1 andType:@"buf1"];
//    [TestXCorr logArray:buf2 ofSize:nSamples2 andType:@"buf2"];
//    [TestXCorr logArray:coeffs ofSize:xcorrBufSize andType:@"xcor"];
    
    float maxCoeff = 0.0;
    int peak = xcorr->findPeakIndexInBuffer(coeffs, xcorrBufSize, &maxCoeff);
    int ret = [self checkResultsPeakValue:maxCoeff atIndex:peak expectedAt:offset inLength:nSamples2];
    
    free(buf1);
    free(buf2);    
    free(coeffs);
    
    delete xcorr;

    return ret;
}


@end
