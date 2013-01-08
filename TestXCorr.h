//
//  TestXCorr.h
//  vDSPxcorr
//
//  Created by Kunal Kandekar on 1/7/13.
//
//

#import <Foundation/Foundation.h>

@interface TestXCorr : NSObject {
    int     nSamples1;
    long    seed1;
    float   ampl1;
    int     nSamples2;
    long    seed2;
    float   ampl2;
    int     offset;
    int     numReps;
}

@property (nonatomic) int     nSamples1;
@property (nonatomic) long    seed1;
@property (nonatomic) float   amplitude1;
@property (nonatomic) int     nSamples2;
@property (nonatomic) long    seed2;
@property (nonatomic) float   amplitude2;
@property (nonatomic) int     offset;
@property (nonatomic) int     numReps;


-(int) testXCorrNoInternalAlloc;

-(int) testXCorrWithInternalAlloc;
@end
