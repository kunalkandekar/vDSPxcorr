//
//  vdspxcorr.c
//  vdspxcorr
//
//  Created by Kunal Kandekar on 1/7/13.
//
//
#include <string.h>
#include <stdlib.h>
#include <float.h>

#import "vdspxcorr.h"

FFT_WINDOW *fftwin_alloc(int size, FFT_WINDOW_TYPE wtype) {
    FFT_WINDOW *win = (FFT_WINDOW*)malloc(sizeof(FFT_WINDOW));
    win->size = size;
    win->wtype = wtype;
    win->coeffs  = (float *) malloc(size * sizeof(float));
    switch (win->wtype) {
        case WINDOW_TYPE_HAN: //Hann:
            vDSP_hann_window(win->coeffs, size, vDSP_HANN_NORM);
            break;
        default:
        case WINDOW_TYPE_HAM: //Hamming:
            vDSP_hamm_window(win->coeffs, size, 0);
            break;
        case WINDOW_TYPE_BLK: //Blackman:
            vDSP_blkman_window(win->coeffs, size, 0);
            break;
    }
    return win;
}

void fftwin_free(FFT_WINDOW *win) {
    free(win->coeffs);
    free(win);
}

float fftwin_gain_offset(FFT_WINDOW *win) {
    float fGainOffset = 0.0;
    switch (win->wtype) {
        case WINDOW_TYPE_HAN:
            fGainOffset = kHannFactor;
            break;
        default:
        case WINDOW_TYPE_HAM:
            fGainOffset = kHammingFactor;
            break;
        case WINDOW_TYPE_BLK:
            fGainOffset = kBlackmanFactor;
            break;
    }
    return fGainOffset;

}

/************ FFT Real ************/

FFT_REAL *fftreal_alloc(uint32_t N, bool alloc) {
    FFT_REAL *fftr = (FFT_REAL*)malloc(sizeof(FFT_REAL));
    //find the next highest power of 2
    uint32_t log2OfN = 0 ;
    while( N >>= 1 ) log2OfN++;
    
    fftr->log2n = log2OfN;
    fftr->n = 1 << fftr->log2n;
    
    fftr->stride = 1;
    fftr->nOver2 = fftr->n / 2;
    
    //NSLog(@"1D real fft of length log2 ( %d ) = %d\n\n", fftr->n, fftr->log2n);
    
    /* Allocate memory for the input operands and check its availability,
     * use the vector version to get 16-byte alignment. */
    fftr->realp = NULL;
    fftr->imagp = NULL;
    if(alloc) {
        fftr->realp = (float *) malloc(fftr->nOver2 * sizeof(float));
        fftr->imagp = (float *) malloc(fftr->nOver2 * sizeof(float));
        fftr->A.realp = fftr->realp;
        fftr->A.imagp = fftr->imagp;
    }
    
    /* Set up the required memory for the FFT routines and check  its
     * availability. */
    fftr->setupReal = vDSP_create_fftsetup(fftr->log2n, FFT_RADIX2);
    if (fftr->setupReal == NULL) {
        //NSLog(@"\nFFT_Setup failed to allocate enough memory  for the real FFT.\n");
    }
    return fftr;
}

void fftreal_free(FFT_REAL *fftr) {
    if(fftr->setupReal) {
        vDSP_destroy_fftsetup(fftr->setupReal);
    }
    if(fftr->realp) free(fftr->realp);
    if(fftr->imagp) free(fftr->imagp);
}

uint32_t fftreal_get_fft_size(FFT_REAL *fftr) {
    return fftr->n;
}

uint32_t fftreal_get_complexbuf_size(FFT_REAL *fftr) {
    return fftr->nOver2;
}

COMPLEX_SPLIT* fftreal_get_complexbuf(FFT_REAL *fftr) {
    return &(fftr->A);
}

void fftreal_conj_complexbuf(FFT_REAL *fftr) {
    vDSP_zvconj(&(fftr->A), 1, &(fftr->A), 1, fftr->nOver2);
}

void fftreal_apply_win(FFT_REAL *fftr, FFT_WINDOW *window, float *samples, int size, int numChannels) {
    for (int i=0; i < numChannels; ++i) {
        vDSP_vmul(samples + i, numChannels, window->coeffs, 1, samples, numChannels, (size / numChannels));
    }
}

