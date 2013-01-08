//
//  TestXCorr.m
//  vDSPxcorr
//
//  Created by Kunal Kandekar on 1/7/13.
//
//

#include <sys/time.h>

#import "TestXCorr.h"
#import "XCorrReal.h"


static uint64_t get_time_usec(void) {
    struct timeval time;
    if(gettimeofday(&time, NULL) < 0) {
        return 0;
    }
    return (time.tv_sec * 1000 * 1000) + time.tv_usec;
}

@implementation TestXCorr


@synthesize nSamples1;
@synthesize seed1;
@synthesize amplitude1;
@synthesize nSamples2;
@synthesize seed2;
@synthesize amplitude2;
@synthesize offset;
@synthesize numReps;

-(id)init
{
    self = [super init];
    if(self){
        nSamples1   = 128;
        seed1       = 23;
        amplitude1  = 1.0;
        nSamples2   = 512;
        seed2       = 23;
        amplitude2  = 2.0;
        offset      = 131;
        numReps     = 1;
    }
    return self;
}


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

-(int)checkResultsPeakValue:(float)maxCoeff
                    atIndex:(int)peak
                  timeTaken:(uint64_t)time_usec
                   overReps:(int)reps
                 expectedAt:(int)expOffset
                   inLength:(int)nSamples
                usingMethod:(NSString*)method
{
    int ret = 0;
    double avg_time_usec = (double)time_usec/reps;
    if(peak == expOffset) {
        NSLog(@"Using %@ avg %3.3f usec over %d runs: SUCCESS! Found peak %f at index %d == offset %d",
              method, avg_time_usec, reps, maxCoeff, peak, expOffset);
        ret = 1;
    }
    else {
        int absError = abs(peak - expOffset);
        float relError = ((100.0 * absError) / nSamples);
        if(relError < 10.0) {
            NSLog(@"Using %@ averaged %3.3f usec over %d runs: CLOSE! Found peak %f at index %d != offset %d, minor error = %d (%f %%)",
                  method, avg_time_usec, reps, maxCoeff, peak, expOffset, absError, relError);
        }
        else {
            NSLog(@"Using %@ averaged %3.3f usec over %d runs: UH-OH! Found peak %f at index %d != offset %d, significant error of %d (%f %%)",
                  method, avg_time_usec, reps, maxCoeff, peak, expOffset, absError, relError);
        }
        ret = 0;
    }
    return ret;
}

-(int) testXCorrNoInternalAlloc
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
    
    float *coefXCor = (float*)malloc(xcorrBufSize * sizeof(float));
    float *coefConv = (float*)malloc(xcorrBufSize * sizeof(float));

    //fill with random samples
    srand((uint32_t)seed1);
    for (int i = 0; i < nSamples1; i++) {
        buf1[i] = amplitude1 * (rand() % 100) / 100.0f / 2;
    }
    
    srand((uint32_t)seed2);
    for (int i = 0; i < nSamples2; i++) {
        buf2[i] = amplitude2 * (rand() % 100) / 100.0f / 2;
    }
    
    //add template at known offset
    for (int i = 0; i < nSamples1; i++) {
        buf2[offset + i] += buf1[i];
    }

    int xcorrSize = 0;
    uint64_t t1 = get_time_usec();
    double noOpt = 0;   //to avoid optimizing stuff out
    for(int i = 0; i < numReps; i++) {
        xcorr->preprocessSamples(buf1, nSamples1, buf1Real, buf1Imag, TRUE);
        xcorr->preprocessSamples(buf2, nSamples2, buf2Real, buf2Imag, FALSE);
        
        xcorrSize = xcorr->crossCorrelatePreprocessed(buf1Real, buf1Imag,
                                                      buf2Real, buf2Imag,
                                                      xcorReal, xcorImag,
                                                      coefXCor);
        noOpt += coefXCor[0];
    }
    uint64_t t2 = get_time_usec();
    NSLog(@"noOpt=%f", noOpt);

