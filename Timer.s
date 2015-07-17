.equ TIMER, 0x10002000
.equ PERIOD, 150000000
.equ CODEC, 0x10003040
.equ PS2, 0x10000100
.equ RED_LEDS, 0x1000000
.equ VGA, 0x08000000
.equ TEXT, 0x09000000
.equ TIMES128, 8

.include "W:/ECE243/Project/TestCode/nios_macros.s"

# r16 Dedicated audio codec address register
# r17 Dedicated general use register (nothing important will be in here)
# r18 Dedicated PS2 address register
# r19 Dedicated general use register #2 (nothing important will be in here)
# r20 Dedicated AUDIO_IN_AND_OUT address register
# r21 Dedicated countdown register
# Remember that the audio codec receives interrupts
# Will most likely have to use a label as opposed to putting everything on the stack

# Use r8 to store the position on the y-axis
# Use r9 to store the position on the x-axis
# Use r14 to hold the address of the text buffer
# Use r22 to hold the address of the VGA bugger

.section .data

										# By default this bit will be 0
										# Reading a 1 from this address means we want low pass filtering
										# Reading a 2 from this address means we want high pass filtering
										# Reading a 3 from this address means we want band pass filtering
										# Reading a 4 from this address means we want to provide an echo effect
										# Reading a 5 from this address means we want to provide a feedback effect
										
										
	.align 2
	LOW_PASS_THRESHOLD: .skip 4
	HIGH_PASS_THRESHOLD: .skip 4
	BAND_PASS_THRESHOLD: .skip 8
	
	FFT_IN_AND_OUT: .skip 8192			# Allocate space for the input and output of the FFT function
	FFT_MAG_AND_PHASE: .skip 8192		# Allocate space for the input and output of the magnitude and phase of the coefficients from the FFT function
	CURRENT_OPERATION: .space 1 		# Reserves space for an identification byte
	
	DRAWN_FREQ: .space 4			# When 0, this means we have additional bar to draw at this frequency
									# When 1, we have drawn both bars associated with one frequency
	SINGLE_PIXEL_VALUE: .space 4	# Used to represent what magnitude a sample must exceed in order to earn a pixel in height
	
	PERMIT_SAMPLING .space 4		# If 1 we are allowed to sample
									# If 0 we are not allowed to sample
									
	IGNORE_SUBSEQUENT .space 4 		# If 1, we can ignore the next interrupt (break code)
									# If 0, we must actually read and address the next interrupt
	SAMPLING_ACTIVE	.space 4 		# If 0, we cannot sample
									# If 1, we can sample
	
.section .text

.global main

main:

	movia r20, CURRENT_OPERATION		# Get current byte address
	movi r21, 0x1						# Initialize to low pass
	stb r21, 0(r20)						# Set initialization

	movia r20, SAMPLING_ACTIVE			
	movi r21, 0x1						# Allow sampling at the start
	stw r21, 0(r20)						# Set initialization
	
	movia r20, PERMIT_SAMPLING			# Get current byte address
	movi r21, 0x1						# Allow sampling
	stw r21, 0(r20)						# Set initialization
	
	movia r20, TIMER
	movui r21, PERIOD					# Set the upper part of the period
	stwio r21, 8(r20)					# Store at the timer
	movhi r21, PERIOD					# Set the bottom part of the period
	stwio r21, 12(r20)					# Store at the timer
	movi r21, 0b101						# Enables interrupts for the timer and start it
	stwio r21, 4(r20)
	
	# Initialize the low pass filtering boundary
	movia r20, LOW_PASS_THRESHOLD					# Fetch the address of the low pass threshold data
	movi r21, 1000									# Hardcode the threshold
	stw r21, 0(r20)									# Set frequencies under 10kHz to be filtered
	
	#Initialize the high pass filtering boundary
	movia r20, HIGH_PASS_THRESHOLD					# Fetch the address of the low pass threshold data
	movi r21, 10000									# Hardcode the threshold
	stw r21, 0(r20)									# Set frequencies over 10kHz to be filtered
	
	# Initiaize the bounds for band pass filtering
	movia r20, BAND_PASS_THRESHOLD					# Fetch the address of the low pass threshold data
	movi r21, 1000									# Set the lower threshold to 1kHz
	stw r21, 0(r20)									# Write the lower threshold data
	movi r21, 10000									# Set the upper threshold to 10kHz
	stw r21, 4(r20)									# Write the higher threshold data
	
	movia sp, 0x800000			# Initialize the stack pointer
	movia r16, CODEC			# Put the address of the codec into r16 for universal use
 	movia r18, PS2				# Put the address of the PS2 (keyboard) into r18
	movia r20, FFT_IN_AND_OUT	# Put the address of the FFT input/output into r20
	
	movi r17, 0b10000001		# Set bit 7 to 1 to enable IRQ Line 7 and 0 (PS2)
	wrctl ctl3, r17
	movi r17, 0x1				# Allow the PS2 to interrupt when there is data to be read
	stwio r17, 4(r18)			# Enable the interrupt
	# movi r17, 0x1				# Set the Processor interrupt enable bit (PIE bit)
	# wrctl ctl0, r17	

