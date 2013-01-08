//
//  ViewController.m
//  vDSPxcorr-iOS
//
//  Created by Kunal Kandekar on 1/7/13.
//
//

#import "ViewController.h"

#import "TestXCorr.h"

@interface ViewController ()

@end

@implementation ViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    int seed1 = 23;
    int seed2 = 42;
    
    int offset = 111;
    
    int len1  = 128;    //length of the "needle" sample sequence
    int len2  = 512;    //length of the "haystack" sample sequence

    int ampl1 = 1.0;    //amplitude of the "needle"
    int ampl2 = 5.0;    //amplitude of the "haystack"
    
    int nruns = 100;
    
    // the greater ampl2 is than ampl1 is, the more noise there will be and hence less accurate the results
    // at higher ampl2/ampl1 ratios, using longer sequence lengths len1 should compensate.
    
    bool noIntAlloc = 1;
    
    
    TestXCorr *test = [[TestXCorr alloc] init];
    test.nSamples1  = len1;
    test.seed1      = seed1;
    test.amplitude1 = ampl1;
    test.nSamples2  = len2;
    test.seed2      = seed2;
    test.amplitude2 = ampl2;
    test.offset     = offset;
    test.numReps    = nruns;
    
    int ret = 0;
    if(noIntAlloc) {
        ret = [test testXCorrNoInternalAlloc];
    }
    else {
        ret = [test testXCorrWithInternalAlloc];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
