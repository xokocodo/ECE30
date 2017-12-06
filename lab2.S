/*****************************************************************************

lab2.S
Daniel Peters A10103585
Chunghoon Woo A09241868
C.J Vanzant A10236730
  The function delay_audio(), defined below in this module, will be called by
  main() immediatly after a new sample becomes available from the analog
  to digital converter. Your function should do the following:
    1. Grab the new sample from the AD0GDR register (memory address 0xE0034004)
	   The 10-bit value is available in bits 6:15. All other bits should be
	   discarded.
	2. Write out the oldest value in the buffer to the DACR register
	   (memory address 0xE006C000). The value should be written to bits 6:15.
	   Zeros should be written to all other bit positions.
	3. Save the new sample into the array cell occupied by the oldest value.
	4. Update any counters/indexes/pointers relating to your circular buffer.

  Remember that this function is called at 40Khz, so it has to execute FAST!

  Comment your code clearly with the logical steps that you are performing.
  Uncommented code will receive zero credit.
  
*****************************************************************************/
.set AD0GDR, 		0xE0034004
.set DACR,			0xE006C000
.set BUFLEN, 10000
.bss
.balign 2
buf: .skip(2*BUFLEN)

.balign 4
n: .skip 4

/**
 * void delay_audio();
 */
 
.text
.balign 4
.global delay_audio

delay_audio:
	
LDR r3, =n                                //r3=Address of n (counter)
LDR r4, =buf                              //r4= Address of buf
LDR r6, =DACR                              //r6=Address of Output
LDR r7, =AD0GDR                           //r7= Address of Input
LDR r11, [r3]                           //r11= Value of n

LDR r1, =10000
CMP r11, r1			//compare the value of n
MOVGT r11, #0				//if greater than 10000, set it to 0
CMP r11, #0				//also, if less than 10000, 
MOVLT r11, #0				//set it to 0

LDRH r8, [r7]                           //Load New Value
MOV  r8, r8, LSR #6                       //Shift new value to bits 
											//to discard 0:5

MOV r2, r11, LSL #1						//arithmetic to old value
LDRH r9, [r4, r2]!               		//Loads Old Value
STRH r8, [r4]                           //Store new value into buffer
MOV  r9, r9, LSL #6                     //Shift old value back to bits 6:15
STRH r9, [r6]                           //Stores old value into output
ADD  r11, r11, #1                       //Increments counter
CMP r11, r1                            //Checks counter
MOVEQ r11, #0                           //If 10000, reset to 0
STR  r11,[r3]                           //Stores Counter

bx lr			// return

	
.end