# The program waits for the user to provide input via the PS2 controller
# The data will then be transformed and played back to the user
LOOP_FOREVER:
	
	movia r20, FFT_IN_AND_OUT	# Put the address of the FFT input/output into r20
	
	movia r17, SAMPLING_ACTIVE 	# See if we are allowed to sample
	ldw r17, 0(r17)				# Check the appropriate bit
	beq r17, r0, LOOP_FOREVER	# While we are not allowed to sample, wait
	
	br FILL_BLANK
	
LOOP_INFINITY:

	br LOOP_INFINITY
	
FILL_BLANK:

	movia r22, PERMIT_SAMPLING					# We cannot get samples until time has elapsed
	stw r0, 0(r22)								# Sampling not allowed 

	movia r22, VGA
	mov r8, r0									# Iterator for x coordinate
	mov r9, r0									# Iterator for y coordinate
	br DRAW_LEFT_COLUMN
	
DRAW_LEFT_COLUMN:
					
	slli r17, r8, 1								# Compute 2 * x
	add r15, r17, r22							# Set Address = VGA + 2 * x
	slli r17, r9, 10							# Compute 1024 * y
	add r15, r15, r17							# Set Address = VGA + 2 * x + 1024 * y
	
	movi r12, 0x0000							# Set the color to black
	sthio r12, 0(r15)							# Write the pixel color
	
	addi r8, r8, 1								# Increment the x coordinate
	movi r17, 320								# Set the x boundary
	blt r8, r17, DRAW_LEFT_COLUMN				# Keep iterating if we haven't reached the bounds
	
	mov r8, r0									# Reset the x coordinate
	addi r9, r9, 1								# Increment the y coordinate
	movi r17, 240								# Set the y boundary
	blt r9, r17, DRAW_LEFT_COLUMN				# Keep iterating
	
	movia r20, FFT_IN_AND_OUT
	movi r8, 1024
	stw r8, 0(r20)
	
	br PERFORM_FFT
	
FETCH_ALL_SAMPLES:

	movi r23, 128						# Set the size of the FIFO queue
	ldwio r22, 4(r16)					# Get information on the number of samples
	andi r22, r22, 0xFF					# Mask everything but the bottom 8 bits (# samples in Right FIFO)
	bne r22, r23, FETCH_ALL_SAMPLES		# While the record FIFO is not full, loop back.
	
	movi r23, TIMES128				# Set the number of times to capture samples
	movi r17, 128					# Move the number of samples (128) into r17 (counter)
	mov r19, r20					# Set r19 to point to the start location (initially)
	
	br FETCH_SAMPLES			# Start fetching samples
	
# Note: At this point, there are guaranteed to be 128 samples in the record FIFO (checked earlier)
FETCH_SAMPLES:

	ldwio r22, 8(r16)			# Grab the data at the start of the left FIFO (and discard it)
	ldwio r22, 12(r16)			# Grab the data from the start of the right FIFO
	stwio r22, 0(r19)			# Store the sample as the real part of the input to the FFT function
	stwio r0,  4(r19)			# Store 0 as the complex part of the input to the FFT function
	
	addi r19, r19, 8			# Move along to the location of the next possible input
	
	subi r17, r17, 1			# Decrement the counter (previously initialized to 128)
	bne r17, r0, FETCH_SAMPLES	# While there are samples to be read, retrieve them
	
	WAIT_FOR_SAMPLES:
		
		movi r8, 128						# Set the size of the FIFO queue
		ldwio r9, 4(r16)					# Get information on the number of samples
		andi r9, r9, 0xFF					# Mask everything but the bottom 8 bits (# samples in Right FIFO)
		bne r9, r8, WAIT_FOR_SAMPLES		# While the record FIFO is not full, loop back.
	
	movi r17, 128				# Move the number of samples (128) into r17 (counter)
	subi r23, r23, 1			# Decrement the number of sample blocks to fetch
	bne r23, r0, FETCH_SAMPLES	# Fetch another block of samples
	
	br PERFORM_FFT

