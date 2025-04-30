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
    tempLo:     .res 1
    tempHi:     .res 1
    temp1:      .res 1
    flag1:      .res 1
    p1:         .res 1

    ; variables for the buffer
    PPU_BufferOffset:   .res 1

    PPU_BUFFER_START    = $0100

    PPU_CTRL            = $2000 ; Miscellaneous Settings - Write
    ; VPHB SINN
            ; Vblank NMI  
            ; PPU direction (0 read backfrom EXT pins; 1 output color on EXT pins)  THIS SHOULD NEVER BE SET TO 1 on stock consoles. MAY DAMAGE PPU
            ; Sprite size 
            ; Background pattern table address

            ; sprite pattern table address for 8x8  
            ; vram address increment per cpu r/w of ppudata (0 add 1, going across; 1 add 32 going down)  
            ; base name table (0 = $2000; 1: $2400; 2: $2800; 3: $2C00)


    PPU_MASK            = $2001 ; Rendering Settings - Write
    ; BGRs bMmG
            ; Emphasize Blue
            ; Emphasize Green 
            ; Emphasize Red
            ; Enable sprite rendering 

            ; Enable background rendering
            ; Enable showing sprite in leftmost 8 pixels of screen
            ; Enable showing background in leftmost 8 pixels of screen
            ; Enable greyscale

    PPU_STATUS          = $2002 ; Rendering Events - Read
    ; VSOx xxxx
            ; Vblank Flag - cleared on read
            ; Sprite 0 hit flag
            ; sprite overflow flag
            ; PPU open bus (or 2C05 PPU identifier)

    OAM_ADDR            = $2003 ; Sprite RAM Address - Write 
    ; AAAA AAAA
            ; OAM Address
    
    OAM_DATA            = $2004 ; Sprite RAM Data - Read/Write
    ; DDDD DDDD
            ; OAM Data

    
    PPU_SCROLL          = $2005 ; X and Y scroll - Write
    ; XXXX XXXX
    ; YYYY YYYY
            ; X scroll bits 7 - 0 (bit 8 in PPU_CTRL bit 0)
            ; Y scroll bits 7 - 0 (bit 8 in PPU_CTRL bit 1)
    
    PPU_ADDR            = $2006 ; VRAM address - Write
    ; ..AA AAAA
    ; AAAA AAAA
            ; Hi then Lo
    
    PPU_DATA            = $2007 ; VRAM data - Read/Write
    ; DDDD DDDD
            ; Data baby

    OAM_DMA             = $4014 ; Sprite DMA - Write
    ; AAAA AAAA
            ; Hi byte of source address


.segment "CODE"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; my goal is to basically rewrite all of this so i wrote it. and stumble through figuring out how to communicate with the ppu 
; so that i can try to make some stupid music video with background updates and bank swapping and all that crazy fun stuff
vblankwait:
    bit PPU_STATUS 
    bpl vblankwait
    rts 

TurnOnRendering:

    rts 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   Palette
;       SAAPP   5 bit index into palette RAM
;               Background/Sprite select
;               Palette number from attributes
;               Pixel value from tile pattern data
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WritePalette:

    lda PPU_STATUS
    lda #$3F
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR
    lda #$13
    sta PPU_DATA
    lda #$1C
    sta PPU_DATA
    lda #$2B
    sta PPU_DATA
    lda #$39
    sta PPU_DATA
    rts 

WriteP1:
    lda PPU_STATUS
    lda #$3F
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR
    lda p1
    sta PPU_DATA
    clc 
    adc #$01 
    sta p1   
    rts 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ok so I need a system, that will write to the ppu from a buffer
;   so this means I need to what. choose buffer format.
;   write to the buffer


;   count, hi, lo, data1, ... 
; assuming pointerlo already set up
WriteToPPUBuffer:
    ldy #$00
    ldx PPU_BufferOffset
    lda (pointerLo),y 
    clc 
    adc #$03
    sta temp1
    sta PPU_BUFFER_START,x 
    inx 
    iny 
    lda (pointerLo),y 
    sta PPU_BUFFER_START,x
    inx 
    iny 
    lda (pointerLo),y 
    sta PPU_BUFFER_START,x 
    inx 
    iny 
@DataLoopStart:
    lda (pointerLo),y 
    sta PPU_BUFFER_START,x 
    inx 
    iny 
    cpy temp1
    bne @DataLoopStart
    stx PPU_BufferOffset
    rts 

WriteBufferToPPU:
    ; first we need to load the count and store the address
    ldx #$00
    cpx PPU_BufferOffset
    beq THIS
@WriteOuterLoopStart:
    ldy PPU_BUFFER_START,x 
    inx 
    lda PPU_BUFFER_START,x
    sta $2006
    inx 
    lda PPU_BUFFER_START,x
    sta $2006
    inx 
@WriteInnerLoopStart:
    lda PPU_BUFFER_START,x
    sta $2007
    inx 
dey 
    beq @DoneInner
    jmp @WriteInnerLoopStart

@DoneInner:
    cpx PPU_BufferOffset
    bne @WriteOuterLoopStart
    sty PPU_BufferOffset
THIS:
    rts 


RESET:
    sei         ; ignore IRQs
    cld         ; disable decimal mode
    ldx #$40    
    stx $4017   ; disable APU frame IRQ
    ldx #$ff    ; set up the stack (idk what this actually does yet)
    txs         ; stack stuff
    inx         ; x is 0 now
    ; above this comment is like. basic boot. I turn off apu cause fuck that. I set up stack somehow. 


    jsr vblankwait



    ; lda #%10111110
    lda #$00
    sta PPU_CTRL    ; turning off vblank, setting nametable addresses, sprite size, i think i only care about vblank being on or off rn the rest is stuff i'll understand later

    jsr vblankwait

    lda #$00
    sta p1
    sta temp1
    sta PPU_MASK

    jsr vblankwait

    jsr WritePalette

    jsr vblankwait

    lda #$08 
    sta PPU_MASK

    jsr vblankwait

    lda #$80
    sta PPU_CTRL


Forever:
    jmp Forever
   
VBLANK:
    inc temp1 
    lda temp1
    cmp #$0A
    bne @skip
    jsr WriteP1
    lda #$00
    sta temp1

@skip:
    rti 

.word TestData01
TestData01:
    .byte $05, $20, $00, $00, $01, $02, $03, $04

.segment "VECTORS"
    .word VBLANK
    .word RESET
    .word 0

.segment "CHARS"
    .incbin "mario.chr"