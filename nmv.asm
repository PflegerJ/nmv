.segment "HEADER"

    ; 16 byte header
	.byte	"NES" 
    .byte   $1A	        ; iNES header identifier
	.byte	$02		    ; 2x 16KB PRG code - lists how much program rom you have
	.byte   $01		    ; 1x  8KB CHR data - lists how much chr rom you have
	.byte   $01         ; mapper 0
    .byte   $00	        ; vertical mirroring off
    .byte   $00         ; iNES_SRAM
    .byte   $00         ; iNES Mapper?
    .byte   $00         ; iNES Mapper?
    .byte   $00, $00, $00, $00, $00  ; padding

.segment "STARTUP"
.segment "ZEROPAGE"
    pointerLo:  .res 1
    pointerHi:  .res 1
    PPU_Buffer: .res 1

.segment "CODE"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; my goal is to basically rewrite all of this so i wrote it. and stumble through figuring out how to communicate with the ppu 
; so that i can try to make some stupid music video with background updates and bank swapping and all that crazy fun stuff
vblankwait: 
    rts 

RESET:
    sei         ; ignore IRQs
    cld         ; disable decimal mode
    ldx #$40    
    stx $4017   ; disable APU frame IRQ
    lda #%10010000
    sta $2000    
    lda #%00011110
    sta $2001




clearnametables:
   

Main:
    lda #$20
    sta $2006
    lda #$00
    sta $2006
hi:
    lda #$01
    sta $2007
    jmp hi

VBLANK:
    lda #$20
    sta $2006
    lda #$00
    sta $2006
hi:
    lda #$00
    sta $2007
    inc 
    jmp hi
    rti 

.segment "VECTORS"
    .word VBLANK
    .word RESET
    .word 0

.segment "CHARS"
    .incbin "mario.chr"