PERFORM_FFT:

	mov r4, r20					# Place a pointer to the address of the first element in the FFT input/output array
	movia r5, FFT_MAG_AND_PHASE	# Place a pointer to the address of the first element in the arrray of output coefficients
	mov r6, r0					# Place 0 in r6 to let the function know we wish to perform the FFT operation
	call doFFT
	
	# Debug: Light the second LED on completion of the FFT subroutine
	#movia r22, RED_LEDS
	#movi r23, 0x3
	#stwio r23, 0(r22)
	
	# TODO
	br SET_SPECTOGRAM

/*
RETURN_TO_OPERATION:

	movia r19, CURRENT_OPERATION	# Retrieve the address of the byte determining the current operation
	ldb r19, 0(r19)					# Get the byte indicating the nature of the operation
	movi r17, 0x1					# Check if operation is low pass
	beq r19, r17, LOW_PASS_COMPLETE	# Complete low pass filtering
	movi r17, 0x2					# Check if operation is high pass
	beq r19, r17, HIGH_PASS_COMPLETE	# Complete high pass filtering
	movi r17, 0x3					# Check if operation is band pass
	beq r19, r17, BAND_PASS_COMPLETE	# Complete band pass filtering
	movi r17, 0x4					# Check if operation is echo
	beq r19, r17, ECHO_COMPLETE		# Complete echo effect
	movi r17, 0x5					# Check if operation is feedback
	beq r19, r17, FEEDBACK_COMPLETE	# Complete feedback effect
	
	# Should not reach here
	br LOOP_FOREVER
	
PERFORM_INVERSE_FFT:

	mov r4, r20						# Place a pointer to the address of the first element in the FFT input/output array
	movia r5, FFT_MAG_AND_PHASE		# Place a pointer to the address of the first element in the arrray of output coefficients
	movi r6, 0x1					# Place 0 in r5 to let the function know we wish to perform the inverse FFT operation
	call doFFT
	
	movia r22, RED_LEDS
	movi r23, 0x7
	stwio r23, 0(r22)
	
	br LOAD_INTO_QUEUE_RESET
	
LOAD_INTO_QUEUE_RESET:

	movia r20, AUDIO_IN_AND_OUT		# Reset to the start address
	mov r19, r20					# Throw that shit into r19
	movia r17, 48000				# Loop through 5 seconds worth of samples 
	
LOAD_INTO_QUEUE:

	ldwio r22, 4(r16)				# Retrieve the amount of available space in the Playback FIFO
	andi r22, r22, 0xFF0000			# Mask remaining bits to find the number of samples
	beq r22, r0, LOAD_INTO_QUEUE	# While no space to write is available, keep polling
	
	ldwio r22, 0(r19)				# Load the value of the next sample
	stwio r22, 8(r16)				# Write the value to the Left FIFO
	stwio r22, 12(r16)				# Write the value to the Right FIFO
	
	addi r19, r19, 8				# Move to the next value to be read
	
	subi r17, r17, 1				# Decrement the counter (initially 240000)				
	bne r17, r0, LOAD_INTO_QUEUE	# While the number of samples to be written is greater than 0, keep trying to write
	
	movia r19, RED_LEDS
	movi r22, 0x0
	stwio r22, 0(r19)
	br LOOP_FOREVER					# Return to polling for input
*/
	
SET_SPECTOGRAM:

	# First name the two axes
	# X axis name as Freq.
	# Y axis name as Mag.
	
	movia r22, VGA				# Load the address of the pixel buffer
	movi r8, 200				# Set the y boundary
	movi r9, 60					# Set the start coordinate for the x axis
	movi r20, 320				# Set the x boundary
	