void fftreal_apply_gain_offset(FFT_REAL *fftr, FFT_WINDOW *window, float *samples, int size)  {
    float fGainOffset = fftwin_gain_offset(window);
    vDSP_vsadd(samples, 1, &fGainOffset, samples, 1, size);
}

void fftreal_scale_fft_complex_mag(FFT_REAL *fftr, float *mag) {
    fftr->A.imagp[0] = 0.0;
    
    float scale = (float) 1.0 / (2 * fftr->n);
    
    vDSP_vsmul(fftr->A.realp, 1, &scale, fftr->A.realp, 1, fftr->nOver2);
    vDSP_vsmul(fftr->A.imagp, 1, &scale, fftr->A.imagp, 1, fftr->nOver2);
    
    // Convert the complex data into something usable
    // spectrumData is also a (float*) of size mNumFrequencies
    vDSP_zvabs(&(fftr->A), 1, mag, 1, fftr->nOver2);
    
}

void fftreal_complexbuf_to_mag(FFT_REAL *fftr, float *mag, int size) {
    uint32_t bins = size >> 1;
    float one = 1, fBins = bins;  //two = 2,
    vDSP_zvabs(&(fftr->A), 1, mag, 1, bins);
    vDSP_vsdiv(mag, 1, &fBins, mag, 1, bins);
    
    // convert to Db
    vDSP_vdbcon(mag, 1, &one, mag, 1, bins, 1);
}

int fftreal_fft_fwd(FFT_REAL *fftr, float *input) {
    if(fftr->realp && fftr->imagp) {
        return fftreal_fft_fwdtos(fftr, input, 1, fftr->realp, fftr->imagp);
    }
    return -1;
}

int fftreal_fft_fwdto(FFT_REAL *fftr, float *input, float *real, float *imag) {
    return fftreal_fft_fwdtos(fftr, input, 1, real, imag);
}

int fftreal_fft_fwdtos(FFT_REAL *fftr, float *input, int stride, float *real, float *imag) {
    fftr->A.realp = real;
    fftr->A.imagp = imag;

    vDSP_ctoz((COMPLEX *) input, 2*stride, &(fftr->A), 1, fftr->nOver2);
    
    vDSP_fft_zrip(fftr->setupReal, &(fftr->A), fftr->stride, fftr->log2n, FFT_FORWARD);
    return 0;
}

int fftreal_fft_inv(FFT_REAL *fftr, float *output) {
    if(fftr->realp && fftr->imagp) {
        return fftreal_fft_invints(fftr, fftr->realp, fftr->imagp, output, 1);
    }
    return -1;
}

int fftreal_fft_invint(FFT_REAL *fftr, float *real, float *imag, float *output) {
    fftr->A.realp = real;
    fftr->A.imagp = imag;
    return fftreal_fft_invcs(fftr, &(fftr->A), output, 1);

}

int fftreal_fft_invints(FFT_REAL *fftr, float *real, float *imag, float *output, int stride) {
    fftr->A.realp = real;
    fftr->A.imagp = imag;
    return fftreal_fft_invcs(fftr, &(fftr->A), output, stride);
    
}

int fftreal_fft_invc(FFT_REAL *fftr, COMPLEX_SPLIT *C, float *output) {
    return fftreal_fft_invcs(fftr, C, output, 1);
}

int fftreal_fft_invcs(FFT_REAL *fftr, COMPLEX_SPLIT *C, float *output, int stride) {
    vDSP_fft_zrip(fftr->setupReal, C, stride, fftr->log2n, FFT_INVERSE);
    
    // scale it by  2n.
    float scale = (float) 1.0 / (2 * fftr->n);
    
    vDSP_vsmul(C->realp, 1, &scale, C->realp, 1, fftr->nOver2);
    vDSP_vsmul(C->imagp, 1, &scale, C->imagp, 1, fftr->nOver2);
    
    vDSP_ztoc(C, 1, (COMPLEX *) output, 2*stride, fftr->nOver2);
    return 0;
}


/************ XCorrReal ************/

