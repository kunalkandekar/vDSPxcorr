//
//  main.cpp
//  vDSPxcorr-osx
//
//  Created by Kunal Kandekar on 1/7/13.
//
//

#import <Foundation/Foundation.h>

#include <iostream>

#import "TestXCorr.h"

int main(int argc, const char * argv[])
{
    // Test code using cross correlation (implemented using vDSP/Accelerate framework)
    // to find the offset of a known signal (the "needle") in a larger series of
    // samples (the "haystack").
    
    int len1  = 128;    // length of the "needle" sample sequence
    int len2  = 512;    // length of the "haystack" sample sequence

    int offset = 111;
    
    int ampl1 = 1.0;    // amplitude of the "needle"
    int ampl2 = 5.0;    // amplitude of the "haystack"

    int seed1 = 23;     // PRNG "needle" sample sequence
    int seed2 = 42;
    
    
    if(argc > 3) {
        len1    = atoi(argv[1]);
        len2    = atoi(argv[2]);
        offset  = atoi(argv[3]);
        if( (len1 > len2) || (offset > len2) || ((len1 > (len2 - offset))) ) {
            std::cout<<"Please choose lengths and offses correctly (len1 < len2, offset < len2, len1 <= (len2 - offset))"
                    <<std::endl;
            return -1;
        }
    }
           
    if(argc > 5) {
        ampl1 = atof(argv[4]);
        ampl2 = atof(argv[5]);
    }
    
    
    // the greater ampl2 is than ampl1 is, the more noise there will be and hence less accurate the results
    // at higher ampl2/ampl1 ratios, using longer sequence lengths len1 should compensate.
    
    bool noIntAlloc = TRUE;
    
    
    TestXCorr *test = [[TestXCorr alloc] init];
    int ret = 0;
    if(!noIntAlloc) {
        ret = [test testXCorrNoAllocSampleLength1:len1 seed1:seed1 amplitude1:ampl1
                                       andLength2:len2 seed2:seed2 amplitude2:ampl2
                                         atOffset:offset];
    }
    else {
        ret = [test testXCorrInternalAllocSampleLength1:len1 seed1:seed1 amplitude1:ampl1
                                             andLength2:len2 seed2:seed2 amplitude2:ampl2
                                               atOffset:offset];
    }

    return 0;
}