DRAW_Y_AXIS:

	subi r8, r8, 1				# Decrement one from y 
	movia r12, 0xFFFFFFFF		# Set the colour to be white
	
	slli r14, r8, 10							# Multiply the y component by 1024
	slli r15, r9, 1								# Multiply the x component by 2
	add r11, r22, r14							# Get the address as a combination of the VGA address and y addresses
	add r11, r11, r15							# Get the complete address by adding the x address
	stwio r12, 0(r11)
	
	br CHECK_Y_AXIS

CHECK_Y_AXIS:

	beq r8, r0, SET_X_AXIS
	br DRAW_Y_AXIS
	
SET_X_AXIS:

	movi r9, 61									# We have gone to the next x address
	movi r8, 200								# We are keeping the y constant (2 pixels wide)
	movi r20, 320								# We are watching the x boundary

DRAW_X_AXIS:

	addi r9, r9, 1 								# Increment x by 1 
	movia r12, 0xFFFFFFFF						# Set the colour to be white
	
	slli r14, r8, 10							# Multiply the y component by 1024
	slli r15, r9, 1								# Multiply the x component by 2
	add r11, r22, r14							# Get the address as a combination of the VGA address and y addresses
	add r11, r11, r15							# Get the complete address by adding the x address
	sthio r12, 0(r11)							# Store the bit at the appropriate address
	
	subi r14, r8, 1								# Move up 1 y pixel (2 pixel wide axis)
	slli r14, r14, 10							# Multiply y value by 1024
	add r11, r14, r22							# Add the y address and VGA address
	add r11, r11, r15							# Store the same value at the adjacent x address
	sthio r12, 0(r11)
	
	br CHECKING_X_AXIS
	
CHECKING_X_AXIS:

	beq r9, r20, SPECTOGRAM
	br DRAW_X_AXIS
	
SPECTOGRAM:
	
	movia r22, VGA				# Load the address of the pixel buffer
	movia r14, TEXT				# Load the address of the text buffer
	movi r9, 0	 				# Set the start counter for the x direction
	movi r8, 240				# Set the limit counter for the y direction
	movi r23, 320				# Set x boundary
	
	movia r17, SINGLE_PIXEL_VALUE
	movia r19, 220 
	stw r19, 0(r17)
	
	movia r17, FFT_MAG_AND_PHASE
	
DRAW_MAGNITUDE:

	beq r9, r23, LOOP_INFINITY			# If done return to looping forever
	ldw r10, 0(r17)						# Load the value of the Magnitude associated with the current frequency
	br DETERMINE_PIXEL_COUNT			# Find number of non zero pixels
	
DETERMINE_PIXEL_COUNT:

	movia r12, SINGLE_PIXEL_VALUE				# Get the value that we need to be checking against
	ldw r12, 0(r12)								# Place the value into r12
	
	# We will use r13 for the sake of the pixel counter when drawing non-black pixels
	mov r13, r10								# Reset the value to 0
	br DRAWING
	
DETERMINE_COUNT:

	beq r10, r0, DRAWING						# If nothing to draw, leave counter at 0
	
	# sub r10, r10, r12							# Sub that value from the magnitude
	# addi r13, r13, 1							# Add 1 to the number of non-black pixels
	# bgt r10, r0, DETERMINE_COUNT				# While the magnitude is non zero, check if another pixel is non-black
	
	br DRAWING
	
DRAWING: 

	# We want to draw the appropriate colour for any of the given pixels
	# 1. Decrement y counter
	# 2. Determine the colour of the pixel (Lower B, Mid Green, High Red)
	# 3. Draw the pixel. Increment x by one and draw again. Decrement x by one
	# 4. Check if y counter is at 0
	# 5. If yes then increment x counter by 2 (next sample). Increment access point of the array. Reset the y counter.
	
	subi r8, r8, 1								# Decrement the y counter
	
DETERMINE_COLOUR:

	beq r13, r0, DRAW_EMPTY						# Shed tears because NIOS does not do greater than or equal to
	bgt r0, r13, DRAW_EMPTY						# If the magnitude's range has been represented draw a black screen

	movi r10, 160								# Check if in first range
	bgt r8, r10, DRAW_BLUE						# Branch and draw low magnitude
	movi r10, 80								# Check if in second range
	bgt r8, r10, DRAW_GREEN						# Branch and draw mid magnitude
	br DRAW_RED									# Branch and draw high magnitude
	
	
DRAW_EMPTY:

	movi r12, 0b0								# Store a black colour
	br CHECKING_Y
	
