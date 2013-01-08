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

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
