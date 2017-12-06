/*****************************************************************************

lab4.S
Daniel Peters A10103585
Chunghoon Woo A09241868
C.J Vanzant A10236730

 This file contains 4 functions which you need to implement:
	vu_meter() - this function is called by main() and should call the other
		functions in this module as appropriate to implement the VU meter.
		This function should process samples in an infinite loop and will
		never return.
		
	dc_offset() - this function should take the average of 20000 samples
		from the A/D converter and return the result. This will give the
		DC offset of the signal, which you will need to subtract from
		each sample in subsequent steps.
		
	filter() - this function should pass the argument through a first order
		IIR filter (the coefficients of which are defined in FILT_K and
		FILT_A) and return the result.
		
	display() - this function should display the base-10 logarithm of the
		argument on the LED array.
 
 Comment your code clearly with the logical steps that you are performing.
 Uncommented code will receive zero credit.
   
*****************************************************************************/

.set AD0GDR,		0xE0034004
.set FIO0SET,		0x3FFFC018
.set FIO0CLR,		0x3FFFC01C
.set FRACBITS,		28
.set FILT_K,		0x263e9c		// filter scale coefficient in q4.28 format
.set FILT_A,		0xf04c7d3a		// filter coefficient in q4.28 format
.set FLOAT1,		0x4d800000		// floating point represetion of (1 << 28)


.text
.align 4


/**
 *  void vu_meter();
 */
.global vu_meter
.func vu_meter
vu_meter:
	
	BL dc_offset
	STMFD sp! , {r0}			 //Stack return of offset
	MOV r11, #0 				// Initialize Counter
infloop: LDR r3,=0xE0034004	    //Load the address of the sample
	LDR r4, [r3]				//Load the content of the sample into r4
	MOV r12, r4   				//Make a copy of the returned value	
	MOV r5, r4, LSR #31			//We store the bit 31 of sample into r5. 
	CMP r5, #1					//check whether new sample is available
	BNE infloop					//if new sample is not available, restart the loop.
	LDR r10,=0x3ff
	MOV r4, r12   				//Revert to the copy of the sample			
	MOV r4, r4, LSR #6			//when a sample is available, extract the sample bits 6:15.
	AND r4, r4, r10				//Clear out remaining 0:5 bits
	LDMFD sp, {r0}				//Recall the initial DC offset (and dont update sp)
	SUB r4, r4, r0				//Subtract the DC offset from the sample
	MUL r4, r4, r4    			//square the result
	MOV r7, #18					//convert the result into a fixed point.
	LDR r12,=FRACBITS			//Obtain the content of Fracbits into r12.
	RSB r7, r7, r12				//r7 = Fracbits - 18
	MOV r4, r4, LSL r7			//accomplished both shifts in one step.
	MOV r0, r4					//r0 now has the calculated value.
	STMFD sp!, {r0}				//allocate space for an integer on the stack
	MOV r1, sp					//move the stack pointer to r1 as the filter function accepts.
	BL filter					//branch to filter function with input of r0, r1
	ADD r11, r11, #1			//increment the counter of the loop
	CMP r11, #166				//Compare the counter to 166.
	MOVEQ r0, r4				//if counter is 166, put the calculated value back into r0
	BLEQ display				//and go to display
	MOVEQ r1, #0				//if going to display, reset the counter to 0
	B infloop					//branch to the top of the loop
	
	bx	lr
.endfunc


/**
 *  int dc_offset();
 */