DRAW_BLUE:

	movia r12, 0b11111							# Store a pure blue colour	
	br CHECKING_Y
	
DRAW_GREEN:

	movia r12, 0b11111100000						# Store a pure green colour	
	br CHECKING_Y
	
DRAW_RED:

	movia r12, 0b1111100000000000				# Store a pure red colour	
	br CHECKING_Y
	
CHECKING_Y:

	slli r14, r8, 10							# Multiply the y component by 1024
	slli r15, r9, 1								# Multiply the x component by 2
	add r11, r22, r14							# Get the address as a combination of the VGA address and y addresses
	add r11, r11, r15							# Get the complete address by adding the x address
	sthio r12, 0(r11)							# Store the bit at the appropriate address
	
	subi r13, r13, 1
	beq r8, r0, RESET_AND_ADVANCE
	br DRAWING
	
RESET_AND_ADVANCE:

	movi r8, 202								# Reset the value of the y counter
	addi r9, r9, 1								# Advance to the next x address to draw at
	addi r17, r17, 8							# Advance to the next sample
	
	br DRAW_MAGNITUDE							# Move to the next sample
	
/*	
# Performs low-pass filtering. Zeros-out high-frequency components above a certain threshold. Calculations:
# - Offset in memory locations between the 1st (excluding DC) and last (127th) buckets: (127 - 1) * 8 = 1008
# - Difference to subtract from the offset on each iteration: 16B (4 Bytes/Word * 2 Words/Sample * 2 Samples (1 current, 1 aliased))
# - Range of iterations: 1 to 64
# - Frequency increment: 44,100Hz / 128  ~= 345Hz
LOW_PASS_COMPLETE:
	
	movia r17, LOW_PASS_THRESHOLD			# Fetch a pointer to the address containing the lower threshold
	ldw r17, 0(r17)							# Store the lower threshold frequency in r17
	
	movia r19, FFT_IN_AND_OUT				# Store a pointer to the first sample in r19
	addi r19, r19, 8						# Advance it by 8 (skip the 0-frequency component)
	
	movi r21, 64							# The index of the maximum-frequency bucket. Higher frequencies get aliased
	movi r22, 1								# Counter: starts at 1, goes upto 64 (both inclusive)
	movi r23, 1008							# Initialize r23 to the difference (offset) between the 1st and 127th sample. (127-1)*8 = 1008
	movi r8, 375							# The current frequency (Hz) of the bucket
	
	LOW_PASS_COMPLETE_LOOP:
	
		blt r8, r17, LOW_PASS_COMPLETE_LOOP_NEXT	# If the current frequency is less than the cut-off, do not rewrite it
	
		# Else, zero-out this component
		stw r0, 0(r19)								# Re-write the real component
		stw r0, 4(r19)								# Re-write the imaginary component
	
		# Zero-out the aliased component
		add r9, r19, r23							# Add the offset to advance the pointer by
		stw r0, 0(r9)								# Re-write the real component
		stw r0, 4(r9)								# Re-write the imaginary component
	
		LOW_PASS_COMPLETE_LOOP_NEXT:
		addi r19, r19, 8							# Advance to the next sample
		addi r22, r22, 1							# Increment the counter
		subi r23, r23, 16							# Subtract the difference (16B, see description) from the offset
		addi r8, r8, 375							# Add the frequency increment (345Hz, see description)
		blt r22, r21, LOW_PASS_COMPLETE_LOOP		# While the counter is less than the middle-element index, keep looping
	
	# Completed low-pass filtering. Perform the inverse FFT on the modified array
	br PERFORM_INVERSE_FFT

# Performs high-pass filtering. Zeros-out high-frequency components below a certain threshold. Calculations:
# - Offset in memory locations between the 1st (excluding DC) and last (127th) buckets: (127 - 1) * 8 = 1008
# - Difference to subtract from the offset on each iteration: 16B (4 Bytes/Word * 2 Words/Sample * 2 Samples (1 current, 1 aliased))
# - Range of iterations: 1 to 64
# - Frequency increment: 44,100Hz / 128  ~= 345Hz
HIGH_PASS_COMPLETE:
	
	movia r17, HIGH_PASS_THRESHOLD			# Fetch a pointer to the address containing the upper threshold
	ldw r17, 0(r17)							# Store the upper threshold frequency in r17
	
	movia r19, FFT_IN_AND_OUT				# Store a pointer to the first sample in r19
	stw r0, 0(r19)							# Zero-out the real part of the DC component
	stw r0, 4(r19)							# Zero-out the imaginary part of the DC component
	addi r19, r19, 8						# Advance it by 8 (skip the 0-frequency component)
	
	movi r21, 64							# The index of the maximum-frequency bucket. Higher frequencies get aliased
	movi r22, 1								# Counter: starts at 1, goes upto 64 (both inclusive)
	movi r23, 1008							# Initialize r23 to the difference (offset) between the 1st and 127th sample. (127-1)*8 = 1008
	movi r8, 375							# The current frequency (Hz) of the bucket
	
	HIGH_PASS_COMPLETE_LOOP:
		
		bgt r8, r17, HIGH_PASS_COMPLETE_LOOP_NEXT	# If the current frequency is less than the cut-off, do not rewrite it
		
		# Else, zero-out this component
		stw r0, 0(r19)								# Re-write the real component
		stw r0, 4(r19)								# Re-write the imaginary component
		
		# Zero-out the aliased component
		add r9, r19, r23							# Add the offset to advance the pointer by
		stw r0, 0(r9)								# Re-write the real component
		stw r0, 4(r9)								# Re-write the imaginary component
		
		HIGH_PASS_COMPLETE_LOOP_NEXT:
		addi r19, r19, 8							# Advance to the next sample
		addi r22, r22, 1							# Increment the counter
		subi r23, r23, 16							# Subtract the difference (16B, see description) from the offset
		addi r8, r8, 375							# Add the frequency increment (345Hz, see description)
		blt r22, r21, HIGH_PASS_COMPLETE_LOOP		# While the counter is less than the middle-element index, keep looping
	
	# Completed high-pass filtering. Perform the inverse FFT on the modified array
	br PERFORM_INVERSE_FFT
	
# Performs band-pass filtering
BAND_PASS_COMPLETE:
	
	movia r17, BAND_PASS_THRESHOLD			# Fetch a pointer to the address containing the upper threshold
	ldw r9, 0(r17)							# Store the lower threshold of the band in r8
	ldw r10, 4(r17)							# Store the higher threshold of the band in r9
	
	movia r19, FFT_IN_AND_OUT				# Store a pointer to the first sample in r19
	addi r19, r19, 8						# Advance it by 8 (skip the 0-frequency component)
	
	movi r21, 64							# The index of the maximum-frequency bucket. Higher frequencies get aliased
	movi r22, 1								# Counter: starts at 1, goes upto 64 (both inclusive)
	movi r23, 1008							# Initialize r23 to the difference (offset) between the 1st and 127th sample. (127-1)*8 = 1008
	movi r8, 375							# The current frequency (Hz) of the bucket
	
	BAND_PASS_COMPLETE_LOOP:
		
		bgt r9, r10, BAND_PASS_COMPLETE_LOOP_NEXT
	
	br PERFORM_INVERSE_FFT
	
ECHO_COMPLETE:
	
	# Complete the filtering operation
	br PERFORM_INVERSE_FFT
	
FEEDBACK_COMPLETE:
	
	# Complete the filtering operation
	br PERFORM_INVERSE_FFT	
*/

