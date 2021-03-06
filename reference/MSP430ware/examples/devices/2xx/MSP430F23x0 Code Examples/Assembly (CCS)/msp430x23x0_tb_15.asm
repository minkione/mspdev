;*******************************************************************************
;   MSP430F23x0 Demo - Timer_B, PWM TB1-2, Up/Down Mode, HF XTAL ACLK
;
;   Description: This program generates two PWM outputs on P4.1,2 using
;   Timer_B configured for up/down mode. The value in TBCCR0, 128, defines
;   the PWM period/2 and the values in TBCCR1-2 the PWM duty cycles. Using
;   HF XTAL ACLK as TBCLK, the timer period is HF XTAL/256 with a 75%
;   duty cycle on P4.1 and 25% on P4.2.
;   ACLK = MCLK = TBCLK = HF XTAL
;   //* HF XTAL REQUIRED AND NOT INSTALLED ON FET *//
;   //* Min Vcc required varies with MCLK frequency - refer to datasheet *//
;
;                MSP430F23x0
;             -----------------
;         /|\|              XIN|-
;          | |                 | HF XTAL (3  16MHz crystal or resonator)
;          --|RST          XOUT|-
;            |                 |
;            |         P4.1/TB1|--> TBCCR1 - 75% PWM
;            |         P4.2/TB2|--> TBCCR2 - 25% PWM
;
;  JL Bile
;  Texas Instruments Inc.
;  June 2008
;  Built Code Composer Essentials: v3 FET
;*******************************************************************************
 .cdecls C,LIST, "msp430x23x0.h"
;-------------------------------------------------------------------------------
			.text	;Program Start
;-------------------------------------------------------------------------------
RESET       mov.w   #450h,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT
SetupP4     bis.b   #006h,&P4DIR            ; P4.1 and P4.2 output
            bis.b   #006h,&P4SEL            ; P4.1 and P4.2 TB1/2 otions
SetupBC     bis.b   #XTS,&BCSCTL1           ; LFXT1 = HF XTAL
            mov.b   #LFXT1S1,&BCSCTL3       ; LFXT1S1 = 3-16Mhz
SetupOsc    bic.b   #OFIFG,&IFG1            ; Clear OSC fault flag
            mov.w   #0FFh,R15               ; R15 = Delay
SetupOsc1   dec.w   R15                     ; Additional delay to ensure start
            jnz     SetupOsc1               ;
            bit.b   #OFIFG,&IFG1            ; OSC fault flag set?
            jnz     SetupOsc                ; OSC Fault, clear flag again
            bis.b   #SELM_3,&BCSCTL2        ; MCLK = LFXT1
SetupC0     mov.w   #128,&TBCCR0            ; PWM Period/2
SetupC1     mov.w   #OUTMOD_6,&TBCCTL1      ; TBCCR1 toggle/set
            mov.w   #32,&TBCCR1             ; TBCCR1 PWM Duty Cycle
SetupC2     mov.w   #OUTMOD_6,&TBCCTL2      ; TBCCR2 toggle/set
            mov.w   #96,&TBCCR2             ; TBCCR2 PWM duty cycle
SetupTB     mov.w   #TBSSEL_1+MC_3,&TBCTL   ; ACLK, updown mode
                                            ;
Mainloop    bis.w   #CPUOFF,SR              ; CPU off
            nop                             ; Required only for debugger
                                            ;
;-------------------------------------------------------------------------------
;			Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect	".reset"            ; MSP430 RESET Vector
            .short	RESET                   ;
            .end