XCORR_REAL *xcr_alloc(int nsamples1, int nsamples2, XCORR_REAL_PREALLOC preAlloc, float *tsamples) {
    XCORR_REAL *xcorr = (XCORR_REAL*)malloc(sizeof(XCORR_REAL));
    
    xcorr->buf   = NULL;
    xcorr->bufxr = NULL;
    xcorr->bufxi = NULL;
    xcorr->bufyr = NULL;
    xcorr->bufyi = NULL;
    xcorr->max_samples1 = nsamples1;
    xcorr->max_samples2 = nsamples2;
    xcorr->max_samples_in = xcorr->max_samples1 + xcorr->max_samples2 - 1;
    xcorr->size = 8;
    while(xcorr->size < xcorr->max_samples_in) {
        xcorr->size <<= 1;
    }
    
    //NSLog(@"XCORR FFT SIZE = %d", size);
    xcorr->fft = fftreal_alloc(xcorr->size, false);
    xcorr->complex_buf_size = fftreal_get_complexbuf_size(xcorr->fft);
    
    //NSLog(@" fft size = %d complex size = %d", xcorr->size, xcorr->complex_buf_size);
    
    xcorr->buf_size_bytes = xcorr->size * sizeof(float);
    
    if(preAlloc != XCORR_REAL_INTERNAL_ALLOC_NO) {
        xcorr->buf = (float *)malloc(xcorr->buf_size_bytes);
        int complex_buf_size_bytes = xcorr->complex_buf_size * sizeof(float);
        xcorr->bufxr = (float *)malloc(complex_buf_size_bytes);
        xcorr->bufxi = (float *)malloc(complex_buf_size_bytes);
        xcorr->bufyr = (float *)malloc(complex_buf_size_bytes);
        xcorr->bufyi = (float *)malloc(complex_buf_size_bytes);
    }
    
    xcorr->N = &(xcorr->cN);
    
    if(tsamples && xcorr->buf) {
        int max_samples1_bytes = nsamples1 * sizeof(float);
        memset(xcorr->buf + nsamples1, 0, (xcorr->buf_size_bytes - max_samples1_bytes));
        xcr_prep_template(xcorr, tsamples, xcorr->max_samples1);
    }
    
    if(xcorr->buf) {
        //pre-zeropad input buffers so we don't have to for every call to crossCorrelate
        int max_samples_bytes = xcorr->max_samples_in * sizeof(float);
        memset(xcorr->buf, 0, (xcorr->buf_size_bytes - max_samples_bytes)); //zeropad
    }
    return xcorr;
}

void xcr_free(XCORR_REAL *xcorr) {
    if(xcorr->buf) free(xcorr->buf);
	if(xcorr->bufxr) free(xcorr->bufxr);
	if(xcorr->bufxi) free(xcorr->bufxi);
    if(xcorr->bufyr) free(xcorr->bufyr);
	if(xcorr->bufyi) free(xcorr->bufyi);
    fftreal_free(xcorr->fft);
    free(xcorr);
}

int xcr_get_buf_size(XCORR_REAL *xcorr) {
    return xcorr->size;
}

int xcr_get_complexbuf_size(XCORR_REAL *xcorr) {
    return fftreal_get_complexbuf_size(xcorr->fft);
}

int xcr_get_result_size(XCORR_REAL *xcorr) {
    return xcorr->size;
}

// pre-process (i.e. FFT and conjugate) a "template" of samples into a re-usable buffer for repeat xcorrs
int xcr_prep_template(XCORR_REAL *xcorr, float *samples1, int nsamples1) {
    if(!xcorr->bufxr || !xcorr->bufxi) {
        //internal buffers not allocated!
        return -1;
    }
    if(xcr_prep_samples(xcorr, samples1, nsamples1, xcorr->bufxr, xcorr->bufxi, true) < 0) {
        return -1;
    }
    xcorr->N->realp = xcorr->bufxr;
    xcorr->N->imagp = xcorr->bufxi;
    return 0;
   
}