.section .exceptions, "ax"

INTERRUPT_HANDLER:

	subi sp, sp, 12					# Grow the stack to store clobbered registers
	stw r17, 0(sp)					# Save r17 on the stack
	stw r19, 4(sp)					# Save r19 on the stack
	stw r8, 8(sp)					# Save r8 on the stack
	
	rdctl et, ctl4					# Copy the ipending into r24
	andi et, et, 0x80				# Check to see if interrupt pending is from line 7
	bne et, r0, DETERMINE_OPERATION	# The interrupt is not from IRQ7

	rdctl et, ctl4					# Copy the ipending into r24
	andi et, et, 0x1				# Check to see if the interrupt pending is from line 0
	bne	et, r0, ALLOW_SAMPLING 		# Let's us acquire a new set of samples
	
	br EXIT_HANDLER
	
DETERMINE_OPERATION:

	ldwio r17, 0(r18)			# Load the value at the PS2 address
	andi r17, r17, 0xFF			# Isolate the lower 8 bits (data)
	
	movi r19, 0x32				# Check if user has selected the bandpass filtering 'B'
	beq r17, r19, BAND_PASS		# Enter band pass filtering
	
	movi r19, 0x24				# Check if the user has seleceted the echo feature 'E'
	beq r17, r19, ECHO			# Enter the echo operation
	
	movi r19, 0x2B				# Check if the user has selected the feedback feature 'F'
	beq r17, r19, FEEDBACK		# Enter the feedback operation
	
	movi r19, 0x4B				# Check if the user has selected the low pass filtering 'L'
	beq r17, r19, LOW_PASS		# Enter the low pass filtering
	
	movi r19, 0x33				# Check if the user has selected the high pass filtering 'H'
	beq r17, r19, HIGH_PASS		# Enter the high pass filtering
	
	movi r19, 0x2D				# Check if the user has selected to reacquire a new sample 'R'
	beq r17, r19, RESET_SAMPLE	# Allow sampling
	
	movi r19, 0xF0				# Check if we are receiving break code
	beq r17, r19, INGORE_NEXT	# Tell us to ignore the next keyboard interrupt
	
	br  EXIT_HANDLER
	
