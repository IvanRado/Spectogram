#include <stdio.h>
#include <math.h>

/**
 * @param inputSignal (int[]): An integer array representing the input signal.
 *                             Replaced by the output (real, imaginary)
 *                             on completion of the subroutine
 * 
 * @param outputComponents   : The output (first 64 bytes represent magnitude, 
 *                             next 64 bytes represent phase). To be used for
 *                             displaying the output on a spectrogram (stem-plot)
 * 
 * @param isInverseFFT       : 0 indicates FFT  (time-domain to frequency-domain)
 *                             1 indicates iFFT (frequency-domain to time-domain)
 * 
 * Given a window of an input signal, performs the Fast-Fourier Transform (FFT) 
 * on it using bit-reversal and the Danielson-Lanzcos Algorithm. The input should
 * be interleaved, with the real and complex parts at the even and odd indices,
 * respectively. 
 * 
 * NOTE: Each sample consists of real (even indices) and imaginary (odd indices) 
 * parts. As such, the length of the input vector should be twice the number of 
 * samples. However, the length of the output vector is equal to the number of
 * samples
 */
void doFFT(int* inputSignal, int* outputComponents, int isInverseFFT) {
    
    // Variable declaration
    int numSamples = 1024;
    int n = numSamples << 1;
	int currentMax = 2;
    int j = 1;
	int i = 1;
	int k = 1;
    
    /* Run the bit-reversal method. This swaps the values of the input
     * between pairs of indices which are bit-wise mirrored. For instance,
     * swaps the values at (1010b | 0101b, for a 16-bit input)*/
    for(i = 1; i < n; i = i+2) {
        
        // As long as indices haven't been repeated
        if(j > i) {
            
            // Swap the real part of the input signal
            double swap = inputSignal[i-1];
            inputSignal[i-1] = inputSignal[j-1];
            inputSignal[j-1] = swap;
            
            // Swap the imaginary part of the input signal (redundant, all 0s!)
            swap = inputSignal[i];
            inputSignal[i] = inputSignal[j];
            inputSignal[j] = swap;
        }
        
        /* When performing the inverse-FFT, normalize the coefficients of
         * the frequency components with the number of samples (as defined
         * in the DFT synthesis equation) */
        if(isInverseFFT == 1) {
            
            // Normalize the real and imaginary parts
            inputSignal[i-1] = inputSignal[i-1] >> 7;
            inputSignal[i]   = inputSignal[i] >> 7;
        }
        
        /* Reset the reference index. Note: Adjacent indices (j & j+1, for j even) 
         * denote the SAME sample (real, complex), so bit-reversal must maintain 
         * the integrity of the sample (should not separate its components) */
        int m = numSamples;
        while(m >= 2 && j > m) {
            j = j - m;
            m = m >> 1;
        }
        
        // Increment the index
        j = j + m;
    }
    
    /* Performs the FFT in-place using the Danielson-Lanczos method (frequency-
     * domain synthesis. The outer two loops compute the DTFT and sub-DTFTs
     * respectively. The inner loop performs the butterfly calculation (basic
     * FFT element) */
    while (n > currentMax) {
        
        // Variable declaration
        int step = currentMax * 2;
        
        /* Note: Theta must be positive to find the inverse FFT
         * x[n] = Sigma_k: X[k] * e^(j*w*k*n) */
        double theta = -(2 * M_PI)/currentMax;
        if(isInverseFFT == 1) theta = (-theta);
        
        double wtemp = sin(theta/2.0);
        double wpr = -2.0 * wtemp * wtemp;
        double wpi = sin(theta);
		double wr = 1.0;
        double wi = 0.0;
        
        // Outer loop. Computes the sub-DFT
        for (k = 1; k < currentMax; k += 2) {
                        
            /* Performs the butterfly calculation as described below:
             * WWW.DSPguide.com/CH12/2.HTM (Remove capitals!) */
            for (i = k; i <= n; i += step) {
                
                j = i + currentMax;
                double tempr = wr * inputSignal[j-1] - wi * inputSignal[j];
                double tempi = wr * inputSignal[j] + wi * inputSignal[j-1];
                
                inputSignal[j-1] = inputSignal[i-1] - tempr;
                inputSignal[j] = inputSignal[i] - tempi;
                inputSignal[i-1] += tempr;
                inputSignal[i] += tempi;
            }
			
            wtemp = wr;
            wr += wr * wpr - wi * wpi;
            wi += wi * wpr + wtemp * wpi;
        }
        
        // Increment the max iteration (upto N)
        currentMax = step;
    }
    
    /* Populate the output (magnitude, phase) vector. This output vector is only 
     * relevant for the FFT (not the inverse FFT) and is ordered as follows:
     * Mag(0), Phase(0), ..., Mag(numSamples/2 - 1), Phase(numSamples/2 - 1) */
    for(i = 0; i < n; i += 2) {
        
        // Compute the magnitude (length of the component vector)
        outputComponents[i]  = sqrt((double) inputSignal[i] * (double) inputSignal[i] + 
                                    (double) inputSignal[i+1] * (double) inputSignal[i+1]);
        
		// Take the logarithm of the magnitude
		if(outputComponents[i] != 0) outputComponents[i] = 7 * log(outputComponents[i]);
		
        // Compute the phase
        outputComponents[i+1] = 0;
    }
}

// Given a pointer to a memory location, writes a vector correponding to a sin-wave input
void writeSinWave(int* inputSignal) {
	
	int NUM_SAMPLES = 1024;
	int n = 2 * NUM_SAMPLES;
	int i = 0;
	
	// Signal parameters
	double phaseIncrement = 2 * M_PI * 5000/NUM_SAMPLES;
    double currentPhase = 0;
	
	for( i = 0; i < n; i += 2) {
        
		// Write the real component (sin)
        inputSignal[i] = 100.0 * sin(currentPhase);
        currentPhase += phaseIncrement;
        
		// Write the imaginary component (0)
		inputSignal[i+1] = 0;
    }
}