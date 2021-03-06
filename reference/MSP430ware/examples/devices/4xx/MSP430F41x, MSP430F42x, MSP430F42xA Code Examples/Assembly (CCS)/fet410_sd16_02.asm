;******************************************************************************
;   MSP-FET430P410 Demo - SD16, Single Conversion on a Group of Channels
;
;   Description: This program uses the SD16 module to perform a single
;   conversion on a group of channels (0, 1, and 2). A SD16 interrupt occurs
;   when the conversions have completed. Test by applying voltages to the
;   three input channels and setting a breakpoint at the line indicated
;   below. Run program until it reaches the breakpoint, then use the
;   debugger's register window to view the conversion results. CH0 results
;   are stored in register R5, CH1 results are stored in register R6, and
;   CH2 results are stored in register R7.
;   ACLK = LFXT1 = 32768Hz, MCLK = SMCLK = default DCO = 32 x ACLK = 1048576Hz
;   ;* An external watch crystal between XIN & XOUT is required for ACLK *//	
;   ;* Minimum Vcc is required for SD16 module - see datasheet        *//
;   ;* 100nF cap btw Vref and AVss is recommended when using 1.2V ref *//
;
;                 MSP430F427
;              -----------------
;          /|\|              XIN|-
;           | |                 | 32kHz
;           --|RST          XOUT|-
;             |                 |
;    Vin1+ -->|A0.0+            |
;    Vin1- -->|A0.0-            |
;    Vin2+ -->|A1.0+            |
;    Vin2- -->|A1.0-            |
;    Vin3+ -->|A2.0+            |
;    Vin3- -->|A2.0-            |
;             |                 |
;             |            VREF |---+
;             |                 |   |
;             |                 |  -+- 100nF
;             |                 |  -+-
;             |                 |   |
;             |            AVss |---+
;             |                 |
;
;   H. Grewal / S. Karthikeyan
;   Texas Instruments Inc.
;   May 2005
;   Built with Code Composer Essentials Version 1.0
;******************************************************************************
 .cdecls C,LIST,  "msp430x42x.h"

;-----------CPU Registers Used-------------------------------------------------
;           R5 - SD16MEM0 conversion result
;           R6 - SD16MEM1 conversion result
;           R7 - SD16MEM2 conversion result
;           R15 - Temporary working register

;------------------------------------------------------------------------------
            .text                  ; Program Start
;------------------------------------------------------------------------------
RESET       mov     #600h,SP                ; Initialize stack pointer
StopWDT     mov     #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT
SetupFLL    bis.b   #XCAP14PF,&FLL_CTL0     ; Configure load caps
            mov     #10000,R15              ;
Xtal_Wait   dec     R15                     ; Delay for 32 kHz crystal to
            jnz     Xtal_Wait		        ; stabilize
SetupSD16   mov     #SD16REFON+SD16SSEL0,&SD16CTL ; 1.2V ref, SMCLK
            bis     #SD16SNGL+SD16GRP,&SD16CCTL0  ; Single conv, group
            bis     #SD16SNGL+SD16GRP,&SD16CCTL1  ; Single conv, group
            bis     #SD16SNGL+SD16IE,&SD16CCTL2   ; Single conv, enable int.
                                            ; CH2 is master of channel group
            mov     #03600h,R15             ; Delay needed for 1.2V ref startup
L$1         dec     R15                     ;
            jnz     L$1                     ;
            eint                            ; Enable global interrupts
Mainloop    bis     #SD16SC,&SD16CCTL2      ; Start conversion for all channels
            bis     #CPUOFF,SR              ; Enter LPM0 (disable CPU), wait for
                                            ; conversions to complete
            nop                             ; Required for debug only
            jmp     Mainloop                ; set BREAKPOINT HERE
                                            ;
;------------------------------------------------------------------------------
SD16_ISR    ; SD16 Interrupt Service Routine
;------------------------------------------------------------------------------
            add.w   &SD16IV,PC              ; Add offset to PC
            reti                            ; Vector 0: No interrupt
            jmp     SD_OV                   ; Vector 2: Overflow
            jmp     SD_CH0                  ; Vector 4: CH0 IFG
            jmp     SD_CH1                  ; Vector 6: CH1 IFG
                                            ; Vector 8: CH2 IFG
                                            ;
;-----------SD16 Channel 2 Interrupt Handler-----------------------------------
SD_CH2      mov     &SD16MEM2,R7            ; Save CH2 conversion result
            mov     &SD16MEM1,R6            ; Save CH1 conversion result
            mov     &SD16MEM0,R5            ; Save CH0 conversion result
            bic     #CPUOFF,0(SP)           ; Return active
SD_CH2_END  reti                            ; Return from interrupt
                                            ;
;-----------SD16 Memory Overflow Interrupt Handler-----------------------------
SD_OV       reti                            ; Return from interrupt
                                            ;
;-----------SD16 Channel 0 Interrupt Handler-----------------------------------
SD_CH0      reti                            ; Return from interrupt
                                            ;
;-----------SD16 Channel 1 Interrupt Handler-----------------------------------
SD_CH1      reti                            ; Return from interrupt
                                            ;
;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   ".reset"                ; RESET Vector
            .short  RESET                   ;
            .sect   ".int12"                ; SD16 Vector
            .short  SD16_ISR                ;
            .end