IGNORE_NEXT:

	movia et, IGNORE_SUBSEQUENT	# Don't let the next interrupt screw anything up
	movi r17, 0x1				# Don't consider the next keyboard interrupt
	stw r17, 0(et)				# Next keyboard interrupt will be ignored
	br EXIT_HANDLER
	
RESET_SAMPLE:

	movia et, PERMIT_SAMPLING		# Check if the timer has allowed us to sample
	ldw et, 0(et)					# Get the value
	beq et, r0, EXIT_HANDLER
	
	movia et, SAMPLING_ACTIVE		# Allow sampling to occur
	movi r17, 0x1					# Set sampling active
	stw r17, 0(et)
	br EXIT_HANDLER
	
ALLOW_SAMPLING:

	# See if we need to write a 1 into the continue control bit
	movia et, PERMIT_SAMPLING		# Allow samples to be read
	movi r21, 0x1					# Write 1 to allow sampling
	stw r21, 0(et)					# Sampling is allowed
	
	movia et, TIMER					# Reset timer
	stwio r21, 0(et)				# Acknowledge interrupt
	br EXIT_HANDLER					# Leave the interrupt handler
	
	

LOW_PASS:

	movi et, 0x1					# Set the operation to be low pass filtering
	movia r17, CURRENT_OPERATION	# Get the address of the identification bit
	stb et, 0(r17)					# Set the current operation
	br EXIT_HANDLER
	
HIGH_PASS:

	movi et, 0x2					# Set the operation to be high pass filtering
	movia r17, CURRENT_OPERATION	# Get the address of the identification bit
	stb et, 0(r17)					# Set the current operation
	br EXIT_HANDLER
	
BAND_PASS:

	movi et, 0x3					# Set the operation to be band pass filtering
	movia r17, CURRENT_OPERATION	# Get the address of the identification bit
	stb et, 0(r17)					# Set the current operation
	br EXIT_HANDLER
	
ECHO:

	movi et, 0x4					# Set the operation to be band pass filtering
	movia r17, CURRENT_OPERATION	# Get the address of the identification bit
	stb et, 0(r17)					# Set the current operation
	br EXIT_HANDLER
	
FEEDBACK:

	movi et, 0x5					# Set the operation to be band pass filtering
	movia r17, CURRENT_OPERATION	# Get the address of the identification bit
	stb et, 0(r17)					# Set the current operation
	br EXIT_HANDLER
	
EXIT_HANDLER:

	ldw r17, 0(sp)				# Pop r17 off the stack
	ldw r19, 4(sp)				# Pop r19 on the stack
	ldw r8, 8(sp)				# Pop r20 on the stack
	
	addi sp, sp, 12				# Restore the stack
	
	subi ea, ea, 4				# Replay instruction that got interrupted
	eret
	
# Incude this check for all filters

	movia r17, IGNORE_SUBSEQUENT	# See if this is part of the break code
	ldw r17, 0(r17)					# If it's 0, simply go to the handler
	bne r17, r0, RESET_IGNORE		# If ignoring, simply end

RESET_IGNORE:

	movia r17, IGNORE_SUBSEQUENT	# Get word address
	stw r0, 0(r17)					# Next keyboard interrupt is valid
	br EXIT_HANDLER					# Leave interrupt handler
