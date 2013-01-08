//
//  TestXCorr.h
//  vDSPxcorr
//
//  Created by Kunal Kandekar on 1/7/13.
//
//

#import <Foundation/Foundation.h>

@interface TestXCorr : NSObject

-(int) testXCorrNoAllocSampleLength1:(int)nSamples1 seed1:(long)seed1 amplitude1:(float)ampl1
                           andLength2:(int)nSamples2 seed2:(long)seed2 amplitude2:(float)ampl2
                             atOffset:(int)offset;

-(int) testXCorrInternalAllocSampleLength1:(int)nSamples1 seed1:(long)seed1 amplitude1:(float)ampl1
                                 andLength2:(int)nSamples2 seed2:(long)seed2 amplitude2:(float)ampl2
                                   atOffset:(int)offset;
@end
