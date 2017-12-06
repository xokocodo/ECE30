/*****************************************************************************

lab5.S
Daniel Peters A10103585u 
C.J Vanzant A10236730
Chunghoon Woo A09241868

 You need to implement the function lab5() below. lab5() should blink the LEDs
 as described in the project specification. lab5() is called by main
 in an infinite loop. You need to save any callee-save registers that
 this function overwrites. For this you can use the stmfd instruction.
 You will also need to reserve space on the stack for the duty[] array.
 
 Comment your code clearly with the logical steps you are performing.
 Uncommented code will receive zero credit.
   
*****************************************************************************/


.set FIO0SET,		0x3FFFC018
.set FIO0CLR,		0x3FFFC01C

.text
.align 4

.balign 4
offTime: .skip 32

/*
 * void lab5();

 */
.global lab5
.func lab5
lab5:

STMFD sp!, {r4-r11,lr}

TopofCode: MOV r6, #0
loop: 
		
		LDR r12,=0x3FFFC018
		LDR r4,=0x3FFFC01C
		MOV r5, #0xff
		STR r5, [r4]
		MOV r0, #250
		BL delay_ms
		STR r5, [r12]
		MOV r0, #250
		BL delay_ms
		ADD r6, r6, #1
		CMP r6, #5
		BNE loop
MOV r0, #2000
BL delay_ms		
MOV r6, #0
MOV r7, #1
loop2: 
		
		LDR r12,=0x3FFFC018
		LDR r4,=0x3FFFC01C
		
		MOV r5, r7, LSL r6
		STR r5, [r4]		
		MOV r0, #100
		BL delay_ms
		STR r5, [r12]
		ADD r6, r6, #1
		CMP r6, #7
		BNE loop2
MOV r5, r7, LSL #8
STR r5, [r4]
loop3: 

		LDR r12,=0x3FFFC018
		LDR r4,=0x3FFFC01C
		
		MOV r5, r7, LSL r6
		STR r5, [r4]
		MOV r0, #100
		BL delay_ms
		STR r5, [r12]
		CMP r6, #0
		SUB r6, r6, #1
		BNE loop3

MOV r0, #2000
BL delay_ms	

MOV r0, #0 
MOV r1, #0 
MOV r2, #0 
MOV r3, #0 
MOV r4, #0
MOV r5, #0 
MOV r6, #0 
MOV r7, #0 
MOV r8, #0 	
MOV r9, #0 
MOV r10, #0 
MOV r11, #0 

/////////////////////////////////////////////////////////////////////////


MOV r4, #0 // n=0
LDR r11, =40000   //Load 40,000
BL csubmillis     //
ADD r11, r11, r0  // end = csubmillis + 40000
MOV r5, #0 //nextDuty = 0  
LDR r8, =offTime  //Address of offTime
LDR r9, =FIO0CLR  //Address of FIO0CLR
MOV r10, #0xff    //Value to turn off LEDs

		
OuterWhile: BL csubmillis     //			
			CMP r0, r11  // Compare csubmillis() and end
				BGE endofcode  //if submillis >= end, stop thile loop
				
				BL csubmillis     //
								
				CMP r0, r5
				BLT endIf1
			
				BL csubmillis     //	
				MOV r6, r0   // now = csubmillis()
				ADD r5, r6, #100   //nextDuty = now + 100
				MOV r7, #0        // i=0
				forLoop1: CMP r7, #8    
				
						BGE endForLoop1       //if foor loop condition not met, skip down
						MOV r0, r7           //get ready to call compute_duty
						MOV r1, r4   
						BL compute_duty     // (i,n)
						ADD r0, r0, r6      //now + compute_duty(i,n)
						STR r0, [r8, r7, LSL#2]  // offTime[i] = now + compute_duty(i, n);
						ADD r7, r7, #1
						B forLoop1               //jump to loop top
			
			endForLoop1: STR r10, [r9]	  // FIO0CLR = 0xff;
			ADD r4, r4, #1                // n++
			CMP r4, #1000                //if(n >= 1000)
			MOVGE r4, #0                  //n = 0;
			
		endIf1: MOV r7, #0	      // i=0
		forLoop2:CMP r7, #8      // compare i and 8
				
				BGE OuterWhile  //if i>=8, skip down
				
				BL csubmillis     //
				
				LDR r1, [r8, r7, LSL#2]
				CMP r0, r1            //if(csubmillis() < offTime[i]), skip down
				MOVGE r2, #1
				MOVGE r2, r2, LSL r7
				LDRGE r12, =FIO0SET //Address of FIO0SET
				STRGE r2, [r12]
				ADD r7, r7, #1   //i++
				B forLoop2
		
		
endofcode:	LDMFD sp!, {r4-r11,lr}
bx	lr

.endfunc
.end
