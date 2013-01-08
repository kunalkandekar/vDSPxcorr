//
//  vdspxcorr.h
//  vdspxcorr
//
//  Created by Kunal Kandekar on 1/7/13.
//
//

#ifndef vdspxcorr_vdspxcorr_h
#define vdspxcorr_vdspxcorr_h

#import "Accelerate/Accelerate.h"

#if defined __cplusplus
extern "C" {
#endif

typedef enum FFT_WINDOW_TYPE {
    WINDOW_TYPE_HAN = 1,
    WINDOW_TYPE_HAM = 2,
    WINDOW_TYPE_BLK = 3
} FFT_WINDOW_TYPE;

#define kHannFactor -3.2
#define kHammingFactor 1.0
#define kBlackmanFactor 2.37

/************ FFT Window ************/

typedef struct _FFT_WINDOW {
    FFT_WINDOW_TYPE wtype;
    int size;
    float *coeffs;
} FFT_WINDOW;

FFT_WINDOW *fftwin_alloc(int sz, FFT_WINDOW_TYPE wtype);
void fftwin_free(FFT_WINDOW *win);
float fftwin_gain_offset(FFT_WINDOW *win);

/************ FFT Real ************/

typedef struct _FFT_REAL {
    //FFT control block
    COMPLEX_SPLIT   A;
    FFTSetup        setupReal;
    float           *realp;
    float           *imagp;
    uint32_t        log2n;
    uint32_t        n;
    uint32_t        nOver2;
    int32_t         stride;
    
    float           scale;
} FFT_REAL;


FFT_REAL *fftreal_alloc(uint32_t N, bool alloc);
    
void fftreal_free(FFT_REAL *fftReal);
    
uint32_t fftreal_get_fft_size(FFT_REAL *fftReal);
uint32_t fftreal_get_complexbuf_size(FFT_REAL *fftReal);

COMPLEX_SPLIT* fftreal_get_complexbuf(FFT_REAL *fftReal);
void fftreal_conj_complexbuf(FFT_REAL *fftReal);
void fftreal_apply_win(FFT_REAL *fftReal, FFT_WINDOW *window, float *samples, int size, int numChannels);
void fftreal_apply_gain_offset(FFT_REAL *fftReal, FFT_WINDOW *window, float *samples, int size);
void fftreal_scale_fft_complex_mag(FFT_REAL *fftReal, float *mag);
void fftreal_complexbuf_to_mag(FFT_REAL *fftReal, float *mag, int size);

int fftreal_fft_fwd(FFT_REAL *fftReal, float *input);
int fftreal_fft_fwdto(FFT_REAL *fftReal, float *input, float *real, float *imag);
int fftreal_fft_fwdtos(FFT_REAL *fftReal, float *input, int stride, float *real, float *imag);
int fftreal_fft_inv(FFT_REAL *fftReal, float *output);
int fftreal_fft_invint(FFT_REAL *fftReal, float *real, float *imag, float *output);
int fftreal_fft_invints(FFT_REAL *fftReal, float *real, float *imag, float *output, int stride);
int fftreal_fft_invc(FFT_REAL *fftReal, COMPLEX_SPLIT *C, float *real);
int fftreal_fft_invcs(FFT_REAL *fftReal, COMPLEX_SPLIT *C, float *real, int stride);


/************ XCorrReal ************/
typedef enum XCORR_REAL_PREALLOC {
    XCORR_REAL_INTERNAL_ALLOC_NO  = 0,
    XCORR_REAL_INTERNAL_ALLOC_YES = 1,
} XCORR_REAL_PREALLOC;

typedef struct _XCORR_REAL {
	int size;
    int complex_buf_size;
    int buf_size_bytes;
    int max_samples_in;
    int max_samples1;
    int max_samples2;
	FFT_REAL *fft;
    
	float *buf;
	float *bufxr;
	float *bufxi;
	float *bufy;
    float *bufyr;
	float *bufyi;
	float *bufc;
    
    COMPLEX_SPLIT cN;
    COMPLEX_SPLIT *N;
} XCORR_REAL;


XCORR_REAL *xcr_alloc(int nsamples1, int nsamples2, XCORR_REAL_PREALLOC preAlloc, float *tsamples);
void xcr_free(XCORR_REAL *xcorr);
    
int xcr_get_buf_size(XCORR_REAL *xcorr);

int xcr_get_complexbuf_size(XCORR_REAL *xcorr);

int xcr_get_result_size(XCORR_REAL *xcorr);

// pre-process (i.e. FFT and conjugate) a "template" of samples into a re-usable buffer for repeat xcorrs
int xcr_prep_template(XCORR_REAL *xcorr, float *samples1, int nsamples1);

int xcr_xcorr_template_with(XCORR_REAL *xcorr, float *samples2, int nsamples2, float *coeffs);

// xcorr arbitrary samples using internal buffers
// coeffs must be at least xcr_get_buf_size long
int xcr_xcorr(XCORR_REAL *xcorr,
              float *samples1, int nsamples1,
              float *samples2, int nsamples2,
              float *coeffs);

//int normalizedCrossCorrelateWithHaystack(float * x, int lx, float *c, int lc);

// More efficient methods using pre-zeroed buffers and zero-copy
// coeffs must be at least xcr_get_buf_size long
int xcr_prep_samples(XCORR_REAL *xcorr,
                     float *samples1, int nsamples1,
                     float *bufr, float *bufi,
                     bool conj);

int xcr_prep_samplesz(XCORR_REAL *xcorr,
                      float *samples1, int nsamples1,
                      float *bufr, float *bufi,
                      bool conj, int zero);

int xcr_xcorr_prepped(XCORR_REAL *xcorr,
                      float *bufnr, float *bufni,
                      float *bufhr, float *bufhi,
                      float *bufcr, float *bufci,
                      float *coeffs);

//naive peak finder
int xcr_find_peak(XCORR_REAL *xcorr, float *coeffs, int coeffSize, float *maxVal);
    
#if defined __cplusplus
};
#endif

#endif