int xcr_xcorr_template_with(XCORR_REAL *xcorr, float *samples2, int nsamples2, float *coeffs) {
    if(!xcorr->bufyr || !xcorr->bufyi) {
        //internal buffers not allocated!
        return -1;
    }
    if(xcr_prep_samples(xcorr, samples2, nsamples2, xcorr->bufyr, xcorr->bufyi, false) < 0) {
        return -1;
    }
    
    COMPLEX_SPLIT *H = fftreal_get_complexbuf(xcorr->fft);
    
    vDSP_zvmul(xcorr->N, 1, H, 1, H, 1, xcorr->complex_buf_size, 1);
    
    fftreal_fft_invints(xcorr->fft, xcorr->bufyr, xcorr->bufyi, coeffs, 1);
    
    return xcorr->max_samples2 - xcorr->max_samples1 + 1;
}

// xcorr arbitrary samples using internal buffers
// coeffs must be at least xcr_get_buf_size long
int xcr_xcorr(XCORR_REAL *xcorr,
              float *samples1, int nsamples1,
              float *samples2, int nsamples2,
              float *coeffs) {
    if(xcr_prep_template(xcorr, samples1, nsamples1) < 0) {
        return -1;
    }
    return xcr_xcorr_template_with(xcorr, samples2, nsamples2, coeffs);
}

//int normalizedCrossCorrelateWithHaystack(float * x, int lx, float *c, int lc);

// More efficient methods using pre-zeroed buffers and zero-copy
// coeffs must be at least xcr_get_buf_size long
int xcr_prep_samples(XCORR_REAL *xcorr,
                     float *samples1, int nsamples1,
                     float *bufr, float *bufi,
                     bool conj) {
    return xcr_prep_samplesz(xcorr,
                             samples1, nsamples1,
                             bufr, bufi,
                             conj, (xcorr->buf == NULL));
}

// coeffs must be at least xcr_get_buf_size long
int xcr_prep_samplesz(XCORR_REAL *xcorr,
                      float *samples1, int nsamples1,
                      float *bufr, float *bufi,
                      bool conj, int zerocopy) {
    if(nsamples1 > xcorr->max_samples_in) {
        return -1;
    }
    float *bufin = NULL;
    if(zerocopy) {
        //assume pre-zeroed out input buffer and use that
        bufin = samples1;
    }
    else {
        bufin = xcorr->buf;
        int max_samples_in_bytes = nsamples1 * sizeof(float);
        
        if(nsamples1 < xcorr->max_samples_in) {
            //zeropad
            memset(xcorr->buf + nsamples1, 0, (xcorr->buf_size_bytes - max_samples_in_bytes));
        }
        
        memcpy(xcorr->buf, samples1, max_samples_in_bytes);
    }
    fftreal_fft_fwdtos(xcorr->fft, bufin, 1, bufr, bufi);
    
    if(conj) {
        fftreal_conj_complexbuf(xcorr->fft);    //bufxr and bufxi now hold conjugate complex of FFT of needle
    }
    
    return 0;
}

int xcr_xcorr_prepped(XCORR_REAL *xcorr,
                      float *bufnr, float *bufni,
                      float *bufhr, float *bufhi,
                      float *bufcr, float *bufci,
                      float *coeffs) {
    COMPLEX_SPLIT NC;
    COMPLEX_SPLIT HC;
    COMPLEX_SPLIT CC;
    NC.realp = bufnr;
    NC.imagp = bufni;
    HC.realp = bufhr;
    HC.imagp = bufhi;
    CC.realp = bufcr;
    CC.imagp = bufci;
    
    vDSP_zvmul(&NC, 1, &HC, 1, &CC, 1, xcorr->complex_buf_size, 1);
    fftreal_fft_invcs(xcorr->fft, &CC, coeffs, 1);
    
    return xcorr->max_samples2 - xcorr->max_samples1 + 1;
}

//naive peak finder
int xcr_find_peak(XCORR_REAL *xcorr, float *coeffs, int coeffsize, float *maxVal) {
    //vDSP_maxmgvi(coeffs, 1, maxVal, &index, coeffSize);     //does not work because it uses abs values...
    *maxVal = FLT_MIN;
    int index = -1;
    for (int counter = 0; counter < coeffsize; ++counter) {
		if (coeffs[counter] > *maxVal) {
			*maxVal = coeffs[counter];
            index = counter;
        }
	}
    return index;
}

