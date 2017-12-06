#include <lpc2148/lpc214x.h>
#include <lpc2148/openlpc.h>

extern void vu_meter();

int	main (void)
{
	// select P0.0-P0.7 as outputs
	FIO0DIR |= 0xff;

	// blink the leds to show we're alive
	FIO0CLR = 0xff;
	delay_ms(200);
	FIO0SET = 0xff;

	// Select MAT0.1 (P0.5)
	//PINSEL0 |= (2 << 10);

	// Select DAC (P0.25), AD0.1 (P0.28)
	PINSEL1 |= (2 << 18) | (1 << 24);

	// AD0.1, operational, conversions start on rising edge of MAT0.1
	AD0CR = (1 << 1) | (13 << 8) | (1 << 21) | (4 << 24);

	// start T0 counting
	T0TCR = 2;					// disable timer, put in reset mode.
	T0CTCR = 0;					// select timer mode
	T0PR = 0; 					// prescale register to 1
	T0MR1 = 1500-1;				// sampling rate is 20Khz (60M/1500/2 = 20khz)
	T0MCR = 1 << 4;				// when timer0 matches the match1 register, the timer will be reset
	T0EMR = 3 << 6;				// when timer0 matches the match1 register, MAT0.1 will be toggled
	T0TCR = 1;					// take the timer out of reset mode and enable for counting.
	
	vu_meter();

	return 0;
}