//    [TestXCorr logArray:buf1 ofSize:nSamples1 andType:@"buf1"];
//    [TestXCorr logArray:buf2 ofSize:nSamples2 andType:@"buf2"];
//    [TestXCorr logArray:coeffs ofSize:xcorrSize andType:@"xcor"];
    
    float maxCoeff = 0.0;
    int peak = xcorr->findPeakIndexInBuffer(coefXCor, xcorrSize, &maxCoeff);
    
    int ret = [self checkResultsPeakValue:maxCoeff
                                  atIndex:peak
                                timeTaken:((double)(t2 - t1)/numReps)
                                 overReps:numReps
                               expectedAt:offset
                                 inLength:nSamples2
                              usingMethod:@"vDSPxcorr"];
    
    //confirm and compare with vDSP_conv
    uint64_t t3 = get_time_usec();
    for(int i = 0; i < numReps; i++) {
        vDSP_conv (buf2, 1, buf1, 1, coefConv, 1, xcorrBufSize, nSamples1);
        noOpt += coefConv[0];
    }
    uint64_t t4 = get_time_usec();

    peak = xcorr->findPeakIndexInBuffer(coefConv, xcorrSize, &maxCoeff);
    ret = [self checkResultsPeakValue:maxCoeff
                              atIndex:peak
                            timeTaken:(t4 - t3)
                             overReps:numReps
                           expectedAt:offset
                             inLength:nSamples2
                          usingMethod:@"vDSP_conv"];
    NSLog(@"noOpt=%f", noOpt);
    free(buf1);
    free(buf2);
    
    free(buf1Real);
    free(buf1Imag);
    free(buf2Real);
    free(buf2Imag);
    free(xcorReal);
    free(xcorImag);
    free(coefXCor);
    free(coefConv);
    delete xcorr;
    
    return ret;
}

-(int) testXCorrWithInternalAlloc
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
    
    float *coefXCor = (float*)malloc(xcorrBufSize * sizeof(float));
    float *coefConv = (float*)malloc(xcorrBufSize * sizeof(float));
    
    //fill with random samples
    srand((uint32_t)seed1);
    for (int i = 0; i < nSamples1; i++) {
        buf1[i] = amplitude1 * (rand() % 100) / 100.0f / 2;
    }
    
    srand((uint32_t)seed2);
    for (int i = 0; i < nSamples2; i++) {
        buf2[i] = amplitude2 * (rand() % 100) / 100.0f / 2;
    }
    
    //add template at known offset
    for (int i = 0; i < nSamples1; i++) {
        buf2[offset + i] += buf1[i];
    }
    
    int xcorrSize = 0;
    double noOpt = 0;   //to avoid optimizing stuff out
    uint64_t t1 = get_time_usec();
    for(int i = 0; i < numReps; i++) {
        xcorr->preprocessTemplate(buf1, nSamples1);
        xcorrSize = xcorr->crossCorrelateTemplateWith(buf2, nSamples2, coefXCor);

        noOpt += coefXCor[0];
    }
    uint64_t t2 = get_time_usec();
    NSLog(@"noOpt=%f", noOpt);

//    [TestXCorr logArray:buf1 ofSize:nSamples1 andType:@"buf1"];
//    [TestXCorr logArray:buf2 ofSize:nSamples2 andType:@"buf2"];
//    [TestXCorr logArray:coeffs ofSize:xcorrBufSize andType:@"xcor"];
    
    float maxCoeff = 0.0;
    int peak = xcorr->findPeakIndexInBuffer(coefXCor, xcorrBufSize, &maxCoeff);
    int ret = [self checkResultsPeakValue:maxCoeff
                                  atIndex:peak
                                timeTaken:(t2 - t1)
                                 overReps:numReps
                               expectedAt:offset
                                 inLength:nSamples2
                              usingMethod:@"vDSPxcorr"];
    
    //confirm with vDSP_conv
    uint64_t t3 = get_time_usec();
    for(int i = 0; i < numReps; i++) {
        vDSP_conv (buf2, 1, buf1, 1, coefConv, 1, xcorrBufSize, nSamples1);

        noOpt += coefConv[0];
    }
    uint64_t t4 = get_time_usec();
    peak = xcorr->findPeakIndexInBuffer(coefConv, xcorrSize, &maxCoeff);

    ret = [self checkResultsPeakValue:maxCoeff
                              atIndex:peak
                            timeTaken:(t4 - t3)
                             overReps:numReps
                           expectedAt:offset
                             inLength:nSamples2
                          usingMethod:@"vDSP_conv"];
    NSLog(@"noOpt=%f", noOpt);
    free(buf1);
    free(buf2);    
    free(coefXCor);
    free(coefConv);

    delete xcorr;

    return ret;
}


@end