.func dc_offset
dc_offset:

	STMFD sp!, {r3-r12, lr}
	LDR r0, =0	//Accumulator
	LDR r1, =20000	//limit of loop.
	LDR r6, =0		//initial loop.
	LDR r10,=0x3ff
	
	loop:			
		sampleloop: LDR r3, =AD0GDR	//load the address of input
					LDR r4, [r3]				//Load the content of the sample into r4
					MOV r12, r4					//Make a copy of r4
					MOV r5, r4, LSR #31			//We store the bit 31 of sample into r5. 
					CMP r5, #1					//check whether new sample is available
					BNE sampleloop				//if new sample is not available, restart the loop.
		MOVEQ r4, r12		//revert to old copy of r4
		MOV r4, r4, LSR #6  //extract the sample from bits 6:15
		AND r4, r4, r10
		ADD r0, r0, r4		//update the accumulator
		CMP r6, r1			//compare the vaule of initial and limit of loop
		ADD r6, r6, #1		//Increment the counter
		BLT	loop			//if the counter is less than the counter, enter loop
		
	BL __aeabi_idiv		//divide the accumulator by 20000 by using routine
						//r0 should have the result
	LDMFD sp!, {r2-r12, lr}	//pop back the registers
	
	BX lr
.endfunc


/**
 *  int filter(int x, int *w);
 */
.func filter
filter:

//enter the function with r0 = calculated sample, r1= stack pointer to blank integer

STMFD sp!, {r2-r12, lr}			//stack any registers
LDR r2,=0x263e9c			//Load coefficient of FILT_K
SMULL r3, r4, r0, r2		//execute 64-bit multiply
MOV r0, r3, LSR#FRACBITS	//shift lo word to the right by FRACBITS
ORR r0, r0, r4, LSL#(32- FRACBITS)	//shift hi word to the right by FRACBITS and OR with lo word
BL __aeabi_f2iz				//change floating number to integer.

LDR r8, [r1]
ADD r5, r8, r0				// y = *w + x
MOV r10, r5                 //save y

MOV r11, r0					//move x into r11

LDR r7,=0xf04c7d3a			//Load coefficient FILT_A
SMULL r3, r4, r5, r7 		// implement same calculation as before
MOV r5, r3, LSR#FRACBITS	//r8 is shifted by fracbits
ORR r5, r5, r4, LSL#(32- FRACBITS) // shift hi word to the right by fracbits 

MOV r0, r5    //move *w into r0
BL __aeabi_f2iz //change it to integers
MOV r5, r0   //the returned value is now in r5

SUB r5, r11, r5	//*w = x - returned value
STR r5, [r1]    //Store *w

MOV r0, r10     // y is in r0

LDMFD sp!, {r2-r12, lr}		//put back the stack
	bx		lr
.endfunc


/**
 *  int display(int x);
 */
.func display
display:

	STMFD sp!, {r2-r12, lr}
	ADD r0, r0, #2	//add x with 2
	BL __aeabi_i2f	//should convert integer to floating point. answer in r0
	
	LDR r1, =FLOAT1	//Floating representation of 1<<28
	BL __aeabi_fdiv	//Divide r0 by r1 and return the result into r0
	
	BL log10f
	
	LDR r1,= 0x402CCCCD		//load the floating point representation of 2.7
	
	BL __aeabi_fadd			//ad 2.7f to the calculated
	
	LDR r1,=0x40466666		//load 3.1f
	
	BL __aeabi_fmul	//multiply the r0 by r1
	BL __aeabi_f2iz	//turn the floating back into integer
	
	
	CMP r0, #8		//compare r0, now(int k),with integer 8p
	MOVGT r0, #8	//if r0 greater than 8, put 8 in r0
	CMP r0, #0		//same for lower limit of 0
	MOVLT r0, #0
	
	LDR r4, =FIO0SET	//load the address of FIO0SET
	LDR r5,=0xFF		//set clear address
	STR r5, [r4] 		//load the clearing address into FIO0SET(Clears LED's)
	
	LDR r7, =FIO0CLR		//load address of FIO0CLR
	RSB r6, r0, #8			//computes r6 = 8 - k
	MOV r5, r5, LSR r6		//compute oxff>>(8-k)	
	STR r5, [r7]			//store it into FIO0CLR
	
LDMFD sp!, {r2-r12, lr}
	BX		lr
.endfunc

.end
