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
    badAppleLo: .res 1
    badAppleHi: .res 1

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
InitializePalette:
    lda PPU_STATUS
    lda #$3F
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR
   ; tay 
    ;tax 
    ;lda #$C1
;@loop:
 ;   sta PPU_DATA
 ;   iny  
  ;  cpy #8
   ; bne @loop
   ; inx 
   ; cpx #2
   ; beq @done
   ; lda #$FF
   ; jmp @loop
;@done:
  ;  rts


    lda #$FF
    sta PPU_DATA
    sta PPU_DATA
    sta PPU_DATA
    sta PPU_DATA

    sta PPU_DATA
    sta PPU_DATA
    sta PPU_DATA
    sta PPU_DATA

    lda #$30

    sta PPU_DATA
    sta PPU_DATA
    sta PPU_DATA
    sta PPU_DATA

    sta PPU_DATA
    sta PPU_DATA
    sta PPU_DATA
    sta PPU_DATA
    rts 


InitializeBadApple:
    ldx #$00
    lda frameAddr,x
    sta badAppleLo
    inx 
    lda frameAddr,x
    sta badAppleHi
    rts 

WriteBadAppleFrame:

    lda PPU_STATUS
    lda #$23
    sta PPU_ADDR
    lda #$C0
    sta PPU_ADDR

    ldy #$00
@BadAppleWriteLoop:
    lda (badAppleLo),y
    sta PPU_DATA
    iny 
    cpy #$40
    bne @BadAppleWriteLoop
    rts 

WriteBadAppleFrame2:
    ldy #$00
    lda (badAppleLo),y 
    cmp #$88
    beq @AAAA
	and #%01000000
    ;cmp #$11
	cmp #%01000000
    bne @Full
    jsr PartialWrite
    jmp @AlmostDone 
@AAAA:
    iny 
    jmp @AlmostDone

@Full:
    jsr WriteBadAppleFrame

@AlmostDone:
    tya 
    clc 
    adc badAppleLo
    sta badAppleLo
    lda badAppleHi
    adc #$00
    cmp #$00
    bne @storeHi
    ldx #$01
    lda frameAddr,x 
@storeHi:
    sta badAppleHi

@Done:
    rts 

PartialWrite:
	lda (badAppleLo),y 
	and #%00111111
	tax 
    iny 
@hhhh:
    lda PPU_STATUS
    lda #$23
    sta PPU_ADDR
    lda (badAppleLo),y 
    sta PPU_ADDR
    iny 
    lda (badAppleLo),y 
    sta PPU_DATA
    iny 
	dex 
	cpx #$00
	bne @hhhh
	rts 

  ;  lda (badAppleLo),y 
   ; cmp #$11
   ; bne @hhhh
   ; iny 
   ; rts 



;@PartialLoop:
;    lda (badAppleLo),y 
;    cmp #$11
;    beq @DonePartial
;    lda PPU_STATUS
;    lda #$3F
;    sta PPU_ADDR
;    lda (badAppleLo),y 
;    sta PPU_DATA
;    iny 
;    jmp @PartialLoop

;@DonePartial:
;    rts 

Check:
    lda badAppleHi
    cmp #$FF
    bne @exit
    lda badAppleLo
    cmp #$C0
    bcc @exit
    ldx #$01
    lda frameAddr,x
    sta badAppleHi
@exit:
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
    ;sta p1
   ; sta temp1
    sta PPU_MASK

    jsr vblankwait

    ;   jsr WritePalette

    jsr InitializePalette
    jsr InitializeBadApple


    jsr vblankwait

    lda #$0A 
    sta PPU_MASK

    jsr vblankwait

    lda #$80
    sta PPU_CTRL

    lda #$00
    sta PPU_SCROLL
    sta PPU_SCROLL

Forever:
    jmp Forever
   
VBLANK:
    

    jsr WriteBadAppleFrame2
    jsr Check
    lda #$00
    sta PPU_SCROLL
    sta PPU_SCROLL
   
    rti 

frameAddr:
    .byte <frame0, >frame0
.byte $00
frame0:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000

frame1:
	.byte $88
frame2:
	.byte $88
frame3:
	.byte $88
frame4:
	.byte $88
frame5:
	.byte $88
frame6:
	.byte $88
frame7:
	.byte $88
frame8:
	.byte $88
frame9:
	.byte $88
frame10:
	.byte $88
frame11:
	.byte $88
frame12:
	.byte $88
frame13:
	.byte $88
frame14:
	.byte $88
frame15:
	.byte $88
frame16:
	.byte $88
frame17:
	.byte $88
frame18:
	.byte $88
frame19:
	.byte $88
frame20:
	.byte $88
frame21:
	.byte $88
frame22:
	.byte $88
frame23:
	.byte $88
frame24:
	.byte $88
frame25:
	.byte $88
frame26:
	.byte $88
frame27:
	.byte $88
frame28:
	.byte $88
frame29:
	.byte $88
frame30:
	.byte $88
frame31:
	.byte $88
frame32:
	.byte $88
frame33:
	.byte $88
frame34:
	.byte $88
frame35:
	.byte $88
frame36:
	.byte $88
frame37:
	.byte $88
frame38:
	.byte $88
frame39:
	.byte $88
frame40:
	.byte $88
frame41:
	.byte $88
frame42:
	.byte $88
frame43:
	.byte $88
frame44:
	.byte $88
frame45:
	.byte $88
frame46:
	.byte $88
frame47:
	.byte $88
frame48:
	.byte $88
frame49:
	.byte $88
frame50:
	.byte $88
frame51:
	.byte $88
frame52:
	.byte $88
frame53:
	.byte $88
frame54:
	.byte $88
frame55:
	.byte $88
frame56:
	.byte $88
frame57:
	.byte $88
frame58:
	.byte $88
frame59:
	.byte $88
frame60:
	.byte $88
frame61:
	.byte $88
frame62:
	.byte $88
frame63:
	.byte $88
frame64:
	.byte $88
frame65:
	.byte $88
frame66:
	.byte $88
frame67:
	.byte $88
frame68:
	.byte $88
frame69:
	.byte $88
frame70:
	.byte $88
frame71:
	.byte $88
frame72:
	.byte $88
frame73:
	.byte $88
frame74:
	.byte $88
frame75:
	.byte $88
frame76:
	.byte $88
frame77:
	.byte $88
frame78:
	.byte $88
frame79:
	.byte $88
frame80:
	.byte $88
frame81:
	.byte $88
frame82:
	.byte $88
frame83:
	.byte $88
frame84:
	.byte $88
frame85:
	.byte $88
frame86:
	.byte $88
frame87:
	.byte %01000001, $E7, %00001100
frame88:
	.byte %01000011, $DF, %11001100, $E7, %11001100, $EF, %00001100
frame89:
	.byte %01000011, $C7, %11001100, $CF, %11001100, $D7, %11001100
frame90:
	.byte %01000001, $E7, %11111100
frame91:
	.byte %01000001, $C7, %11000000
frame92:
	.byte %01000101, $C7, %00000011, $CF, %11000000, $DF, %11111111, $E7, %11001100, $EF, %11001100
frame93:
	.byte %01000101, $C7, %00000000, $CF, %00110000, $D7, %00110011, $E7, %11111111, $EF, %11001111
frame94:
	.byte %01000100, $CF, %00000000, $D7, %00000000, $DF, %11110011, $F7, %11001100
frame95:
	.byte %01000101, $DF, %00110000, $E6, %11001100, $E7, %11110011, $EF, %11111111, $FF, %00001100
frame96:
	.byte %01000110, $DE, %11000000, $DF, %00000000, $E7, %00110011, $EE, %00001100, $EF, %11110011, $F7, %11111111
frame97:
	.byte %01000110, $DE, %00000000, $E6, %00000000, $E7, %00110000, $EE, %00000000, $EF, %11111111, $F7, %11001111
frame98:
	.byte %01001000, $C7, %11001100, $CF, %11001100, $D7, %00001100, $DF, %11001100, $E6, %00110011, $E7, %11001100, $EF, %11001100, $F7, %11001100
frame99:
	.byte %01001001, $C7, %11111111, $CF, %11111111, $D7, %11001111, $DF, %11111111, $E6, %00000000, $E7, %11111111, $EF, %11111111, $F7, %11111111, $FF, %00001111
frame100:
	.byte %01001000, $C6, %11001100, $CE, %11001100, $D6, %11001100, $D7, %11111111, $DE, %11000000, $E6, %11001100, $EE, %11001100, $F6, %00001100
frame101:
	.byte %01000110, $C6, %11111111, $CE, %11111111, $DE, %11111100, $E6, %11111111, $EE, %11001111, $F6, %11001100
frame102:
	.byte %01000110, $C5, %00001100, $D6, %11111111, $DE, %11111111, $E5, %11001100, $EE, %11111111, $FE, %00001100
frame103:
	.byte %01000110, $C5, %11001100, $CD, %11001100, $D5, %11001100, $DD, %00001100, $ED, %00001100, $F6, %11001111
frame104:
	.byte %01000010, $DD, %11001100, $E5, %11001111
frame105:
	.byte %01000110, $C5, %11111111, $CD, %11111111, $D5, %11001111, $DD, %11001111, $ED, %00000000, $F6, %11111111
frame106:
	.byte %01000011, $D5, %11111111, $DD, %11111111, $FE, %00000000
frame107:
	.byte %01000010, $E5, %00001100, $F6, %11001100
frame108:
	.byte %01000001, $EE, %11001100
frame109:
	.byte %01000100, $C5, %11111100, $CC, %11000000, $D4, %00001100, $E5, %00000000
frame110:
	.byte %01000101, $D5, %11001111, $DD, %11001111, $E6, %11001111, $F6, %00001100, $FF, %00001100
frame111:
	.byte %01000101, $C5, %11001100, $CC, %00000000, $DD, %00001100, $E6, %11001100, $EE, %00001100
frame112:
	.byte %01000011, $E6, %00001100, $EE, %00000000, $F6, %00000000
frame113:
	.byte %01000011, $C5, %11111100, $DE, %11001111, $F7, %11001111
frame114:
	.byte %01000110, $C5, %11000000, $D4, %00000000, $D5, %00000000, $DD, %00000000, $E6, %00000000, $FF, %00000000
frame115:
	.byte %01000001, $CD, %11111100
frame116:
	.byte %01000010, $DE, %00001100, $F7, %00001111
frame117:
	.byte %01000100, $CD, %11001100, $D0, %00110011, $E7, %11001111, $EF, %11111100
frame118:
	.byte %01000101, $C5, %00000000, $D0, %00110000, $D8, %00000011, $EF, %11001100, $F7, %00001100
frame119:
	.byte %01000010, $D0, %00000000, $D8, %00110011
frame120:
	.byte %01000010, $CD, %11000000, $D8, %00110000
frame121:
	.byte %01000101, $C0, %00110011, $CD, %00000000, $D0, %11000000, $D6, %11111100, $D8, %00000000
frame122:
	.byte %01000100, $C8, %00110011, $D0, %00110011, $D6, %11111111, $D8, %00110011
frame123:
	.byte %01000010, $C0, %00111111, $E0, %00110011
frame124:
	.byte %01000110, $C0, %11111111, $C8, %11111111, $D0, %00111111, $D2, %00001100, $D8, %00111111, $E7, %11111111
frame125:
	.byte %01000111, $C6, %11001100, $D0, %11111111, $D2, %11000000, $D8, %11111111, $DE, %00001111, $E0, %00111111, $E8, %00000011
frame126:
	.byte %01000100, $C1, %00110011, $CE, %11001100, $D6, %11001111, $E8, %00110011
frame127:
	.byte %01000111, $C1, %00110000, $C9, %00110011, $D1, %00000011, $D2, %00000000, $D9, %00000011, $DE, %11001111, $E0, %11111111
frame128:
	.byte %01000111, $C1, %00110011, $D1, %00110011, $D3, %00110000, $D6, %11001100, $D9, %00110011, $E8, %00111111, $F0, %00000011
frame129:
	.byte %01000100, $D3, %00000000, $DE, %11001100, $E1, %00000011, $F0, %00110011
frame130:
	.byte %01000111, $C1, %11110011, $C6, %11000000, $C9, %00111111, $D6, %11111100, $E1, %00110011, $E8, %11111111, $F8, %00000011
frame131:
	.byte %01000100, $C1, %00110011, $C9, %11111111, $D6, %11111111, $D9, %11110011
frame132:
	.byte %01000111, $C1, %11110011, $D1, %11111111, $D6, %11001100, $D9, %11111111, $E1, %00111111, $E9, %00000011, $F0, %00111111
frame133:
	.byte $88
frame134:
	.byte %01000100, $C1, %11111111, $D2, %00001100, $F0, %11111111, $F7, %00000000
frame135:
	.byte %01000100, $DE, %00001100, $E1, %11111111, $E9, %00110011, $F8, %00001111
frame136:
	.byte %01000011, $CA, %00000011, $D2, %11001100, $D6, %11000000
frame137:
	.byte %01000011, $D2, %11000000, $DA, %00110011, $F1, %00000011
frame138:
	.byte %01000111, $C2, %00110000, $CA, %00110011, $D2, %00000011, $D6, %11001100, $DA, %00111111, $DE, %00000000, $E9, %00111111
frame139:
	.byte %01000101, $D2, %00110011, $DE, %00001100, $E2, %00000011, $E7, %11001111, $F1, %00110011
frame140:
	.byte %01000100, $C2, %00110011, $E2, %00110011, $EF, %00001100, $F9, %00000011
frame141:
	.byte %01000010, $C6, %11001100, $DA, %00110011
frame142:
	.byte %01000101, $D3, %00000011, $DE, %00000000, $E7, %11001100, $E9, %11111111, $F1, %00111111
frame143:
	.byte $88
frame144:
	.byte %01000011, $C2, %11110011, $CB, %00110000, $F1, %11111111
frame145:
	.byte %01000011, $D3, %00110011, $DA, %00111111, $DF, %11001111
frame146:
	.byte %01000110, $C2, %11111111, $CA, %00111111, $CB, %00000000, $D2, %11110011, $DA, %11111111, $F9, %00001111
frame147:
	.byte %01000110, $C6, %11000000, $CA, %11111111, $D2, %11111111, $D3, %00110000, $E2, %00111111, $EA, %00110000
frame148:
	.byte $88
frame149:
	.byte %01000100, $D3, %00000000, $EA, %00110011, $EF, %00000000, $F2, %00000011
frame150:
	.byte %01000001, $F2, %00110011
frame151:
	.byte $88
frame152:
	.byte %01000100, $C6, %00000000, $CB, %00000011, $EF, %00001100, $F7, %00001100
frame153:
	.byte %01000011, $DF, %11111111, $F7, %11001100, $FE, %00000011
frame154:
	.byte %01000100, $CB, %00110011, $DE, %00001100, $E7, %11111111, $FF, %00001100
frame155:
	.byte %01000101, $C3, %00110000, $D3, %00000011, $DB, %00110011, $E2, %11111111, $EF, %11001111
frame156:
	.byte %01000011, $CB, %00110000, $D3, %00110011, $FE, %00000000
frame157:
	.byte %01000001, $DB, %00000011
frame158:
	.byte %01000100, $C3, %00000000, $C6, %11000000, $E2, %00111111, $F7, %11001111
frame159:
	.byte %01000011, $C6, %11001100, $DE, %11001100, $F7, %11111111
frame160:
	.byte %01000010, $EF, %11111111, $FF, %00001111
frame161:
	.byte %01000010, $E6, %11001100, $F5, %11000000
frame162:
	.byte %01000101, $CE, %11001111, $DB, %00000000, $F2, %00000011, $F5, %11001100, $FD, %00001100
frame163:
	.byte %01000011, $D6, %11111100, $DE, %11001111, $ED, %11000000
frame164:
	.byte %01000110, $C6, %11111100, $CE, %11111111, $E2, %00110011, $ED, %00000000, $EE, %11000000, $F5, %00000000
frame165:
	.byte %01000100, $C6, %11111111, $D6, %11111111, $DA, %00111111, $FD, %00000000
frame166:
	.byte %01001000, $D3, %00000011, $DE, %11111111, $E2, %00000011, $EE, %11001100, $F2, %00000000, $F5, %00110011, $F6, %00001100, $FD, %00000011
frame167:
	.byte %01000101, $C2, %00111111, $CB, %00000000, $DA, %00110011, $E6, %11001111, $F6, %11001100
frame168:
	.byte %01000011, $EA, %00000011, $ED, %00110000, $F9, %00000011
frame169:
	.byte %01000011, $CD, %00001100, $E5, %00110000, $ED, %00110011
frame170:
	.byte %01000100, $E5, %00000000, $EA, %00000000, $ED, %00110000, $FE, %00001100
frame171:
	.byte %01000010, $CD, %11001100, $D3, %00000000
frame172:
	.byte %01000110, $C2, %00110011, $D5, %00001100, $DD, %00001100, $ED, %00000000, $F5, %00000000, $FD, %00000000
frame173:
	.byte %01000101, $C2, %00111111, $C5, %11000000, $D5, %11001100, $E6, %11111111, $F1, %00111111
frame174:
	.byte $88
frame175:
	.byte %01000001, $EE, %11001111
frame176:
	.byte %01000001, $DD, %11001100
frame177:
	.byte %01000011, $EE, %11111111, $F1, %00110011, $F4, %11001100
frame178:
	.byte %01000010, $ED, %11000000, $FC, %00001100
frame179:
	.byte %01000101, $C2, %00110011, $CA, %11110011, $CD, %11111100, $ED, %00000000, $F6, %11111111
frame180:
	.byte %01000100, $D5, %11111111, $E5, %00001100, $EC, %11000000, $F5, %00001100
frame181:
	.byte %01000011, $DD, %11001111, $EC, %00000000, $F4, %00000000
frame182:
	.byte %01000110, $CA, %00110011, $D2, %00110011, $F5, %00000000, $F9, %00000000, $FC, %00000000, $FE, %00001111
frame183:
	.byte $88
frame184:
	.byte %01000011, $C5, %11001100, $D2, %11110011, $E5, %11001100
frame185:
	.byte %01000010, $CD, %11111111, $DD, %11111111
frame186:
	.byte %01000010, $D2, %00111111, $E9, %00111111
frame187:
	.byte %01000011, $D2, %00110011, $E2, %00000000, $ED, %00001100
frame188:
	.byte $88
frame189:
	.byte $88
frame190:
	.byte %01000001, $ED, %11001100
frame191:
	.byte %01000010, $C2, %00110000, $E5, %11001111
frame192:
	.byte %01000011, $C5, %11111100, $DA, %00000011, $F5, %00001100
frame193:
	.byte %01000001, $CC, %11000000
frame194:
	.byte %01000011, $D4, %00001100, $DC, %00001100, $F5, %11001100
frame195:
	.byte %01000100, $D4, %11001100, $E5, %11111111, $F1, %00000011, $FD, %00001100
frame196:
	.byte $88
frame197:
	.byte %01000011, $C5, %11111111, $CA, %00110000, $DA, %00000000
frame198:
	.byte %01000001, $E9, %00110011
frame199:
	.byte %01000010, $CC, %11001100, $ED, %11001111
frame200:
	.byte %01000001, $DC, %11001100
frame201:
	.byte %01000011, $E9, %00111111, $ED, %11111111, $F1, %00110011
frame202:
	.byte $88
frame203:
	.byte $88
frame204:
	.byte $88
frame205:
	.byte $88
frame206:
	.byte $88
frame207:
	.byte %01000100, $C2, %00000000, $DA, %00000011, $E9, %11111111, $F9, %00000011
frame208:
	.byte $88
frame209:
	.byte $88
frame210:
	.byte %01000001, $CA, %00110011
frame211:
	.byte $88
frame212:
	.byte %01000010, $DA, %00110011, $ED, %11001111
frame213:
	.byte $88
frame214:
	.byte %01000011, $C2, %00110000, $F1, %00111111, $F2, %11000000
frame215:
	.byte %01000010, $DC, %00001100, $F2, %00000000
frame216:
	.byte %01000100, $DC, %00000000, $E2, %00110000, $F9, %00001111, $FA, %00001100
frame217:
	.byte %01000010, $C2, %00110011, $EA, %00000011
frame218:
	.byte %01000011, $E2, %00110011, $ED, %11001100, $F1, %11111111
frame219:
	.byte %01000100, $CA, %00111111, $CC, %11000000, $EB, %00000011, $FA, %00000000
frame220:
	.byte %01000010, $E3, %00110000, $EB, %00110011
frame221:
	.byte %01000010, $CA, %11111111, $EA, %00110011
frame222:
	.byte %01000010, $E5, %11001111, $F3, %00000011
frame223:
	.byte %01000011, $D2, %00111111, $F2, %00110000, $F5, %11000000
frame224:
	.byte %01000101, $D2, %11111111, $E3, %00000000, $E5, %11001100, $EB, %00110000, $F2, %00110011
frame225:
	.byte %01000011, $EB, %00000000, $FA, %00000011, $FD, %00000000
frame226:
	.byte %01000010, $F3, %00000000, $F5, %00000000
frame227:
	.byte %01000010, $DA, %00111111, $E2, %11110011
frame228:
	.byte %01000011, $CC, %00000000, $EA, %00111111, $F3, %00110000
frame229:
	.byte %01000011, $D4, %11000000, $ED, %00001100, $F3, %00000000
frame230:
	.byte $88
frame231:
	.byte %01000001, $D4, %00000000
frame232:
	.byte %01000001, $EA, %11111111
frame233:
	.byte %01000101, $C2, %00111111, $C3, %00001100, $D3, %11000000, $DA, %11111111, $E2, %00110011
frame234:
	.byte %01000010, $D3, %00000000, $FA, %00001111
frame235:
	.byte %01000001, $D3, %00000011
frame236:
	.byte %01000001, $F2, %00111111
frame237:
	.byte %01000011, $C2, %11111111, $C5, %11001111, $EA, %11110011
frame238:
	.byte %01000010, $D3, %00110011, $EA, %00110011
frame239:
	.byte %01000011, $C4, %00000011, $DB, %00000011, $E2, %00111111
frame240:
	.byte %01000101, $C4, %00000000, $C5, %11001100, $DD, %11001111, $ED, %00000000, $F2, %11110011
frame241:
	.byte %01000001, $CB, %00110000
frame242:
	.byte %01000001, $C3, %00000000
frame243:
	.byte %01000001, $E2, %11111111
frame244:
	.byte $88
frame245:
	.byte %01000010, $DD, %11001100, $F2, %11111111
frame246:
	.byte $88
frame247:
	.byte %01000001, $EA, %00111111
frame248:
	.byte $88
frame249:
	.byte %01000001, $CB, %00110011
frame250:
	.byte %01000010, $CD, %11111100, $EA, %11111111
frame251:
	.byte $88
frame252:
	.byte %01000001, $FB, %00000011
frame253:
	.byte $88
frame254:
	.byte %01000010, $D3, %11110011, $E3, %00000011
frame255:
	.byte %01000011, $D3, %00110011, $DB, %00110011, $F2, %11110011
frame256:
	.byte %01000001, $C3, %00000011
frame257:
	.byte %01000001, $C4, %00000011
frame258:
	.byte %01000001, $C3, %00001111
frame259:
	.byte %01000001, $CD, %11001111
frame260:
	.byte %01000010, $C4, %00001111, $CD, %11001100
frame261:
	.byte %01000001, $FB, %00000000
frame262:
	.byte %01000010, $D3, %11110011, $ED, %00001100
frame263:
	.byte %01000010, $DB, %00000011, $E3, %00000000
frame264:
	.byte %01000010, $CD, %11111100, $D3, %11111111
frame265:
	.byte %01000001, $D3, %00110011
frame266:
	.byte %01000011, $DD, %11001111, $E4, %11000000, $EA, %00111111
frame267:
	.byte %01000010, $C5, %11001111, $EC, %00001100
frame268:
	.byte %01000111, $C3, %00000011, $C4, %00000011, $CB, %00110000, $CD, %11111111, $DD, %11111111, $E4, %11001100, $FD, %00000011
frame269:
	.byte %01000001, $EA, %00110011
frame270:
	.byte %01000010, $C3, %00000000, $DC, %11000000
frame271:
	.byte %01000100, $CB, %00110011, $EC, %11001100, $ED, %11001100, $F5, %00001100
frame272:
	.byte %01000011, $DB, %00000000, $DD, %11001111, $F5, %11001100
frame273:
	.byte %01000011, $C4, %00001111, $DC, %00000000, $FA, %00000011
frame274:
	.byte %01000011, $E4, %11000000, $F2, %00110011, $FD, %00001111
frame275:
	.byte %01000011, $E4, %00000000, $EC, %11000000, $F4, %00001100
frame276:
	.byte %01000001, $DD, %11111111
frame277:
	.byte %01000001, $EC, %00000000
frame278:
	.byte %01000010, $E2, %00111111, $FD, %00001100
frame279:
	.byte $88
frame280:
	.byte %01000010, $CB, %00000011, $E5, %11001111
frame281:
	.byte %01000010, $C3, %00001100, $F4, %00000000
frame282:
	.byte %01000011, $C5, %11111111, $CB, %00000000, $D4, %00001100
frame283:
	.byte %01000010, $D4, %11001100, $F4, %11000000
frame284:
	.byte $88
frame285:
	.byte $88
frame286:
	.byte %01000011, $C3, %00001111, $C4, %00111111, $D3, %00000000
frame287:
	.byte %01000101, $CC, %11000000, $D3, %00110000, $E5, %11111111, $F4, %00000000, $F5, %11111100
frame288:
	.byte %01000010, $DC, %00001100, $FD, %00001111
frame289:
	.byte %01000010, $C4, %00001111, $D3, %00000000
frame290:
	.byte %01000001, $E2, %00110011
frame291:
	.byte %01000010, $EA, %00000011, $ED, %11001111
frame292:
	.byte %01000010, $DA, %00111111, $ED, %11111111
frame293:
	.byte %01000011, $F2, %00000011, $F5, %11111111, $FA, %00000000
frame294:
	.byte $88
frame295:
	.byte $88
frame296:
	.byte %01000001, $F2, %00000000
frame297:
	.byte $88
frame298:
	.byte $88
frame299:
	.byte %01000001, $C3, %00001100
frame300:
	.byte $88
frame301:
	.byte %01000011, $C2, %00111111, $CC, %11001100, $DC, %11001100
frame302:
	.byte $88
frame303:
	.byte $88
frame304:
	.byte %01000001, $E4, %00001100
frame305:
	.byte %01000010, $C2, %00110011, $C3, %00001111
frame306:
	.byte %01000001, $EA, %00000000
frame307:
	.byte %01000010, $DA, %00110011, $EA, %00000011
frame308:
	.byte %01000010, $C4, %11001111, $CA, %00110011
frame309:
	.byte %01000010, $C2, %00111111, $D4, %11001111
frame310:
	.byte $88
frame311:
	.byte $88
frame312:
	.byte %01000001, $D4, %11111111
frame313:
	.byte %01000001, $DA, %00111111
frame314:
	.byte $88
frame315:
	.byte %01000011, $CA, %11110011, $DA, %11111111, $F2, %11000000
frame316:
	.byte %01000010, $EA, %00110011, $F2, %00000000
frame317:
	.byte %01000011, $C4, %00001111, $E3, %00110000, $F2, %00110000
frame318:
	.byte %01000111, $CA, %11111111, $D4, %11001100, $DA, %00111111, $DC, %00001100, $E3, %00110011, $EB, %00000011, $F2, %00110011
frame319:
	.byte %01000010, $E4, %00000000, $FA, %00001111
frame320:
	.byte $88
frame321:
	.byte $88
frame322:
	.byte %01000001, $E2, %00111111
frame323:
	.byte %01000011, $CC, %11000000, $E3, %00000000, $EB, %00110011
frame324:
	.byte %01000010, $C2, %11111111, $DA, %11111111
frame325:
	.byte %01000011, $E2, %00110011, $EB, %00110000, $FD, %00001100
frame326:
	.byte %01000010, $DC, %00000000, $ED, %11111100
frame327:
	.byte %01000001, $ED, %11001100
frame328:
	.byte %01000100, $CC, %00000000, $EB, %00000000, $F3, %00000011, $F5, %11111100
frame329:
	.byte $88
frame330:
	.byte $88
frame331:
	.byte $88
frame332:
	.byte %01000001, $F5, %11001100
frame333:
	.byte %01000011, $D3, %00000011, $E5, %11001111, $F3, %00000000
frame334:
	.byte %01000001, $FA, %00000011
frame335:
	.byte %01000010, $D3, %00110011, $FA, %00001111
frame336:
	.byte %01000011, $C3, %11001111, $EA, %11110011, $F3, %00110000
frame337:
	.byte %01000011, $CB, %00110000, $D3, %11110011, $E2, %00111111
frame338:
	.byte %01000011, $D3, %00110011, $D4, %11000000, $F2, %11111111
frame339:
	.byte %01000001, $DB, %00110000
frame340:
	.byte %01000001, $DB, %00000000
frame341:
	.byte %01000011, $C3, %00001111, $D4, %00000000, $DB, %00000011
frame342:
	.byte %01000010, $E2, %11111111, $F3, %00000000
frame343:
	.byte %01000010, $DD, %11001111, $E5, %11001100
frame344:
	.byte $88
frame345:
	.byte $88
frame346:
	.byte $88
frame347:
	.byte %01000001, $EA, %11111111
frame348:
	.byte %01000010, $ED, %00001100, $F5, %00001100
frame349:
	.byte %01000001, $FD, %00000000
frame350:
	.byte %01000001, $F5, %00000000
frame351:
	.byte %01000001, $C4, %00000011
frame352:
	.byte %01000010, $CB, %00110011, $DB, %00110011
frame353:
	.byte %01000001, $ED, %00000000
frame354:
	.byte %01000001, $C5, %11001111
frame355:
	.byte %01000001, $F3, %00110000
frame356:
	.byte %01000001, $C5, %11001100
frame357:
	.byte %01000001, $D3, %11110011
frame358:
	.byte %01000001, $D3, %00110011
frame359:
	.byte %01000001, $DD, %11001100
frame360:
	.byte %01000001, $C4, %00001111
frame361:
	.byte %01000010, $C3, %00111111, $CD, %11111100
frame362:
	.byte %01000010, $C5, %11001111, $CD, %11001100
frame363:
	.byte %01000010, $D3, %00111111, $ED, %00001100
frame364:
	.byte %01000001, $EA, %00111111
frame365:
	.byte %01000011, $CD, %11111100, $D3, %11111111, $DD, %11001111
frame366:
	.byte $88
frame367:
	.byte %01000100, $DD, %11111111, $ED, %11001100, $F3, %00000000, $F5, %00110000
frame368:
	.byte %01000011, $C3, %00001111, $DB, %00000011, $EA, %00110011
frame369:
	.byte %01000100, $CD, %11111111, $D3, %11110011, $E4, %11000000, $EC, %00001100
frame370:
	.byte %01000011, $DD, %11001111, $E4, %11001100, $F5, %00111100
frame371:
	.byte %01000001, $D3, %00110011
frame372:
	.byte %01000001, $FD, %00000011
frame373:
	.byte %01000011, $E5, %11001111, $F5, %11111100, $FD, %00001111
frame374:
	.byte %01000010, $CB, %00110000, $F5, %11001100
frame375:
	.byte %01000010, $E4, %00000000, $EC, %11001100
frame376:
	.byte %01000011, $C5, %11111111, $DD, %11111111, $EC, %11000000
frame377:
	.byte %01000010, $F2, %11110011, $FA, %00000011
frame378:
	.byte %01000001, $DB, %00000000
frame379:
	.byte %01000010, $E5, %11111111, $EC, %00000000
frame380:
	.byte %01000010, $F2, %00110011, $F4, %00001100
frame381:
	.byte $88
frame382:
	.byte %01000001, $CB, %00000000
frame383:
	.byte %01000001, $E2, %00111111
frame384:
	.byte $88
frame385:
	.byte %01000011, $D4, %00001100, $F4, %00000000, $FD, %00001100
frame386:
	.byte %01000010, $D4, %11001100, $FD, %00001111
frame387:
	.byte $88
frame388:
	.byte %01000011, $D4, %11111100, $ED, %11111100, $F4, %11000000
frame389:
	.byte %01000010, $C4, %00111111, $D4, %11001100
frame390:
	.byte %01000010, $CC, %11000000, $F5, %11111111
frame391:
	.byte %01000010, $D3, %00000000, $ED, %11001100
frame392:
	.byte %01000011, $D3, %00110000, $DC, %00001100, $F4, %00000000
frame393:
	.byte $88
frame394:
	.byte %01000001, $F5, %11111100
frame395:
	.byte $88
frame396:
	.byte $88
frame397:
	.byte %01000011, $C4, %00001111, $CC, %00000000, $E5, %11001111
frame398:
	.byte %01000001, $F5, %11001100
frame399:
	.byte %01000001, $FD, %00001100
frame400:
	.byte %01000011, $C5, %11001111, $D3, %00110011, $DC, %00000000
frame401:
	.byte %01000011, $C3, %00001100, $D4, %00001100, $E2, %11111111
frame402:
	.byte %01000001, $D4, %00000000
frame403:
	.byte $88
frame404:
	.byte %01000100, $CD, %11111100, $E5, %11001100, $EC, %11000000, $F5, %00000000
frame405:
	.byte %01000010, $C3, %00000000, $EC, %00001100
frame406:
	.byte %01000101, $DB, %00000011, $EA, %00111111, $EC, %00000000, $ED, %00001100, $FD, %00000000
frame407:
	.byte $88
frame408:
	.byte $88
frame409:
	.byte %01000011, $ED, %00000000, $F6, %11001111, $FE, %00001100
frame410:
	.byte %01000100, $C5, %11001100, $DD, %11001111, $EA, %11111111, $FD, %00000011
frame411:
	.byte %01000100, $C5, %00001100, $D5, %11111100, $F5, %00110011, $F6, %11001100
frame412:
	.byte %01000101, $CD, %11001100, $D5, %11001100, $E5, %00001100, $ED, %00110000, $FD, %00000000
frame413:
	.byte %01000010, $CD, %11000000, $F2, %00111111
frame414:
	.byte %01000110, $C5, %00001111, $DB, %00110011, $DD, %11001100, $EE, %11001111, $F5, %00000011, $FE, %00000000
frame415:
	.byte %01000011, $CB, %00110000, $CD, %00000000, $F2, %11111111
frame416:
	.byte %01000001, $ED, %00000000
frame417:
	.byte %01000100, $F5, %11000000, $F6, %00001100, $FA, %00001111, $FD, %00001100
frame418:
	.byte %01000001, $E3, %00110000
frame419:
	.byte %01000110, $C5, %00000011, $D5, %11000000, $EB, %00110000, $EE, %11001100, $F3, %00000011, $F6, %00000000
frame420:
	.byte %01000001, $C5, %00000000
frame421:
	.byte %01000110, $C6, %11001111, $CD, %11000000, $CE, %11111100, $E3, %00110011, $EB, %00110011, $F3, %00110011
frame422:
	.byte %01000110, $C4, %00001100, $CD, %00000000, $CE, %11001100, $D5, %00000000, $F5, %11001100, $FF, %00001100
frame423:
	.byte %01000111, $C3, %00000011, $C6, %11001100, $CB, %00110011, $DD, %11000000, $E5, %00000000, $EE, %00001100, $F7, %11001111
frame424:
	.byte %01000011, $D6, %11111100, $DB, %00111111, $ED, %11000000
frame425:
	.byte %01000111, $C5, %00000011, $CE, %11111100, $DB, %11111111, $DD, %00000000, $ED, %00000000, $FB, %00000011, $FD, %00000000
frame426:
	.byte %01000101, $C3, %00110011, $C5, %00000000, $DB, %11110011, $F5, %11000000, $F7, %11001100
frame427:
	.byte %01000101, $C4, %00000000, $CE, %11001100, $E3, %00111111, $E6, %11001111, $F5, %00000000
frame428:
	.byte %01001010, $C6, %00001100, $CE, %00000000, $D3, %11110011, $D6, %11001100, $DB, %00110011, $DE, %11111100, $E3, %11111111, $EB, %00111111, $F3, %11111111, $FF, %00000000
frame429:
	.byte %01000101, $C6, %00000000, $D6, %11000000, $DE, %11001100, $E3, %11110011, $FE, %00001100
frame430:
	.byte %01001000, $C3, %00111111, $CB, %00111111, $CE, %11000000, $D3, %11111111, $DB, %11111111, $E3, %11111111, $E6, %11001100, $EB, %11111111
frame431:
	.byte %01000011, $C3, %11111111, $D6, %00000000, $DC, %00110011
frame432:
	.byte %01000011, $C5, %00000011, $DC, %00000000, $FE, %00000011
frame433:
	.byte %01000011, $CB, %11111111, $CE, %00000000, $DE, %11000000
frame434:
	.byte %01000110, $C4, %00000011, $C5, %00000000, $DC, %11000000, $DE, %00000000, $E6, %11000000, $EF, %11001111
frame435:
	.byte %01000100, $D4, %00110000, $E4, %00000011, $EF, %11111111, $F6, %00110000
frame436:
	.byte %01000111, $C4, %00110011, $D7, %11001111, $DC, %11110011, $E4, %00110011, $E6, %00000000, $FA, %00000000, $FB, %00000000
frame437:
	.byte %01000011, $C4, %00111111, $C5, %00001100, $F6, %00000000
frame438:
	.byte %01000101, $C5, %00001111, $DC, %00110011, $EC, %00000011, $F2, %00001111, $FF, %00001100
frame439:
	.byte %01000100, $C6, %00001100, $D7, %11111111, $EE, %11001100, $FE, %00000000
frame440:
	.byte %01000100, $DF, %11001111, $EE, %11000000, $F2, %00000000, $F3, %00111111
frame441:
	.byte %01001000, $C6, %11001100, $CC, %00000011, $DF, %11001100, $E7, %11111100, $EC, %00110011, $F2, %00000011, $F4, %00000011, $F7, %11111100
frame442:
	.byte %01000101, $C4, %11111111, $C5, %00000011, $E7, %11001100, $F2, %00000000, $F3, %00001111
frame443:
	.byte %01000010, $E4, %00111111, $F6, %00001100
frame444:
	.byte %01001000, $C6, %11001111, $DF, %11001111, $EA, %00111111, $EE, %00000000, $EF, %11111100, $F7, %11111111, $FA, %00000011, $FF, %00001111
frame445:
	.byte %01000001, $FA, %00001111
frame446:
	.byte %01000011, $C5, %00110011, $CE, %00001100, $EE, %11000000
frame447:
	.byte %01000110, $C6, %11111111, $CC, %00110011, $DF, %11111111, $EA, %00001111, $EF, %11111111, $F2, %00110000
frame448:
	.byte %01000010, $E4, %11111111, $F3, %00001100
frame449:
	.byte %01000011, $F3, %00000000, $F4, %00000000, $F6, %11001100
frame450:
	.byte %01000010, $CE, %11001100, $E7, %11001111
frame451:
	.byte %01000010, $C5, %00001111, $F2, %11110000
frame452:
	.byte %01000010, $EA, %00000011, $EE, %11001100
frame453:
	.byte %01000010, $E7, %11111111, $F2, %11110011
frame454:
	.byte $88
frame455:
	.byte $88
frame456:
	.byte %01000001, $E6, %00001100
frame457:
	.byte %01000001, $EA, %00000000
frame458:
	.byte %01000010, $D4, %00000000, $E6, %00000000
frame459:
	.byte %01000001, $E6, %11000000
frame460:
	.byte %01000001, $EB, %11001111
frame461:
	.byte %01000010, $C5, %11001111, $D6, %00001100
frame462:
	.byte %01000010, $CC, %00000011, $FA, %00000011
frame463:
	.byte %01000001, $FE, %00001100
frame464:
	.byte %01000001, $F2, %11111111
frame465:
	.byte %01000001, $E6, %00000000
frame466:
	.byte %01000010, $E6, %11000000, $EB, %00001111
frame467:
	.byte %01000001, $EC, %00000011
frame468:
	.byte %01000011, $D6, %11001100, $E2, %00111111, $F2, %00111111
frame469:
	.byte %01000001, $EA, %00110000
frame470:
	.byte %01000001, $E4, %11110011
frame471:
	.byte %01000010, $C4, %00111111, $DE, %00001100
frame472:
	.byte %01000010, $DE, %11001100, $E6, %00000000
frame473:
	.byte %01000001, $E6, %00001100
frame474:
	.byte %01000001, $E6, %11001100
frame475:
	.byte %01000001, $E4, %00110011
frame476:
	.byte %01000001, $CE, %11001111
frame477:
	.byte $88
frame478:
	.byte %01000001, $E6, %11111100
frame479:
	.byte $88
frame480:
	.byte %01000001, $C5, %11111111
frame481:
	.byte $88
frame482:
	.byte $88
frame483:
	.byte %01000001, $F2, %11111111
frame484:
	.byte $88
frame485:
	.byte $88
frame486:
	.byte $88
frame487:
	.byte $88
frame488:
	.byte %01000001, $EE, %11111100
frame489:
	.byte $88
frame490:
	.byte $88
frame491:
	.byte $88
frame492:
	.byte $88
frame493:
	.byte %01000001, $FA, %00001111
frame494:
	.byte $88
frame495:
	.byte $88
frame496:
	.byte $88
frame497:
	.byte $88
frame498:
	.byte %01000001, $E6, %11001100
frame499:
	.byte %01000001, $C5, %11001111
frame500:
	.byte $88
frame501:
	.byte $88
frame502:
	.byte $88
frame503:
	.byte %01000001, $CE, %11001100
frame504:
	.byte $88
frame505:
	.byte $88
frame506:
	.byte $88
frame507:
	.byte %01000011, $E6, %11000000, $EA, %00110011, $EE, %11111111
frame508:
	.byte %01000010, $DE, %00001100, $EB, %00001100
frame509:
	.byte %01000010, $EC, %00110011, $F6, %00001100
frame510:
	.byte %01000001, $DE, %00000000
frame511:
	.byte %01000010, $C5, %00001111, $EE, %11001111
frame512:
	.byte %01000001, $E3, %11001111
frame513:
	.byte $88
frame514:
	.byte $88
frame515:
	.byte $88
frame516:
	.byte %01000010, $C4, %00110011, $D6, %00001100
frame517:
	.byte $88
frame518:
	.byte %01000001, $EE, %11001100
frame519:
	.byte $88
frame520:
	.byte $88
frame521:
	.byte %01000001, $E6, %00000000
frame522:
	.byte $88
frame523:
	.byte $88
frame524:
	.byte %01000010, $C5, %00001100, $D6, %00000000
frame525:
	.byte %01000001, $F6, %11001100
frame526:
	.byte %01000001, $C6, %11001111
frame527:
	.byte $88
frame528:
	.byte %01000001, $FE, %00000000
frame529:
	.byte %01000010, $CC, %00000000, $EA, %11110011
frame530:
	.byte %01000001, $EC, %00000011
frame531:
	.byte $88
frame532:
	.byte %01000001, $E3, %11001100
frame533:
	.byte %01000100, $C4, %11110011, $CE, %00001100, $EE, %11000000, $F7, %11001111
frame534:
	.byte %01000011, $E6, %11000000, $EB, %00000000, $EE, %11001100
frame535:
	.byte %01000001, $F7, %11111111
frame536:
	.byte $88
frame537:
	.byte $88
frame538:
	.byte $88
frame539:
	.byte %01000010, $E3, %00001100, $E6, %00000000
frame540:
	.byte $88
frame541:
	.byte %01000001, $EE, %00001100
frame542:
	.byte %01000010, $C4, %00110011, $CE, %00000000
frame543:
	.byte %01000010, $C4, %00111111, $F6, %00001100
frame544:
	.byte %01000100, $C5, %00000000, $E3, %00000000, $EC, %00001111, $EE, %00000000
frame545:
	.byte %01000010, $D3, %11110011, $E7, %11001111
frame546:
	.byte %01000011, $E7, %11001100, $EA, %11111111, $EE, %11000000
frame547:
	.byte $88
frame548:
	.byte %01000011, $DF, %11001111, $EB, %00110000, $FF, %00001100
frame549:
	.byte %01000001, $DF, %11001100
frame550:
	.byte $88
frame551:
	.byte %01000001, $D3, %11111111
frame552:
	.byte %01000001, $D7, %11001111
frame553:
	.byte %01000011, $C6, %00001111, $E2, %11111111, $F6, %00000000
frame554:
	.byte $88
frame555:
	.byte %01000001, $DC, %00110000
frame556:
	.byte %01000001, $EF, %11111100
frame557:
	.byte $88
frame558:
	.byte %01000001, $EC, %00001100
frame559:
	.byte %01000001, $D7, %11001100
frame560:
	.byte $88
frame561:
	.byte $88
frame562:
	.byte $88
frame563:
	.byte %01000001, $F3, %00000011
frame564:
	.byte $88
frame565:
	.byte $88
frame566:
	.byte $88
frame567:
	.byte %01000001, $F3, %00110011
frame568:
	.byte $88
frame569:
	.byte %01000001, $DB, %00111111
frame570:
	.byte $88
frame571:
	.byte $88
frame572:
	.byte %01000001, $E4, %00110000
frame573:
	.byte $88
frame574:
	.byte $88
frame575:
	.byte %01000001, $E4, %00000000
frame576:
	.byte $88
frame577:
	.byte $88
frame578:
	.byte $88
frame579:
	.byte $88
frame580:
	.byte $88
frame581:
	.byte $88
frame582:
	.byte $88
frame583:
	.byte %01000001, $F3, %00000011
frame584:
	.byte $88
frame585:
	.byte $88
frame586:
	.byte $88
frame587:
	.byte $88
frame588:
	.byte $88
frame589:
	.byte $88
frame590:
	.byte $88
frame591:
	.byte $88
frame592:
	.byte %01000001, $E4, %00110000
frame593:
	.byte $88
frame594:
	.byte $88
frame595:
	.byte %01000010, $E4, %00110011, $FC, %00000011
frame596:
	.byte $88
frame597:
	.byte $88
frame598:
	.byte $88
frame599:
	.byte $88
frame600:
	.byte $88
frame601:
	.byte %01000001, $EE, %00000000
frame602:
	.byte $88
frame603:
	.byte $88
frame604:
	.byte $88
frame605:
	.byte $88
frame606:
	.byte %01000010, $D3, %11110011, $D7, %11001111
frame607:
	.byte $88
frame608:
	.byte $88
frame609:
	.byte %01000001, $DB, %11111111
frame610:
	.byte $88
frame611:
	.byte %01000010, $F3, %00000000, $FF, %00001111
frame612:
	.byte $88
frame613:
	.byte %01000001, $EE, %11000000
frame614:
	.byte $88
frame615:
	.byte %01000001, $EC, %00000000
frame616:
	.byte %01000001, $FF, %00000011
frame617:
	.byte $88
frame618:
	.byte %01000001, $C6, %11001111
frame619:
	.byte %01000010, $CB, %00111111, $DC, %00000000
frame620:
	.byte $88
frame621:
	.byte %01000001, $EF, %11111111
frame622:
	.byte %01000010, $C4, %00110011, $D3, %00110011
frame623:
	.byte %01000011, $D7, %11111111, $EC, %00000011, $FF, %00001111
frame624:
	.byte $88
frame625:
	.byte %01000001, $D3, %11110011
frame626:
	.byte %01000010, $D3, %00110011, $E2, %00111111
frame627:
	.byte $88
frame628:
	.byte %01000001, $DF, %11001111
frame629:
	.byte %01000100, $C5, %00001100, $CE, %00001100, $EB, %00000000, $F6, %00001100
frame630:
	.byte %01000010, $DF, %11111111, $EE, %00000000
frame631:
	.byte %01000001, $C5, %00000000
frame632:
	.byte %01000010, $E7, %11001111, $FF, %00001100
frame633:
	.byte %01000001, $EA, %11110011
frame634:
	.byte %01000011, $C4, %00000011, $E7, %11111111, $EE, %00001100
frame635:
	.byte %01000010, $CB, %00110011, $FC, %00000000
frame636:
	.byte %01000011, $C4, %00000000, $E6, %11000000, $F6, %11001100
frame637:
	.byte $88
frame638:
	.byte %01000010, $EE, %11001100, $EF, %11111100
frame639:
	.byte %01000010, $CE, %11001100, $EF, %11111111
frame640:
	.byte %01000011, $E3, %00001100, $E6, %00000000, $EE, %11000000
frame641:
	.byte %01000001, $E4, %11110011
frame642:
	.byte %01000001, $EA, %00110011
frame643:
	.byte %01000001, $E3, %11001100
frame644:
	.byte $88
frame645:
	.byte %01000011, $E3, %11001111, $EB, %00001100, $FE, %00001100
frame646:
	.byte %01000010, $E4, %11000011, $FF, %00001111
frame647:
	.byte $88
frame648:
	.byte %01000010, $EC, %00111111, $EE, %11001100
frame649:
	.byte %01000001, $F2, %11110011
frame650:
	.byte $88
frame651:
	.byte %01000010, $E4, %11000000, $F4, %00000011
frame652:
	.byte %01000011, $C3, %11110011, $E4, %00000000, $EB, %11001100
frame653:
	.byte %01000010, $E2, %11111111, $E3, %11111111
frame654:
	.byte %01000001, $EA, %00000011
frame655:
	.byte %01000010, $DB, %11110011, $E4, %11000000
frame656:
	.byte %01000010, $C3, %00110011, $DB, %11111111
frame657:
	.byte %01000010, $E4, %00000000, $F2, %00110000
frame658:
	.byte %01000011, $EB, %11001111, $EC, %00110011, $F3, %00001100
frame659:
	.byte %01000111, $C6, %11111111, $DB, %11110011, $E6, %11000000, $EB, %11111111, $EE, %00001100, $F2, %00000000, $F4, %00110011
frame660:
	.byte %01000100, $C3, %00110000, $D3, %00000000, $EA, %00001111, $F3, %00001111
frame661:
	.byte %01000010, $FA, %00000000, $FE, %00000000
frame662:
	.byte %01000101, $C3, %00000000, $CB, %00000011, $F1, %00110011, $F3, %11001111, $F6, %00001100
frame663:
	.byte %01000101, $D6, %00001100, $DE, %11000000, $EA, %11111111, $F3, %11111111, $F9, %00000011
frame664:
	.byte %01000100, $E6, %00000000, $EC, %00110000, $F2, %00001100, $F6, %00000000
frame665:
	.byte %01000011, $C2, %11110011, $F1, %00111111, $F2, %11001100
frame666:
	.byte %01001000, $C5, %00001100, $D6, %11001100, $DB, %11110000, $DE, %00000000, $F2, %11001111, $FB, %00001111, $FC, %00000011, $FE, %00001100
frame667:
	.byte %01000010, $F6, %11000000, $FA, %00001100
frame668:
	.byte %01001000, $C2, %00110011, $CB, %00000000, $CE, %11001111, $E6, %11001100, $EC, %00000000, $F1, %11111111, $FE, %00000000, $FF, %00001100
frame669:
	.byte %01000101, $E6, %00001100, $EE, %00000000, $F2, %11111111, $F6, %00001100, $F7, %11001111
frame670:
	.byte %01000001, $DE, %11001100
frame671:
	.byte %01000011, $C3, %00001100, $F6, %00000000, $F9, %00001111
frame672:
	.byte %01000100, $CA, %11110011, $DB, %00110000, $F4, %00110000, $FA, %00001111
frame673:
	.byte %01000100, $DE, %00001100, $E4, %00110000, $EC, %00110011, $F4, %00110011
frame674:
	.byte %01000110, $C2, %00111111, $C3, %00001111, $C4, %00000011, $E6, %00000000, $EC, %11110011, $FF, %00001111
frame675:
	.byte %01000001, $EC, %11111111
frame676:
	.byte %01000101, $E6, %11000000, $EB, %11110011, $EC, %00111111, $EE, %00001100, $FF, %00001100
frame677:
	.byte %01000100, $DB, %00000000, $EB, %00110011, $EC, %11111111, $EE, %00000000
frame678:
	.byte %01000101, $C2, %11111111, $C4, %00001111, $C5, %00001111, $E6, %00000000, $F4, %00111111
frame679:
	.byte %01000100, $DB, %00110000, $EB, %00111111, $F4, %11111111, $FC, %00001111
frame680:
	.byte %01000110, $C4, %00111111, $CA, %11111111, $D3, %00000011, $DB, %00000000, $DE, %00000000, $F7, %11001100
frame681:
	.byte %01000110, $C3, %00111111, $D3, %00110011, $DB, %00110011, $E4, %00000000, $EC, %11111100, $ED, %00110000
frame682:
	.byte %01000110, $C3, %11111111, $C4, %11111111, $CE, %11001100, $D6, %00001100, $EB, %11111111, $FF, %00000000
frame683:
	.byte %01000101, $CB, %00110000, $EC, %11000000, $ED, %00110011, $EF, %11001111, $F5, %00000011
frame684:
	.byte %01000100, $C5, %00111111, $CB, %00110011, $D6, %00000000, $F5, %00110011
frame685:
	.byte %01000101, $C5, %11111111, $D3, %00111111, $E4, %00110000, $F4, %11111100, $F7, %00001100
frame686:
	.byte %01000111, $CB, %11111111, $CE, %00001100, $D3, %11111111, $E7, %11001111, $ED, %00110000, $EF, %11001100, $FD, %00000011
frame687:
	.byte %01000100, $DB, %00111111, $DF, %11001100, $E7, %11001100, $EC, %00000011
frame688:
	.byte %01001000, $CC, %00110011, $CE, %00000000, $D7, %11001111, $DB, %11111111, $EC, %00110011, $F4, %11001100, $F5, %00111111, $F7, %00000000
frame689:
	.byte %01000100, $D4, %00000011, $D7, %11001100, $E4, %00110011, $F4, %11000011
frame690:
	.byte %01000100, $CC, %11111111, $CF, %11001111, $ED, %11110000, $F4, %11110011
frame691:
	.byte %01000100, $D4, %00110011, $DF, %00000000, $E7, %11000000, $EC, %00111111
frame692:
	.byte %01001010, $CE, %00001100, $D7, %00001100, $DC, %00110011, $E4, %11111111, $E7, %00000000, $EC, %11111111, $ED, %11000000, $EF, %00000000, $F5, %11111111, $FD, %00001111
frame693:
	.byte %01000110, $CD, %00000011, $CE, %00000000, $CF, %11001100, $D7, %00000000, $ED, %11001100, $F4, %00111111
frame694:
	.byte %01000101, $C6, %11001111, $CF, %00001100, $D4, %00111111, $F4, %11111111, $F5, %11111100
frame695:
	.byte %01000110, $C6, %00001111, $CD, %00001111, $CF, %00000000, $DC, %11110011, $E5, %00110000, $ED, %11000000
frame696:
	.byte %01000110, $D4, %11111111, $DC, %11111111, $DD, %00110000, $E5, %00110011, $ED, %00110011, $F5, %11111111
frame697:
	.byte %01000100, $C6, %00110011, $C7, %11001111, $CD, %00111111, $EE, %00000011
frame698:
	.byte %01000111, $C6, %00111111, $C7, %00001100, $CD, %00110011, $DD, %00110011, $ED, %11110011, $EE, %00110000, $F6, %00110011
frame699:
	.byte %01000111, $C6, %11111111, $C7, %00000000, $CD, %00111111, $D5, %00110000, $E5, %00111111, $EE, %00110011, $FE, %00000011
frame700:
	.byte %01000110, $C6, %00111111, $D5, %00110011, $DD, %11111111, $E5, %11111111, $E6, %00110000, $ED, %11111111
frame701:
	.byte %01000010, $C7, %00000011, $E6, %00000000
frame702:
	.byte %01000010, $CD, %11111111, $D5, %11110011
frame703:
	.byte %01000011, $C7, %00001111, $D5, %11111111, $E6, %00111100
frame704:
	.byte %01000100, $D6, %00110000, $DE, %00110000, $E6, %00111111, $F6, %00000011
frame705:
	.byte %01000101, $C6, %11111111, $CE, %00000011, $DE, %00110011, $E6, %00110011, $FE, %00000000
frame706:
	.byte %01000100, $CE, %00110011, $D6, %00110011, $F6, %00000000, $FD, %00000011
frame707:
	.byte %01000100, $DE, %11110011, $EE, %00000011, $F5, %00110011, $FD, %00000000
frame708:
	.byte %01001001, $CE, %00111111, $D6, %11111111, $DE, %11111111, $E6, %00111111, $ED, %00111111, $F4, %00111111, $F5, %00000000, $FC, %00000000, $FE, %00000011
frame709:
	.byte %01000110, $CE, %11111111, $ED, %00001111, $EE, %00000000, $F4, %00000011, $FB, %00000011, $FE, %00000000
frame710:
	.byte %01001100, $C7, %00111111, $E6, %00001111, $EC, %00001111, $ED, %00000000, $F1, %00110011, $F2, %00001111, $F3, %00000000, $F4, %00000000, $F5, %00001100, $F9, %00000011, $FA, %00000000, $FB, %00000000
frame711:
	.byte %01001010, $E5, %00001111, $E6, %00000011, $E9, %00000011, $EA, %00001100, $EB, %00000000, $EC, %00000000, $F1, %11111111, $F2, %00000000, $F5, %11001100, $F9, %00001111
frame712:
	.byte %01001101, $D9, %00111111, $DF, %00110000, $E1, %00000000, $E2, %00001100, $E3, %00001100, $E4, %00001111, $E5, %00000011, $E9, %11110000, $EA, %00110000, $ED, %11000000, $F2, %00110011, $FA, %00000011, $FD, %00001100
frame713:
	.byte %01010010, $D1, %00000000, $D2, %11001100, $D9, %00110000, $DA, %00000000, $DB, %00001100, $DF, %00000000, $E1, %11111111, $E2, %00110011, $E3, %00000000, $E4, %00000000, $E5, %00000000, $E6, %00000000, $E9, %11111111, $EA, %00110011, $ED, %11110011, $F2, %00000011, $F5, %00001100, $FD, %00000000
frame714:
	.byte %11111111, %00111111, %11001111, %11111111, %11111111, %11111111, %11111111, %00111111
	.byte %11111111, %00110011, %11001100, %11111111, %11111111, %11111111, %11111111, %00000000
	.byte %11111111, %11110011, %00000000, %00001100, %11111111, %11111111, %00111111, %00000000
	.byte %11111111, %11111111, %00110011, %00000000, %00001100, %00001111, %11110011, %00000000
	.byte %11111111, %11111111, %00000000, %00000000, %00000000, %00110000, %00000000, %00000000
	.byte %11111111, %00111111, %00000000, %00000000, %00000000, %11111111, %00000000, %00000000
	.byte %11111111, %11110011, %00110000, %00000000, %00000000, %00110011, %00000000, %00000000
	.byte %00001111, %00001111, %00001111, %00001111, %00001111, %00000011, %00000000, %00000000

frame715:
	.byte %01010101, $C1, %00110011, $C2, %00000000, $C9, %11110011, $CA, %11110000, $CB, %00000000, $D1, %11111111, $D2, %00111111, $D3, %00000000, $D4, %00001100, $DA, %00000000, $DC, %00000000, $DD, %00001100, $DE, %11000011, $E1, %00110011, $E5, %11110000, $E9, %11110011, $EA, %00110000, $F1, %11111111, $F2, %11111111, $F3, %11110000, $F4, %11110000
frame716:
	.byte %11111111, %11111111, %11110000, %00110000, %11001111, %11111111, %11111111, %11111111
	.byte %11111111, %11111111, %11111111, %00000000, %00000000, %11111111, %11111111, %00000011
	.byte %11111111, %11111111, %00000011, %00000000, %00000000, %11001111, %11111111, %00000000
	.byte %11111111, %00110011, %00000000, %00000000, %00000000, %00000000, %11000000, %00000000
	.byte %11111111, %11110011, %00000000, %00000000, %00000000, %11110011, %00000000, %00000000
	.byte %11111111, %11111111, %11110011, %00110000, %11001100, %11111111, %00000000, %00000000
	.byte %11111111, %11111111, %11111111, %11111111, %11111111, %00110011, %00000000, %00000000
	.byte %00001111, %00001111, %00001111, %00001111, %00001111, %00000011, %00000000, %00000000

frame717:
	.byte %01010001, $C2, %11111111, $C3, %11111111, $C4, %00001100, $CB, %00000011, $CD, %11001111, $CF, %00111111, $D1, %00110011, $D2, %00000000, $D5, %11001100, $D9, %11110011, $DE, %00001111, $E1, %11111111, $E2, %00110011, $EA, %11111111, $EB, %11110000, $EC, %11111100, $F5, %11111111
frame718:
	.byte %01001110, $C4, %00110000, $C9, %00111111, $CA, %00001111, $CB, %00001111, $CD, %11001100, $CF, %11111111, $D1, %11110011, $D7, %00000011, $D9, %11111111, $DA, %00110000, $DE, %11001111, $E5, %00110000, $EE, %00110011, $FD, %00001111
frame719:
	.byte %01010010, $C4, %00110011, $C5, %11001100, $C9, %11111111, $CB, %11111111, $CC, %00110011, $D1, %11111111, $D2, %00110011, $D7, %11111111, $DA, %00110011, $DE, %11111111, $DF, %00110011, $E5, %00000000, $E6, %00001111, $EB, %00110000, $EC, %11110000, $ED, %11110000, $EE, %00000000, $F6, %00110011
frame720:
	.byte %01010110, $C4, %11111111, $C5, %11001111, $CA, %11111111, $CB, %11001111, $CC, %11111111, $CD, %00000000, $D2, %11111111, $D3, %00001100, $D4, %11001111, $D5, %00000000, $DA, %11111111, $DF, %00111111, $E2, %11111111, $E6, %11111111, $E7, %00110011, $EB, %00000000, $EC, %00000000, $ED, %00000000, $F3, %11110011, $F4, %11110000, $F6, %00110000, $FE, %00000011
frame721:
	.byte %01010101, $C5, %11111111, $CB, %11111111, $CD, %00110011, $D3, %00110011, $D4, %11111111, $D5, %00110011, $DB, %00110011, $DC, %00001100, $DD, %00000011, $DF, %11111111, $E3, %00000011, $E7, %00111111, $EE, %11001111, $EF, %00110011, $F3, %00110000, $F4, %00000000, $F5, %00000000, $F6, %00000000, $F7, %00000011, $FD, %00000011, $FE, %00000000
frame722:
	.byte %01010101, $CD, %11111111, $D3, %11111111, $D4, %11001111, $D5, %11111111, $D6, %11001111, $DB, %11111111, $DC, %11001100, $DD, %00110011, $DE, %11001100, $E3, %00111111, $E5, %00000011, $E7, %11111111, $EB, %00110011, $EE, %11001100, $EF, %00111111, $F3, %00110011, $F6, %00001100, $F7, %00110011, $FB, %00000011, $FC, %00000000, $FD, %00000000
frame723:
	.byte %01010000, $D4, %11111111, $D6, %11111111, $DC, %11111111, $DD, %11111111, $DE, %11001111, $E3, %11111111, $E4, %00110011, $E5, %00111111, $E6, %11001100, $EB, %11111111, $EF, %11111111, $F3, %00111111, $F6, %11001100, $F7, %11111111, $FE, %00001100, $FF, %00001111
frame724:
	.byte %01001001, $DE, %11111111, $E4, %11111111, $E5, %11111111, $E6, %11001111, $EC, %11111111, $ED, %00001100, $F3, %11111111, $F4, %00000011, $FB, %00001111
frame725:
	.byte %01000111, $E6, %11111111, $ED, %11111111, $EE, %00111111, $F4, %11111111, $F5, %00000011, $F6, %11000000, $FC, %00001111
frame726:
	.byte %01000101, $EE, %11111111, $F5, %11111111, $F6, %00001111, $FD, %00001111, $FE, %00000000
frame727:
	.byte %01000010, $F6, %11111111, $FE, %00001111
frame728:
	.byte $88
frame729:
	.byte $88
frame730:
	.byte $88
frame731:
	.byte %01000001, $C3, %11111100
frame732:
	.byte %01000001, $C3, %11110000
frame733:
	.byte $88
frame734:
	.byte %01000001, $C3, %00000000
frame735:
	.byte %01000001, $C4, %11111100
frame736:
	.byte $88
frame737:
	.byte %01000010, $C4, %11001100, $CB, %11110011
frame738:
	.byte $88
frame739:
	.byte %01000010, $CB, %11110000, $CC, %11111100
frame740:
	.byte %01000001, $CB, %00110000
frame741:
	.byte %01000010, $C4, %11001111, $CC, %11001100
frame742:
	.byte %01000010, $C3, %00000011, $CB, %00000000
frame743:
	.byte %01000011, $C3, %00001111, $D3, %11110011, $D4, %11111100
frame744:
	.byte %01000001, $C3, %00111111
frame745:
	.byte %01000001, $D3, %11110000
frame746:
	.byte %01000101, $C3, %11111111, $C4, %11111111, $CC, %00001100, $D3, %00110000, $D4, %11001100
frame747:
	.byte %01000010, $CB, %00000011, $D4, %11000000
frame748:
	.byte %01000001, $D3, %00000000
frame749:
	.byte %01000100, $CB, %00110011, $D4, %00000000, $DB, %11110011, $DC, %11111100
frame750:
	.byte %01000010, $CB, %00111111, $CC, %00001111
frame751:
	.byte %01000001, $CC, %11001111
frame752:
	.byte %01000010, $DB, %00110011, $DC, %11000000
frame753:
	.byte %01000001, $D3, %00000011
frame754:
	.byte %01000100, $CB, %11111111, $CC, %11111111, $DB, %00110000, $DC, %00000000
frame755:
	.byte %01000001, $E4, %11111100
frame756:
	.byte %01000011, $D3, %00110011, $D4, %00001100, $E3, %11110011
frame757:
	.byte %01000011, $D3, %00111111, $DB, %00110011, $E4, %11110000
frame758:
	.byte %01000001, $D4, %00001111
frame759:
	.byte %01000001, $E4, %11000000
frame760:
	.byte %01000011, $D3, %11111111, $D4, %11001111, $E4, %00000000
frame761:
	.byte %01000001, $E3, %00110011
frame762:
	.byte %01000001, $DD, %11001111
frame763:
	.byte %01000011, $D4, %11111111, $DD, %11111111, $E5, %11111100
frame764:
	.byte %01000010, $E3, %00110000, $EC, %11111100
frame765:
	.byte %01000010, $E3, %00110011, $EC, %11110000
frame766:
	.byte %01000011, $DB, %00111111, $E5, %11001100, $EB, %11110011
frame767:
	.byte %01000001, $DC, %00001100
frame768:
	.byte %01000001, $DC, %00001111
frame769:
	.byte %01000001, $EC, %00000000
frame770:
	.byte %01000001, $DB, %11111111
frame771:
	.byte %01000001, $ED, %11111100
frame772:
	.byte %01000001, $EB, %00110011
frame773:
	.byte %01000001, $E5, %11001111
frame774:
	.byte %01000010, $DC, %11001111, $ED, %11001100
frame775:
	.byte %01000001, $DC, %11111111
frame776:
	.byte %01000001, $F4, %11110000
frame777:
	.byte %01000001, $F4, %11111100
frame778:
	.byte %01000010, $E3, %00111111, $F4, %11110000
frame779:
	.byte %01000001, $ED, %11111100
frame780:
	.byte %01000001, $ED, %11001100
frame781:
	.byte $88
frame782:
	.byte $88
frame783:
	.byte %01000001, $F3, %11110011
frame784:
	.byte $88
frame785:
	.byte $88
frame786:
	.byte $88
frame787:
	.byte $88
frame788:
	.byte $88
frame789:
	.byte %01000011, $E3, %00110011, $E5, %11001100, $F3, %11111111
frame790:
	.byte %01000001, $E5, %11001111
frame791:
	.byte %01000001, $DC, %11001111
frame792:
	.byte %01000001, $ED, %11111100
frame793:
	.byte %01000010, $E5, %11001100, $F4, %11111111
frame794:
	.byte %01000001, $DC, %00001111
frame795:
	.byte %01000001, $DB, %00111111
frame796:
	.byte $88
frame797:
	.byte %01000001, $EB, %11110011
frame798:
	.byte %01000010, $DC, %00000011, $EC, %11000000
frame799:
	.byte %01000001, $DC, %00000000
frame800:
	.byte %01000001, $ED, %11111111
frame801:
	.byte %01000010, $DD, %11001111, $EC, %11110000
frame802:
	.byte %01000001, $DB, %00110011
frame803:
	.byte %01000010, $D4, %11001111, $E5, %11111100
frame804:
	.byte %01000010, $DB, %00000011, $EB, %11111111
frame805:
	.byte %01000100, $D3, %00111111, $DB, %00110011, $DD, %11001100, $EC, %11111100
frame806:
	.byte %01000010, $D4, %00001111, $EC, %11111111
frame807:
	.byte %01000001, $DD, %11001111
frame808:
	.byte %01000010, $DB, %00110000, $E3, %00110000
frame809:
	.byte %01000010, $DD, %11001100, $E5, %11111111
frame810:
	.byte %01000100, $D4, %00001100, $DB, %00000000, $E3, %11110011, $E4, %11000000
frame811:
	.byte $88
frame812:
	.byte %01000010, $D3, %00110011, $DD, %11111100
frame813:
	.byte %01000010, $D4, %00000000, $E4, %11110000
frame814:
	.byte $88
frame815:
	.byte %01000001, $D3, %00000011
frame816:
	.byte $88
frame817:
	.byte $88
frame818:
	.byte %01000010, $CC, %11001111, $E4, %11111100
frame819:
	.byte $88
frame820:
	.byte %01000100, $D3, %00000000, $D5, %11001111, $DB, %00110000, $E4, %11110000
frame821:
	.byte %01000011, $CB, %00111111, $D3, %00000011, $E4, %11111100
frame822:
	.byte $88
frame823:
	.byte %01000001, $DD, %11111111
frame824:
	.byte %01000011, $CB, %11111111, $DD, %11001111, $E4, %11110000
frame825:
	.byte %01000011, $D3, %00000000, $DB, %00000000, $DD, %11111111
frame826:
	.byte %01000010, $D5, %11111111, $DD, %11111100
frame827:
	.byte %01000010, $D3, %00000011, $DD, %11111111
frame828:
	.byte %01000001, $DD, %11111100
frame829:
	.byte %01000010, $D5, %11001111, $DD, %11001100
frame830:
	.byte %01000001, $D5, %11111111
frame831:
	.byte $88
frame832:
	.byte %01000001, $D5, %11001100
frame833:
	.byte %01000011, $CC, %11111111, $D3, %00110011, $D5, %11001111
frame834:
	.byte %01000001, $E4, %11000000
frame835:
	.byte $88
frame836:
	.byte %01000010, $CC, %00111111, $DB, %00110000
frame837:
	.byte %01000001, $CC, %11111111
frame838:
	.byte %01000010, $E4, %00000000, $E5, %11111100
frame839:
	.byte %01000001, $D3, %00111111
frame840:
	.byte $88
frame841:
	.byte $88
frame842:
	.byte $88
frame843:
	.byte %01000010, $D3, %00110011, $DB, %00110011
frame844:
	.byte %01000010, $D3, %00111111, $DB, %00000011
frame845:
	.byte %01000010, $DB, %00110011, $E5, %11001100
frame846:
	.byte %01000001, $DD, %00001100
frame847:
	.byte %01000001, $E3, %00110011
frame848:
	.byte %01000001, $D4, %00001100
frame849:
	.byte %01000010, $D4, %00001111, $DD, %11001100
frame850:
	.byte %01000001, $E5, %11000000
frame851:
	.byte %01000010, $DD, %00001100, $EC, %11111100
frame852:
	.byte %01000001, $EC, %11110000
frame853:
	.byte %01000001, $D3, %11111111
frame854:
	.byte $88
frame855:
	.byte $88
frame856:
	.byte $88
frame857:
	.byte %01000001, $ED, %11111100
frame858:
	.byte %01000001, $D5, %11111111
frame859:
	.byte $88
frame860:
	.byte %01000001, $D5, %11001111
frame861:
	.byte $88
frame862:
	.byte %01000001, $E5, %00000000
frame863:
	.byte %01000001, $E5, %11000000
frame864:
	.byte %01000010, $D4, %00111111, $D5, %11111111
frame865:
	.byte %01000001, $D4, %00001111
frame866:
	.byte %01000001, $ED, %11111111
frame867:
	.byte $88
frame868:
	.byte $88
frame869:
	.byte $88
frame870:
	.byte %01000001, $E5, %11001100
frame871:
	.byte %01000010, $DD, %11001100, $ED, %11111100
frame872:
	.byte %01000010, $D4, %00111111, $E5, %00001100
frame873:
	.byte %01000001, $E5, %11001100
frame874:
	.byte %01000001, $E5, %11000000
frame875:
	.byte %01000010, $E5, %11001100, $EB, %11110011
frame876:
	.byte %01000001, $D4, %00001111
frame877:
	.byte %01000001, $D4, %11001111
frame878:
	.byte %01000001, $ED, %11111111
frame879:
	.byte %01000010, $C6, %11110000, $C7, %11110000
frame880:
	.byte %01000100, $C3, %11110011, $C4, %11110000, $C5, %11110000, $D4, %11111111
frame881:
	.byte %01000010, $C2, %11110000, $C3, %11110000
frame882:
	.byte %01001001, $C0, %11110000, $C1, %11110000, $C4, %00110000, $C5, %00000000, $C6, %00000000, $C7, %00000000, $CF, %00000000, $DB, %00000011, $E3, %00110000
frame883:
	.byte %01001001, $C0, %00000000, $C1, %00000000, $C2, %00000000, $C3, %00000000, $C4, %00000000, $CD, %11110011, $CE, %00110000, $D4, %11001111, $D7, %11110011
frame884:
	.byte %01000111, $CD, %00000000, $CE, %00000000, $D4, %11111111, $D5, %11110011, $D6, %11110000, $D7, %00110000, $DF, %00110011
frame885:
	.byte %01001011, $C0, %11110000, $C1, %11110000, $C2, %11110000, $C3, %00110000, $CC, %00110000, $D5, %11111111, $D6, %00110011, $D7, %00000000, $DD, %11001111, $DF, %00000000, $E7, %00110000
frame886:
	.byte %01001011, $C0, %11111111, $CB, %11110011, $CC, %11110000, $CD, %00110000, $D6, %00001100, $D7, %11001100, $DE, %00000000, $DF, %00001100, $E6, %00110011, $E7, %00000000, $EF, %11110000
frame887:
	.byte %00000000, %00000000, %00000000, %11110000, %11111111, %11111111, %11111111, %11111111
	.byte %00000000, %00000000, %00000000, %00001100, %00111111, %00001111, %11111111, %11111111
	.byte %00000000, %00000000, %00000000, %00000000, %11110011, %00000000, %11001100, %00111111
	.byte %00000000, %00000000, %00000000, %11111100, %11111111, %00110000, %00000000, %00000011
	.byte %00000000, %00000000, %00000000, %11001111, %11111111, %00110011, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00001100, %00001111, %00000011, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000

frame888:
	.byte $88
frame889:
	.byte $88
frame890:
	.byte $88
frame891:
	.byte $88
frame892:
	.byte $88
frame893:
	.byte $88
frame894:
	.byte $88
frame895:
	.byte $88
frame896:
	.byte $88
frame897:
	.byte $88
frame898:
	.byte $88
frame899:
	.byte $88
frame900:
	.byte $88
frame901:
	.byte $88
frame902:
	.byte $88
frame903:
	.byte $88
frame904:
	.byte $88
frame905:
	.byte $88
frame906:
	.byte $88
frame907:
	.byte $88
frame908:
	.byte $88
frame909:
	.byte $88
frame910:
	.byte $88
frame911:
	.byte $88
frame912:
	.byte $88
frame913:
	.byte $88
frame914:
	.byte $88
frame915:
	.byte %01001111, $C2, %11001100, $C3, %11111111, $CB, %11001111, $CC, %11111111, $CD, %11111111, $D3, %11111100, $D4, %11111111, $D5, %00001111, $D6, %11111111, $DB, %11111111, $DD, %00000000, $DE, %00001111, $DF, %00000000, $E3, %11111111, $ED, %00000000
frame916:
	.byte %01001111, $C1, %00001111, $C2, %11001111, $CA, %00001100, $CB, %11111111, $D2, %11000000, $D3, %11111111, $D5, %11111111, $D7, %00000011, $DA, %11111100, $DD, %00001111, $DE, %00000011, $E2, %11001100, $E5, %00000000, $EB, %00001111, $EC, %00000011
frame917:
	.byte %01010011, $C0, %00001111, $C2, %11111111, $CA, %11001111, $CF, %00111111, $D1, %11000000, $D2, %11111111, $D6, %00111111, $D7, %00000000, $D9, %11001100, $DA, %11111111, $DC, %00111111, $DD, %11001111, $DE, %00000000, $E1, %11001100, $E2, %11111111, $E4, %00110011, $EA, %00001100, $EB, %00000011, $EC, %00000000
frame918:
	.byte %01001110, $C1, %11001111, $C9, %00001100, $CA, %11111111, $D1, %11111111, $D8, %11001100, $D9, %11111111, $DB, %00110011, $DC, %00001111, $DD, %11111111, $E1, %11111111, $E3, %00110011, $E4, %00000000, $EA, %00000011, $EB, %00000000
frame919:
	.byte %01001001, $C0, %11111111, $C1, %11111111, $C9, %11001100, $CF, %11111111, $D0, %11000000, $D6, %00000011, $E0, %11001100, $E3, %00000000, $E9, %00001111
frame920:
	.byte %01001101, $C0, %11111100, $C8, %00001111, $C9, %11001111, $D0, %11110000, $D1, %11111100, $D7, %00001111, $D8, %11111111, $DB, %00001100, $DC, %11001111, $E0, %11111111, $E2, %00111111, $E8, %00001100, $EA, %00000000
frame921:
	.byte %01001011, $C1, %11110011, $C9, %11111111, $D1, %11111111, $D6, %00111111, $D7, %11111111, $DA, %00000000, $DB, %00001111, $DD, %00111111, $E2, %00000000, $E8, %00001111, $E9, %00000011
frame922:
	.byte %01001100, $C1, %11111111, $C8, %11111111, $D0, %11001100, $D6, %11111111, $D9, %00110011, $DC, %11111111, $DD, %11001111, $DF, %00001111, $E1, %00110011, $E4, %00001100, $E8, %00111111, $E9, %00000000
frame923:
	.byte %01001011, $C0, %11111111, $C7, %11110011, $D0, %11111111, $D8, %00111111, $D9, %00001111, $DA, %00001111, $DD, %00111111, $DE, %00001111, $DF, %11111111, $E1, %00000000, $E8, %00000011
frame924:
	.byte %01001101, $C7, %11110000, $D8, %11001111, $D9, %11111111, $DA, %11111111, $DB, %11111111, $DC, %00001111, $DD, %00001111, $DE, %11111111, $E0, %00000000, $E3, %11001100, $E4, %00110011, $E7, %00001100, $E8, %00000000
frame925:
	.byte %01001110, $C5, %11110000, $C6, %00110000, $C7, %00000000, $C8, %11110011, $D8, %11111111, $DC, %11111111, $DD, %11111111, $E1, %00001100, $E2, %00000011, $E3, %11111111, $E4, %00000000, $E6, %00001111, $E7, %00001111, $EB, %00001100
frame926:
	.byte %01010000, $C4, %00110011, $C5, %11000000, $C6, %00000000, $C8, %11111111, $CC, %11110011, $CD, %11111100, $CE, %11110000, $CF, %11111100, $E0, %00001111, $E1, %00001111, $E2, %00001111, $E3, %00110011, $E5, %00001111, $E6, %11001111, $E7, %11111111, $EB, %00001111
frame927:
	.byte %01010000, $C4, %00000000, $C5, %00000000, $CC, %00000000, $CD, %00000000, $CE, %11000000, $CF, %11110000, $E0, %11111111, $E1, %11111111, $E2, %11111111, $E3, %00111111, $E4, %00001111, $E5, %11111111, $E6, %11111111, $EA, %00001100, $EB, %00110011, $EF, %00001111
frame928:
	.byte %01001101, $C1, %00110011, $C3, %00110011, $CB, %00110011, $CE, %00000000, $CF, %00000000, $D4, %11110000, $D5, %11111100, $E3, %11111111, $E4, %11111111, $EA, %11001100, $EB, %00000000, $ED, %00001100, $EE, %00001111
frame929:
	.byte %01010000, $C1, %11001100, $C3, %00000000, $CB, %00110000, $D3, %11110000, $D4, %11000000, $D5, %11110000, $D6, %11111100, $E8, %00001111, $E9, %00001111, $EA, %11111111, $EB, %00001111, $EC, %00001100, $ED, %00001111, $EE, %11001111, $EF, %11111111, $F2, %00001100
frame930:
	.byte %01001110, $C0, %00110000, $C2, %00110011, $C9, %11111100, $CB, %00000000, $D3, %00000000, $D4, %00000000, $D6, %11110000, $D7, %11110000, $EB, %00111111, $EC, %00001111, $ED, %11111111, $EE, %11111111, $F2, %00000011, $F7, %00001100
frame931:
	.byte %01010000, $C0, %00000000, $C1, %11000000, $C2, %00110000, $C8, %11110011, $C9, %11111111, $CA, %00110011, $D5, %00000000, $D7, %11000000, $DB, %11110000, $E8, %11111111, $E9, %11111111, $EC, %11111111, $F1, %00001100, $F2, %00110011, $F6, %00001111, $F7, %00001111
frame932:
	.byte %01010001, $C2, %00000000, $C8, %00110000, $CA, %00000000, $D2, %00110011, $D3, %11000000, $D6, %00000000, $D7, %00000000, $DA, %11110011, $DB, %11111100, $DC, %11111100, $DF, %11110011, $EB, %11111111, $F0, %00001100, $F1, %11001111, $F2, %00001111, $F5, %00001111, $F7, %00111111
frame933:
	.byte %01001100, $C1, %00000000, $C8, %11000000, $D2, %00000000, $D3, %00000000, $DA, %11111111, $DB, %11000011, $DC, %11110000, $DF, %00110011, $F0, %00001111, $F4, %00001111, $F6, %11001111, $F7, %11111111
frame934:
	.byte %01010000, $C8, %11001111, $C9, %11110011, $D0, %11111100, $DA, %00110011, $DB, %11000000, $DD, %11111100, $DE, %11110000, $DF, %00110000, $E7, %11110011, $F1, %11111111, $F2, %00111111, $F3, %00001100, $F5, %11001111, $F6, %11111111, $F7, %00111111, $FF, %00000011
frame935:
	.byte %01001010, $C9, %00110011, $D0, %11111111, $D1, %00110011, $DD, %11110000, $F0, %11001111, $F2, %00110011, $F5, %11111111, $F7, %00001111, $FE, %00001100, $FF, %00000000
frame936:
	.byte %01001110, $C0, %00000011, $C8, %11111100, $C9, %00110000, $D9, %11111100, $DA, %00000000, $DE, %00110000, $DF, %00000000, $E7, %00110000, $EF, %00111111, $F0, %11111111, $F2, %00000011, $F3, %00001111, $F9, %00000011, $FE, %00000000
frame937:
	.byte %01000111, $C0, %00110011, $C9, %00000000, $D9, %11111111, $DA, %11000000, $F2, %00000000, $F4, %11001111, $FE, %00001111
frame938:
	.byte %01001010, $C0, %00000011, $D1, %00110000, $DA, %11110000, $EF, %11000011, $F2, %00001100, $F6, %00111111, $F7, %00000011, $F8, %00001100, $F9, %00000000, $FE, %00000011
frame939:
	.byte %01000101, $E7, %00000000, $EF, %11110011, $F6, %11111111, $F7, %00001111, $FE, %00001100
frame940:
	.byte %01001001, $C0, %00110000, $D1, %00110011, $D9, %00111100, $DB, %00000000, $E7, %00110000, $EF, %00111111, $F4, %11111111, $F7, %00000011, $FE, %00001111
frame941:
	.byte %01000111, $C0, %00110011, $C8, %11111111, $C9, %00110000, $E7, %00000000, $EF, %11111111, $F2, %00001111, $F9, %00000011
frame942:
	.byte %01001000, $C8, %11001111, $D9, %11111100, $DA, %11110011, $DB, %00110000, $DC, %11000000, $E7, %00110000, $F7, %11111111, $F8, %00000000
frame943:
	.byte %01001110, $C0, %11111111, $C9, %00110011, $D0, %11111100, $D1, %11110011, $DA, %11000011, $DC, %00000000, $DE, %00000000, $E2, %11110011, $E7, %00110011, $F2, %00111111, $F3, %11001111, $F9, %00001111, $FD, %00001100, $FF, %00000011
frame944:
	.byte %01000110, $C9, %11110011, $D1, %11111111, $D9, %11111111, $DD, %11000000, $F8, %00001100, $FA, %00000011
frame945:
	.byte %01001001, $C8, %11111111, $D0, %11110011, $DA, %00111111, $DB, %11110000, $DD, %00000000, $E7, %11110011, $F2, %11111111, $FA, %00001111, $FF, %00001111
frame946:
	.byte %01000111, $C1, %11000000, $C9, %11111111, $D2, %00110011, $DC, %00110000, $E7, %11111111, $F8, %00001111, $FD, %00001111
frame947:
	.byte %01001001, $C1, %11110000, $CA, %00110000, $D0, %11111111, $DA, %11111111, $E2, %11111111, $E3, %11111100, $E4, %11110011, $F3, %00111111, $FB, %00000011
frame948:
	.byte %01001000, $C1, %11110011, $C2, %00110000, $CA, %00110011, $D2, %11111111, $DC, %11110000, $E4, %11110000, $E5, %11111100, $F3, %11111111
frame949:
	.byte %01001011, $C1, %11111111, $C2, %11110011, $CA, %11111111, $D1, %00111111, $DB, %11110011, $DD, %00110000, $E0, %11111100, $E4, %11110011, $E5, %11110000, $E6, %11111100, $FB, %00001111
frame950:
	.byte %01001101, $C2, %11111111, $C3, %00110000, $CA, %11001111, $CB, %11110011, $D1, %11111111, $D2, %11111100, $D3, %00110011, $E0, %11001100, $E3, %11111111, $E4, %00110011, $E6, %11110000, $E7, %11111100, $FC, %00000011
frame951:
	.byte %01001110, $C3, %00110011, $CA, %11111111, $CB, %11111111, $D2, %11110011, $D3, %11111111, $DB, %11111111, $DC, %00110000, $DD, %00000000, $E0, %00000011, $E4, %00111111, $E5, %11110011, $E7, %11110000, $E8, %11111100, $FC, %00001111
frame952:
	.byte %01000111, $C3, %11111111, $D2, %00111111, $DC, %00110011, $E0, %00111111, $E5, %11001111, $E6, %11110011, $E8, %11111111
frame953:
	.byte %01001100, $C0, %11001111, $C4, %00110011, $C8, %11111100, $CC, %00001111, $D2, %11111111, $D3, %11001111, $D4, %00110011, $E0, %11111111, $E1, %11001100, $E4, %11111111, $E7, %11000000, $E8, %11110011
frame954:
	.byte %01010010, $C0, %00001111, $C4, %11110011, $C8, %11000000, $CC, %11001111, $CD, %00000011, $D0, %11001100, $D3, %11111111, $D4, %11110011, $D8, %11111100, $DC, %11111111, $E0, %11001111, $E1, %00110011, $E5, %11000011, $E6, %11110000, $E7, %00000000, $E8, %11111111, $E9, %11111100, $F8, %00001100
frame955:
	.byte %01010010, $C0, %00001100, $C4, %11111111, $C5, %11110011, $C8, %00000000, $CC, %11110011, $CD, %00001100, $D0, %00000000, $D3, %00111111, $D8, %11110011, $DD, %00110011, $E0, %00001100, $E1, %00111111, $E2, %11001111, $E5, %11111111, $E7, %00110000, $E8, %11001100, $E9, %11000011, $F8, %00000000
frame956:
	.byte %01010101, $C0, %00000000, $C1, %11001111, $C5, %11111111, $C6, %00110000, $C9, %11001100, $CC, %11111111, $CD, %00110000, $D0, %00110011, $D1, %11111100, $D3, %11111111, $D4, %11001111, $D5, %00110000, $D8, %11111111, $D9, %11111100, $DC, %11111100, $DD, %11111111, $E1, %11111111, $E8, %11000000, $E9, %00110011, $EA, %11111100, $EE, %11110011
frame957:
	.byte %01010011, $C6, %11110011, $C9, %00000000, $CD, %11110011, $D0, %11110011, $D1, %11000000, $D4, %00111111, $D5, %00110011, $D8, %11001111, $D9, %11110000, $DC, %11111111, $DE, %00110011, $E0, %00000000, $E1, %11001111, $E2, %00111111, $E6, %11110011, $E8, %00000000, $E9, %11111100, $EA, %11000000, $F9, %00001100
frame958:
	.byte %01010111, $C1, %00001100, $C6, %11111111, $C7, %00110011, $CA, %11001100, $CD, %00111111, $CE, %00110000, $D0, %11111111, $D1, %00000000, $D2, %11111100, $D5, %11001111, $D8, %00001111, $D9, %11110011, $DA, %11111100, $DE, %11111111, $E1, %00001100, $E2, %11111111, $E3, %11001111, $E6, %11111111, $E9, %11001100, $EA, %00000011, $F0, %11110000, $F2, %11111100, $F9, %00001111
frame959:
	.byte %01010111, $C1, %00000000, $C7, %11111111, $CD, %11111111, $CE, %00000011, $D1, %00110011, $D2, %11001100, $D4, %11111111, $D6, %00110000, $D8, %00001100, $D9, %11001111, $DD, %11111100, $DF, %00110011, $E1, %00000000, $E3, %11111111, $E7, %00110011, $E9, %00000000, $EA, %00111111, $EB, %11001100, $EE, %11111111, $EF, %11111100, $F1, %11111100, $F2, %11110011, $F8, %00001111
frame960:
	.byte %01010100, $C2, %11001111, $C7, %00111111, $CA, %00000000, $CE, %11000011, $CF, %00000011, $D0, %11001100, $D1, %11111111, $D2, %00000000, $D5, %11111111, $DA, %00110000, $DD, %11111111, $DE, %11110011, $E2, %11001111, $E3, %00111111, $E7, %11110011, $EA, %11111100, $EB, %11000000, $EF, %11111111, $F1, %11110000, $F3, %11111100
frame961:
	.byte %00000000, %00000000, %11001100, %11111111, %11111111, %11111111, %11111111, %11110011
	.byte %00000000, %00000000, %00000000, %11001100, %11111111, %11111111, %11110011, %00110000
	.byte %00000000, %11111111, %00110000, %11111100, %11111111, %11111111, %00000011, %00000000
	.byte %00000000, %00001111, %11110011, %11001111, %11111111, %11110011, %11111111, %11110000
	.byte %00000000, %00000000, %00001100, %11111111, %11111111, %11111111, %11111111, %11111111
	.byte %00000000, %00000000, %11001100, %00000011, %11111100, %11111111, %11111111, %11111111
	.byte %11110000, %00110000, %11111111, %11111100, %11111111, %11111111, %11111111, %11111111
	.byte %00001111, %00001111, %00001111, %00001111, %00001111, %00001111, %00001111, %00001111

frame962:
	.byte %01010010, $C2, %00000000, $CF, %00110011, $D1, %11111100, $D2, %00110011, $D3, %11001100, $D6, %00111111, $D9, %00001100, $DA, %11001111, $DB, %11111100, $DD, %11111111, $DE, %11001100, $EA, %00000000, $EB, %00111111, $EC, %11001100, $F0, %00110000, $F1, %00000000, $F2, %11111100, $F3, %11000000
frame963:
	.byte %01010100, $C7, %11111111, $CB, %00001100, $CE, %11111111, $CF, %00111111, $D1, %11001100, $D2, %11110011, $D3, %00000000, $D6, %11111111, $D7, %00111100, $DB, %00111100, $DE, %11111100, $DF, %11110011, $E2, %00000000, $E3, %11001111, $EB, %11111100, $EC, %11000011, $F0, %00000000, $F2, %11000000, $F3, %00110011, $F4, %11111100
frame964:
	.byte %01001011, $C3, %11001111, $D1, %00000000, $D2, %11111111, $D9, %00000000, $DA, %00001111, $DB, %00110000, $DE, %11110011, $EB, %11001100, $EC, %00000011, $F2, %00000000, $F3, %00111111
frame965:
	.byte %01001110, $CB, %00000000, $CC, %11001111, $CF, %11111111, $D3, %00110000, $D4, %11001100, $D7, %00111111, $DB, %11110011, $DE, %00111111, $DF, %00110000, $E3, %00001100, $EB, %11000000, $EC, %00110011, $F3, %00111100, $F4, %11000000
frame966:
	.byte %01001011, $D2, %11111100, $DA, %00001100, $DC, %11001111, $DE, %11111111, $DF, %11110000, $EB, %00000000, $EC, %00111111, $ED, %11001100, $F3, %11111100, $F9, %00000011, $FA, %00000000
frame967:
	.byte %01001100, $C3, %00001111, $D2, %11001100, $D3, %00110011, $DC, %11001100, $DF, %11001100, $EF, %00111111, $F3, %11001100, $F4, %00000011, $F5, %11111100, $F8, %00000000, $F9, %00000000, $FC, %00001100
frame968:
	.byte %01000111, $C3, %11001111, $D2, %11000000, $D4, %11000000, $DF, %11001111, $E7, %11111100, $EC, %11111100, $F3, %11000000
frame969:
	.byte %01001100, $CC, %00001111, $D3, %11110011, $D4, %00000000, $D7, %11111111, $DB, %11111111, $DF, %11000011, $ED, %11001111, $EF, %11111111, $F4, %00110011, $F5, %11001100, $FB, %00001100, $FC, %00000000
frame970:
	.byte %01001011, $CC, %11001111, $DC, %11000000, $DF, %00000011, $E3, %00000000, $E7, %11111111, $EC, %11001100, $ED, %00001111, $F3, %00000000, $F4, %00111111, $F5, %11000000, $FC, %00000011
frame971:
	.byte %01000101, $D2, %00000000, $D3, %11110000, $DA, %00000000, $DF, %00111111, $E4, %11000011
frame972:
	.byte %01000111, $DC, %00110000, $E7, %11110011, $ED, %00111111, $F4, %11111100, $F5, %00000000, $FB, %00000000, $FD, %00001100
frame973:
	.byte %01000011, $CC, %11001100, $D5, %11001111, $F4, %11001100
frame974:
	.byte %01001000, $DC, %00110011, $DD, %11111100, $DF, %11111111, $EC, %00001100, $ED, %11111111, $F5, %00000011, $FC, %00001111, $FD, %00000000
frame975:
	.byte %01000100, $D3, %11000000, $D5, %11001100, $F6, %11001100, $FC, %00001100
frame976:
	.byte %01000101, $D5, %11001111, $E4, %11001111, $E7, %11111111, $F4, %11000000, $F5, %00110011
frame977:
	.byte %01000100, $CC, %11001111, $DD, %11001100, $E4, %11000011, $FE, %00001100
frame978:
	.byte %01000010, $E3, %00001100, $F5, %00111111
frame979:
	.byte %01000011, $F4, %00000000, $F6, %11001111, $FD, %00000011
frame980:
	.byte %01000001, $E5, %11111100
frame981:
	.byte %01000010, $D3, %00000000, $DB, %11111100
frame982:
	.byte %01000010, $CC, %00001111, $D5, %11111111
frame983:
	.byte %01000100, $CC, %11001111, $DD, %11000000, $F5, %11111111, $FC, %00000000
frame984:
	.byte %01000011, $C3, %11111111, $E4, %11110011, $EC, %11001100
frame985:
	.byte %01000101, $C2, %00001100, $CB, %00001100, $DD, %11001100, $ED, %11111100, $F6, %11111111
frame986:
	.byte %01000100, $CC, %11111111, $D4, %00001100, $E5, %11001100, $ED, %11111111
frame987:
	.byte $88
frame988:
	.byte %01000010, $E3, %00001111, $F4, %00001100
frame989:
	.byte %01000011, $C2, %11001100, $FD, %00001111, $FE, %00001111
frame990:
	.byte %01000111, $C2, %11001111, $CB, %11001111, $D4, %11001100, $DD, %00001111, $E3, %11001111, $E4, %00110011, $F4, %11001100
frame991:
	.byte %01000001, $DD, %11001111
frame992:
	.byte %01000010, $EC, %11001111, $FC, %00001100
frame993:
	.byte $88
frame994:
	.byte %01000001, $D4, %11001111
frame995:
	.byte $88
frame996:
	.byte %01000001, $DC, %00110000
frame997:
	.byte %01000010, $DC, %00111100, $ED, %11111100
frame998:
	.byte $88
frame999:
	.byte %01000001, $DD, %11111111
frame1000:
	.byte %01000010, $C2, %11001100, $DB, %11001100
frame1001:
	.byte %01000001, $DB, %11000000
frame1002:
	.byte $88
frame1003:
	.byte $88
frame1004:
	.byte %01000010, $E3, %11001100, $E4, %00111111
frame1005:
	.byte $88
frame1006:
	.byte %01000001, $D4, %11111111
frame1007:
	.byte %01000001, $DC, %11111100
frame1008:
	.byte %01000001, $E4, %11111111
frame1009:
	.byte %01000010, $DB, %00000000, $E5, %11001111
frame1010:
	.byte %01000001, $C4, %11111100
frame1011:
	.byte %01000001, $ED, %11001100
frame1012:
	.byte %01000001, $C4, %11110000
frame1013:
	.byte %01000010, $D3, %00001100, $FC, %00000000
frame1014:
	.byte %01000011, $C2, %11001111, $CF, %00111111, $F4, %00001100
frame1015:
	.byte %01000010, $CA, %00001100, $CB, %11111111
frame1016:
	.byte %01000010, $ED, %11111100, $F4, %00000000
frame1017:
	.byte %01000010, $C2, %11111111, $DC, %11001100
frame1018:
	.byte %01000100, $C3, %11110011, $DC, %11001111, $E3, %11000000, $E5, %11111111
frame1019:
	.byte %01000011, $CA, %11001111, $D3, %11001111, $DC, %11111100
frame1020:
	.byte %01000100, $C2, %11111100, $C3, %00110011, $C4, %11000000, $DC, %11111111
frame1021:
	.byte %01000011, $C1, %11000000, $C2, %11111111, $EB, %00001100
frame1022:
	.byte %01001000, $C2, %11001111, $C7, %11110011, $C9, %00001100, $CA, %11111111, $CF, %00001111, $D2, %00001100, $D7, %11110011, $DB, %00001100
frame1023:
	.byte %01000010, $C1, %00000000, $D3, %11111111
frame1024:
	.byte %01000100, $C4, %11001100, $C9, %11001100, $CF, %00001100, $DC, %11001111
frame1025:
	.byte %01000110, $C2, %11111111, $CA, %11111100, $D2, %00001111, $ED, %11111111, $F4, %11000000, $F7, %11110011
frame1026:
	.byte %01000101, $C3, %00111111, $C9, %11000000, $CB, %11110011, $D2, %11001111, $F7, %00110011
frame1027:
	.byte %01000101, $C3, %00110011, $C7, %00110011, $CB, %11110000, $D1, %00001100, $DC, %11111111
frame1028:
	.byte %01000100, $C3, %00110000, $C7, %00110000, $CA, %11111111, $CE, %11110011
frame1029:
	.byte %01000110, $CA, %11001111, $CE, %00110011, $CF, %00001111, $D2, %11111111, $DB, %00001111, $EF, %00111111
frame1030:
	.byte %01000100, $C2, %11110011, $C9, %00000000, $D7, %11110000, $EF, %11001111
frame1031:
	.byte %01000110, $C2, %00110011, $C3, %00000000, $CA, %11111111, $EF, %00111111, $F4, %11001100, $FF, %00000011
frame1032:
	.byte %01000101, $C2, %00110000, $C4, %11000000, $C9, %00001100, $CE, %00111111, $D6, %11110011
frame1033:
	.byte %01000101, $C2, %00000000, $C6, %11110011, $EF, %11111111, $F7, %00111111, $FC, %00001100
frame1034:
	.byte %01000100, $C7, %00000000, $C9, %11000000, $F7, %11111100, $FF, %00001111
frame1035:
	.byte %01000100, $CA, %11110000, $CF, %00000011, $D1, %00000000, $F7, %11110000
frame1036:
	.byte %01000110, $C5, %11111100, $C6, %11110000, $C9, %00000000, $CB, %11000000, $E4, %00111111, $F7, %11111111
frame1037:
	.byte %01000011, $C5, %11110000, $CF, %11110011, $D7, %00110000
frame1038:
	.byte %01000100, $C6, %00110000, $CE, %00001111, $F7, %11001100, $FD, %00001100
frame1039:
	.byte %01000110, $CA, %11000000, $CF, %11110000, $D2, %11001111, $D6, %11110000, $E3, %11001100, $EB, %00000000
frame1040:
	.byte %01000100, $CA, %11001100, $DB, %00001100, $EC, %11000011, $EF, %00001111
frame1041:
	.byte %01000111, $CB, %11110011, $CE, %11001111, $CF, %00110000, $E4, %00110011, $EE, %00111111, $EF, %11001111, $F7, %11111111
frame1042:
	.byte %01000100, $C6, %00000000, $DF, %00111111, $EC, %11001111, $EF, %00001111
frame1043:
	.byte %01000101, $CE, %11000011, $E4, %11111111, $EC, %11001100, $EE, %00110011, $EF, %00111111
frame1044:
	.byte %01000010, $CA, %00000000, $EF, %00111100
frame1045:
	.byte %01000110, $C4, %00000000, $D2, %00001100, $DF, %00110011, $EF, %00110011, $F6, %11110011, $FC, %00001111
frame1046:
	.byte %01001011, $C5, %00110000, $CA, %11000000, $CB, %00110011, $CF, %00000000, $D7, %00000000, $EC, %11111111, $EF, %11110000, $F4, %11001111, $F5, %11001111, $F6, %11111111, $FC, %00000011
frame1047:
	.byte %01000011, $C5, %00000000, $CE, %11110011, $EE, %11110011
frame1048:
	.byte %01000111, $CC, %11111100, $CD, %00111111, $CE, %11110000, $DB, %00000000, $E3, %00001100, $F4, %00111111, $FD, %00001111
frame1049:
	.byte %01000110, $CE, %00110000, $D5, %11110011, $DB, %11000000, $DF, %00110000, $EE, %11111100, $F4, %00111100
frame1050:
	.byte %01001000, $CA, %11001100, $CD, %11111111, $D6, %00110000, $DC, %11001111, $E6, %00001111, $E7, %00000011, $EF, %11110011, $F5, %11111111
frame1051:
	.byte %01000111, $CB, %00110000, $D3, %11001111, $EF, %00110011, $F4, %00110011, $F7, %00111111, $FB, %00001100, $FC, %00001100
frame1052:
	.byte %01000100, $CA, %00000000, $DF, %00000000, $EC, %00111111, $F8, %00001111
frame1053:
	.byte %01001001, $CD, %11110011, $CE, %00000000, $DE, %11110011, $EC, %00001111, $EE, %11111111, $F4, %00000011, $F9, %00001111, $FA, %00000011, $FC, %00001111
frame1054:
	.byte %01000110, $EF, %00000000, $F3, %11000000, $F4, %11000011, $F7, %11111111, $FA, %00001111, $FB, %00001111
frame1055:
	.byte %01001001, $D2, %00000000, $D6, %00000000, $E3, %00000000, $E6, %11111111, $E7, %00000000, $EC, %00111111, $F0, %11110000, $F6, %11110011, $F7, %11111100
frame1056:
	.byte %01001000, $E6, %11110011, $EC, %00110011, $EF, %00110000, $F1, %11110000, $F2, %00110000, $F4, %11111100, $F6, %11111111, $F7, %11110000
frame1057:
	.byte %01001001, $E5, %00111111, $E6, %11110000, $EF, %11110000, $F2, %11110000, $F3, %11110000, $F7, %11111100, $F8, %00000011, $FA, %00000000, $FB, %00001100
frame1058:
	.byte %01001100, $CB, %00110011, $CD, %11110000, $D5, %11110000, $DE, %11110000, $E6, %00110000, $EE, %11110011, $F0, %11111111, $F3, %11111100, $F7, %11111111, $F8, %00000000, $F9, %00001100, $FB, %00000000
frame1059:
	.byte %01000100, $CD, %00110000, $EE, %00110011, $F0, %11001111, $F1, %11111111
frame1060:
	.byte %01001010, $CC, %11110000, $DE, %00110000, $E5, %11110011, $EC, %11000011, $EE, %00111111, $F2, %00001111, $F3, %11111111, $F4, %11111111, $F9, %00000000, $FA, %00000011
frame1061:
	.byte %01001010, $CB, %00000000, $D3, %00001111, $DB, %11001100, $E6, %00110011, $E8, %00110000, $EE, %11111111, $F0, %00001111, $F1, %11001111, $F3, %00001111, $FC, %00000011
frame1062:
	.byte %01001011, $E5, %11111111, $E8, %11110000, $EB, %11000000, $EF, %11110011, $F0, %00001100, $F1, %00001111, $F2, %00111111, $FA, %00000000, $FC, %00000000, $FD, %00001100, $FF, %00001100
frame1063:
	.byte %01000111, $DB, %00001100, $DC, %11001100, $E9, %11110000, $EC, %11001111, $EE, %11111100, $FE, %00000011, $FF, %00000000
frame1064:
	.byte %01001100, $DC, %11111100, $DD, %11001111, $E6, %00000000, $EA, %11110000, $EC, %11111100, $EE, %11110000, $EF, %11111111, $F0, %00000000, $F1, %00001100, $F2, %00000011, $F3, %00001100, $FE, %00000000
frame1065:
	.byte %01001001, $DD, %00001111, $E6, %00110000, $E8, %11000000, $EB, %11110000, $EE, %11110011, $F1, %00000000, $F3, %00000000, $F4, %00001111, $F6, %00111111
frame1066:
	.byte %01000111, $D5, %00110000, $DE, %00000000, $E8, %00001100, $EE, %11111111, $F6, %00001111, $F7, %11001111, $FD, %00000000
frame1067:
	.byte %01000101, $CB, %00110000, $E6, %11110000, $E9, %11110011, $F2, %00001100, $F7, %00001111
frame1068:
	.byte %01000110, $D3, %00001100, $E9, %11111111, $EA, %00110000, $EB, %11111100, $EC, %11111111, $F4, %00000011
frame1069:
	.byte %01001010, $CD, %00000000, $DD, %11001111, $E4, %11001111, $E9, %00001111, $EA, %00111111, $EB, %00001100, $F2, %00000000, $F4, %00000000, $F5, %11001111, $F6, %00001100
frame1070:
	.byte %01001000, $CB, %00000000, $E5, %00111111, $E6, %00110000, $E7, %11000000, $EA, %11001111, $EB, %00001111, $F5, %00000011, $F6, %00000000
frame1071:
	.byte %01000101, $CB, %11000000, $E5, %11111111, $E7, %11110000, $E8, %00000000, $F7, %00001100
frame1072:
	.byte %01000101, $DD, %00001111, $E6, %11110000, $E9, %00001100, $EA, %00001111, $F5, %00000000
frame1073:
	.byte %01000101, $DC, %11111111, $DD, %00111111, $E1, %00110000, $EC, %00111111, $F7, %00000000
frame1074:
	.byte %01000101, $DD, %00110011, $E1, %11110000, $EB, %00001100, $EC, %00001111, $ED, %00111111
frame1075:
	.byte %01001001, $DB, %00000000, $DD, %00111111, $E2, %00110000, $E3, %11000000, $E6, %11110011, $E9, %00000000, $EA, %00001100, $EB, %00000000, $EE, %11001111
frame1076:
	.byte %01000011, $E2, %11110000, $E4, %11111100, $EE, %00001111
frame1077:
	.byte %01000011, $DD, %00110011, $E3, %11110000, $EA, %00000000
frame1078:
	.byte %01000101, $DD, %00110000, $E1, %11000000, $E5, %11110011, $E6, %11110000, $EF, %00001111
frame1079:
	.byte %01000011, $D3, %11001100, $E7, %11110011, $ED, %00110011
frame1080:
	.byte %01000101, $E1, %00000000, $E5, %11111111, $E6, %11111100, $EC, %00000011, $EF, %00111111
frame1081:
	.byte %01000100, $D3, %00001100, $EC, %00000000, $ED, %00000011, $EF, %00001111
frame1082:
	.byte %01000010, $E2, %11000000, $E6, %11111111
frame1083:
	.byte %01000101, $E1, %00001100, $E3, %11000000, $E7, %00110011, $EE, %00001100, $EF, %00000011
frame1084:
	.byte %01000010, $D3, %11001100, $E3, %00000000
frame1085:
	.byte %01000110, $DC, %11001111, $DD, %00110011, $E2, %00000011, $E4, %11111111, $E7, %00110000, $EF, %00000000
frame1086:
	.byte %01000011, $DD, %11110011, $E2, %00001111, $ED, %00000000
frame1087:
	.byte %01000100, $D4, %11110011, $E3, %00001111, $E5, %11001111, $EE, %00000000
frame1088:
	.byte %01000010, $DD, %11110000, $E7, %00110011
frame1089:
	.byte %01000011, $E1, %00000000, $E4, %11001111, $E7, %00110000
frame1090:
	.byte %01000010, $CC, %00110000, $DC, %11000011
frame1091:
	.byte %01000010, $E5, %00001111, $E7, %00000000
frame1092:
	.byte %01000100, $DD, %00110000, $DE, %00110000, $E2, %00001100, $E3, %00001100
frame1093:
	.byte %01000101, $D3, %11000000, $D5, %00000000, $DD, %00000000, $E3, %00000000, $E6, %00001111
frame1094:
	.byte %01000010, $DD, %11000000, $E2, %00000000
frame1095:
	.byte %01000010, $D3, %00000000, $DC, %11111111
frame1096:
	.byte %01000011, $DA, %00110000, $DD, %11110000, $E4, %00001111
frame1097:
	.byte %01000010, $DC, %11111100, $E3, %00000011
frame1098:
	.byte %01000001, $DA, %11110000
frame1099:
	.byte %01000100, $E3, %00000000, $E4, %00001100, $E5, %00001100, $E6, %00000011
frame1100:
	.byte %01000001, $DB, %00110000
frame1101:
	.byte %01000001, $DB, %11110000
frame1102:
	.byte %01000001, $DA, %11000000
frame1103:
	.byte %01000001, $E5, %00000000
frame1104:
	.byte $88
frame1105:
	.byte %01000010, $DD, %11110011, $E6, %00000000
frame1106:
	.byte %01000001, $DB, %11000000
frame1107:
	.byte %01000001, $DB, %11110000
frame1108:
	.byte %01000010, $DB, %00110000, $E4, %00000000
frame1109:
	.byte $88
frame1110:
	.byte %01000011, $D4, %00110011, $DA, %00000000, $DD, %11110000
frame1111:
	.byte %01000001, $DD, %11110011
frame1112:
	.byte $88
frame1113:
	.byte %01000001, $DC, %11111111
frame1114:
	.byte %01000011, $D4, %11110011, $DB, %00000000, $DD, %11111100
frame1115:
	.byte $88
frame1116:
	.byte %01000001, $DC, %00111111
frame1117:
	.byte %01000010, $CB, %00000000, $DE, %00000000
frame1118:
	.byte $88
frame1119:
	.byte $88
frame1120:
	.byte $88
frame1121:
	.byte %01000001, $CB, %11000000
frame1122:
	.byte $88
frame1123:
	.byte $88
frame1124:
	.byte $88
frame1125:
	.byte $88
frame1126:
	.byte $88
frame1127:
	.byte %01000001, $DC, %11001111
frame1128:
	.byte $88
frame1129:
	.byte $88
frame1130:
	.byte $88
frame1131:
	.byte $88
frame1132:
	.byte %01000001, $DD, %11111111
frame1133:
	.byte $88
frame1134:
	.byte $88
frame1135:
	.byte %01000001, $DC, %00001111
frame1136:
	.byte %01000001, $CB, %00000000
frame1137:
	.byte $88
frame1138:
	.byte %01000001, $CB, %11000000
frame1139:
	.byte $88
frame1140:
	.byte %01000001, $DA, %00001100
frame1141:
	.byte $88
frame1142:
	.byte $88
frame1143:
	.byte $88
frame1144:
	.byte $88
frame1145:
	.byte $88
frame1146:
	.byte $88
frame1147:
	.byte %01000001, $D4, %00110011
frame1148:
	.byte $88
frame1149:
	.byte $88
frame1150:
	.byte %01000001, $DD, %11001111
frame1151:
	.byte $88
frame1152:
	.byte $88
frame1153:
	.byte %01000001, $DB, %00001111
frame1154:
	.byte %01000001, $CB, %00000000
frame1155:
	.byte $88
frame1156:
	.byte $88
frame1157:
	.byte %01000001, $CC, %00000000
frame1158:
	.byte %01000001, $E3, %00000011
frame1159:
	.byte %01000001, $E3, %00000000
frame1160:
	.byte %01000001, $CB, %11000000
frame1161:
	.byte %01000001, $D3, %00001100
frame1162:
	.byte $88
frame1163:
	.byte $88
frame1164:
	.byte $88
frame1165:
	.byte $88
frame1166:
	.byte $88
frame1167:
	.byte $88
frame1168:
	.byte $88
frame1169:
	.byte $88
frame1170:
	.byte $88
frame1171:
	.byte $88
frame1172:
	.byte $88
frame1173:
	.byte $88
frame1174:
	.byte $88
frame1175:
	.byte $88
frame1176:
	.byte $88
frame1177:
	.byte $88
frame1178:
	.byte $88
frame1179:
	.byte $88
frame1180:
	.byte $88
frame1181:
	.byte $88
frame1182:
	.byte $88
frame1183:
	.byte $88
frame1184:
	.byte %01000010, $DB, %00001100, $DD, %11111111
frame1185:
	.byte %01000001, $CB, %00000000
frame1186:
	.byte $88
frame1187:
	.byte %01000001, $CC, %00110000
frame1188:
	.byte $88
frame1189:
	.byte %01000001, $D3, %00000000
frame1190:
	.byte %01000001, $DA, %00000011
frame1191:
	.byte $88
frame1192:
	.byte $88
frame1193:
	.byte $88
frame1194:
	.byte $88
frame1195:
	.byte %01000001, $DA, %00000000
frame1196:
	.byte $88
frame1197:
	.byte %01000010, $DC, %00110011, $DD, %11110011
frame1198:
	.byte %01000010, $DB, %00111100, $DC, %11110011
frame1199:
	.byte $88
frame1200:
	.byte %01000011, $CC, %00000000, $D3, %00001100, $DD, %11110000
frame1201:
	.byte %01000001, $DC, %11111111
frame1202:
	.byte %01000001, $DB, %00001100
frame1203:
	.byte %01000001, $DB, %00000000
frame1204:
	.byte $88
frame1205:
	.byte $88
frame1206:
	.byte %01000001, $DC, %11110011
frame1207:
	.byte %01000010, $D3, %11001100, $DC, %11111111
frame1208:
	.byte $88
frame1209:
	.byte %01000001, $DB, %11000000
frame1210:
	.byte %01000001, $D4, %00110000
frame1211:
	.byte $88
frame1212:
	.byte %01000001, $DC, %11110011
frame1213:
	.byte $88
frame1214:
	.byte $88
frame1215:
	.byte %01000010, $DA, %11000000, $DB, %11110000
frame1216:
	.byte $88
frame1217:
	.byte $88
frame1218:
	.byte $88
frame1219:
	.byte $88
frame1220:
	.byte $88
frame1221:
	.byte $88
frame1222:
	.byte $88
frame1223:
	.byte $88
frame1224:
	.byte $88
frame1225:
	.byte $88
frame1226:
	.byte $88
frame1227:
	.byte $88
frame1228:
	.byte $88
frame1229:
	.byte $88
frame1230:
	.byte $88
frame1231:
	.byte $88
frame1232:
	.byte %01000001, $D4, %11110000
frame1233:
	.byte %01000001, $E5, %00001100
frame1234:
	.byte %01000001, $D4, %00110000
frame1235:
	.byte %01000001, $D4, %11110011
frame1236:
	.byte %01000001, $DC, %11111111
frame1237:
	.byte %01000011, $DA, %00000000, $DB, %11000000, $E5, %00000000
frame1238:
	.byte $88
frame1239:
	.byte $88
frame1240:
	.byte %01000001, $D3, %00001100
frame1241:
	.byte $88
frame1242:
	.byte %01000010, $D4, %00110011, $DB, %00000000
frame1243:
	.byte %01000001, $D4, %11110011
frame1244:
	.byte %01000001, $D4, %00110011
frame1245:
	.byte %01000010, $D3, %00000000, $D4, %11110011
frame1246:
	.byte $88
frame1247:
	.byte $88
frame1248:
	.byte $88
frame1249:
	.byte %01000001, $DB, %00110000
frame1250:
	.byte %01000010, $CC, %00110000, $DC, %11110011
frame1251:
	.byte %01000010, $CB, %11000000, $DD, %11111100
frame1252:
	.byte $88
frame1253:
	.byte %01000001, $DC, %11111111
frame1254:
	.byte $88
frame1255:
	.byte %01000010, $DB, %00000000, $DC, %11001111
frame1256:
	.byte %01000010, $DC, %00001111, $DD, %11111111
frame1257:
	.byte $88
frame1258:
	.byte $88
frame1259:
	.byte $88
frame1260:
	.byte %01000001, $DA, %00001100
frame1261:
	.byte %01000001, $DC, %11001111
frame1262:
	.byte $88
frame1263:
	.byte $88
frame1264:
	.byte %01000010, $D4, %11111111, $DD, %11001111
frame1265:
	.byte %01000001, $DB, %00000011
frame1266:
	.byte $88
frame1267:
	.byte $88
frame1268:
	.byte %01000001, $CB, %00000000
frame1269:
	.byte $88
frame1270:
	.byte %01000001, $CC, %11110000
frame1271:
	.byte $88
frame1272:
	.byte %01000010, $D4, %11001111, $DB, %00001111
frame1273:
	.byte $88
frame1274:
	.byte $88
frame1275:
	.byte %01000001, $D4, %11111111
frame1276:
	.byte $88
frame1277:
	.byte $88
frame1278:
	.byte $88
frame1279:
	.byte %01000010, $D4, %11111100, $DD, %00001111
frame1280:
	.byte %01000011, $CC, %00110000, $D4, %11111111, $DE, %00110011
frame1281:
	.byte %01000001, $D4, %11001111
frame1282:
	.byte %01000011, $CC, %11110000, $DA, %00000000, $DC, %00001111
frame1283:
	.byte %01000001, $D5, %00000011
frame1284:
	.byte %01000011, $D4, %11001100, $D5, %00110011, $DD, %00111111
frame1285:
	.byte %01000010, $DC, %00001100, $DE, %11111111
frame1286:
	.byte $88
frame1287:
	.byte %01000001, $D4, %11000000
frame1288:
	.byte %01000100, $D4, %00001100, $DC, %00000000, $DD, %00001111, $DF, %00110000
frame1289:
	.byte %01000011, $CC, %11000000, $CD, %00110000, $DC, %00001100
frame1290:
	.byte %01000011, $D5, %11111111, $DB, %00000011, $DF, %00110011
frame1291:
	.byte $88
frame1292:
	.byte %01000100, $CD, %00110011, $D4, %00000000, $DC, %00000000, $DD, %11001111
frame1293:
	.byte %01000100, $CD, %11110011, $DB, %00000000, $DD, %11111111, $DF, %11110011
frame1294:
	.byte %01000001, $D5, %11110011
frame1295:
	.byte %01000010, $D5, %11111111, $DD, %11111100
frame1296:
	.byte %01000011, $CD, %11110000, $DE, %11001111, $DF, %11111111
frame1297:
	.byte %01000011, $D5, %11111100, $D6, %00110000, $DD, %11111111
frame1298:
	.byte %01000011, $CE, %00110000, $D5, %11111111, $DE, %11111111
frame1299:
	.byte %01000010, $CD, %11111100, $DC, %00110000
frame1300:
	.byte %01000101, $CC, %00000000, $D5, %11001111, $D6, %00110011, $DD, %11111100, $E7, %00001100
frame1301:
	.byte %01000011, $CE, %00000000, $D6, %00110000, $E6, %00000011
frame1302:
	.byte %01000010, $DC, %11110000, $DE, %11110011
frame1303:
	.byte %01000001, $D6, %00110011
frame1304:
	.byte $88
frame1305:
	.byte %01000011, $D6, %00000011, $DE, %11111111, $E7, %00001111
frame1306:
	.byte %01000001, $D5, %11001100
frame1307:
	.byte %01000001, $DF, %11111100
frame1308:
	.byte %01000010, $CD, %11110000, $DE, %11110011
frame1309:
	.byte %01000011, $DD, %11001100, $DE, %11111111, $E6, %00001111
frame1310:
	.byte %01000010, $DC, %00110000, $DE, %11111100
frame1311:
	.byte %01000010, $D6, %00000000, $DE, %11111111
frame1312:
	.byte %01000011, $DC, %00000000, $DE, %11110011, $E5, %00001100
frame1313:
	.byte %01000011, $CD, %11000000, $D6, %00110000, $DF, %11110000
frame1314:
	.byte %01000010, $D6, %00000000, $E6, %00111111
frame1315:
	.byte %01000010, $D5, %11001111, $E6, %00001100
frame1316:
	.byte %01000010, $E5, %00001111, $E6, %00001111
frame1317:
	.byte %01000101, $D5, %11111111, $E7, %00111111, $E8, %00110011, $F0, %00110011, $F8, %00000011
frame1318:
	.byte %01000001, $DF, %00110000
frame1319:
	.byte %01000100, $E7, %00001111, $E8, %11001100, $F0, %11111111, $F8, %00001111
frame1320:
	.byte %01000011, $DD, %11001111, $DE, %11110000, $E7, %00000011
frame1321:
	.byte %01000100, $E8, %00000000, $E9, %00110011, $F1, %00110011, $F9, %00000011
frame1322:
	.byte %01000010, $CD, %00000000, $E4, %00001100
frame1323:
	.byte %01000110, $DF, %00000000, $E6, %11001111, $E7, %00000000, $E9, %11001100, $F1, %11111111, $F9, %00001111
frame1324:
	.byte %01000100, $D5, %11110011, $DD, %11111111, $E6, %00001111, $E8, %00110000
frame1325:
	.byte %01001000, $E4, %00000000, $E5, %11001111, $E6, %11001111, $E8, %00110011, $E9, %00000000, $EA, %00110000, $F2, %00110011, $FA, %00000011
frame1326:
	.byte %01000101, $D5, %00110011, $E4, %00001100, $E6, %00001111, $E8, %11110011, $EA, %00110011
frame1327:
	.byte %01000011, $D5, %11110011, $E0, %00110000, $EA, %00110000
frame1328:
	.byte %01000110, $DE, %00110000, $E6, %00110011, $E8, %11111111, $EA, %11001100, $F2, %11111111, $FA, %00001111
frame1329:
	.byte %01000011, $E0, %11000000, $E4, %00000000, $E9, %00110000
frame1330:
	.byte %01000011, $E6, %00000011, $E8, %11001100, $EA, %00000000
frame1331:
	.byte $88
frame1332:
	.byte $88
frame1333:
	.byte $88
frame1334:
	.byte %01000001, $D5, %00110011
frame1335:
	.byte $88
frame1336:
	.byte $88
frame1337:
	.byte $88
frame1338:
	.byte $88
frame1339:
	.byte $88
frame1340:
	.byte %01000001, $E5, %00001111
frame1341:
	.byte $88
frame1342:
	.byte %01000001, $D5, %11110011
frame1343:
	.byte %01000001, $D5, %00110011
frame1344:
	.byte $88
frame1345:
	.byte $88
frame1346:
	.byte $88
frame1347:
	.byte $88
frame1348:
	.byte $88
frame1349:
	.byte $88
frame1350:
	.byte %01000010, $CD, %00110000, $DF, %11000000
frame1351:
	.byte $88
frame1352:
	.byte %01000001, $DF, %00000000
frame1353:
	.byte $88
frame1354:
	.byte %01000001, $DD, %11110011
frame1355:
	.byte $88
frame1356:
	.byte %01000010, $D4, %00001100, $D5, %00111111
frame1357:
	.byte %01000011, $DD, %11111111, $DE, %00110011, $E9, %00000000
frame1358:
	.byte %01000001, $E6, %00000000
frame1359:
	.byte %01000001, $EB, %00110000
frame1360:
	.byte $88
frame1361:
	.byte %01000010, $DE, %00110000, $F3, %00000011
frame1362:
	.byte %01000011, $E5, %00000011, $F3, %00110011, $FB, %00000011
frame1363:
	.byte %01000001, $E6, %00000011
frame1364:
	.byte $88
frame1365:
	.byte $88
frame1366:
	.byte %01000010, $DC, %11000000, $E5, %00000000
frame1367:
	.byte $88
frame1368:
	.byte %01000001, $D5, %00110011
frame1369:
	.byte $88
frame1370:
	.byte $88
frame1371:
	.byte %01000001, $D4, %00000000
frame1372:
	.byte $88
frame1373:
	.byte %01000100, $D5, %11110011, $DE, %00110011, $E6, %00000000, $E9, %00000011
frame1374:
	.byte %01000001, $EB, %00110011
frame1375:
	.byte $88
frame1376:
	.byte $88
frame1377:
	.byte $88
frame1378:
	.byte $88
frame1379:
	.byte %01000001, $DE, %00110000
frame1380:
	.byte %01000001, $E9, %00110011
frame1381:
	.byte $88
frame1382:
	.byte $88
frame1383:
	.byte $88
frame1384:
	.byte $88
frame1385:
	.byte $88
frame1386:
	.byte $88
frame1387:
	.byte %01000001, $D5, %00110011
frame1388:
	.byte $88
frame1389:
	.byte $88
frame1390:
	.byte $88
frame1391:
	.byte $88
frame1392:
	.byte $88
frame1393:
	.byte %01000001, $E9, %11110011
frame1394:
	.byte $88
frame1395:
	.byte $88
frame1396:
	.byte $88
frame1397:
	.byte %01000001, $D4, %00001100
frame1398:
	.byte $88
frame1399:
	.byte %01000001, $E5, %00001100
frame1400:
	.byte $88
frame1401:
	.byte $88
frame1402:
	.byte $88
frame1403:
	.byte $88
frame1404:
	.byte $88
frame1405:
	.byte %01000010, $CD, %00000000, $DE, %00000000
frame1406:
	.byte %01000011, $DD, %11110011, $DE, %00110000, $E6, %00000011
frame1407:
	.byte %01000001, $DE, %00000000
frame1408:
	.byte %01000010, $DE, %00110000, $E6, %00000000
frame1409:
	.byte $88
frame1410:
	.byte $88
frame1411:
	.byte %01000010, $DC, %00000000, $EB, %00110000
frame1412:
	.byte $88
frame1413:
	.byte $88
frame1414:
	.byte %01000001, $E6, %00000011
frame1415:
	.byte $88
frame1416:
	.byte %01000001, $DE, %00000000
frame1417:
	.byte %01000001, $E5, %00001111
frame1418:
	.byte $88
frame1419:
	.byte %01000010, $E4, %00001100, $E9, %11111111
frame1420:
	.byte %01000001, $D4, %00000000
frame1421:
	.byte %01000010, $E6, %00000000, $EB, %00000000
frame1422:
	.byte $88
frame1423:
	.byte %01000001, $DE, %00110000
frame1424:
	.byte $88
frame1425:
	.byte %01000001, $D5, %00110000
frame1426:
	.byte %01000001, $DE, %00000000
frame1427:
	.byte $88
frame1428:
	.byte $88
frame1429:
	.byte $88
frame1430:
	.byte $88
frame1431:
	.byte $88
frame1432:
	.byte %01000001, $E0, %00000000
frame1433:
	.byte %01000001, $E5, %11001111
frame1434:
	.byte $88
frame1435:
	.byte $88
frame1436:
	.byte $88
frame1437:
	.byte $88
frame1438:
	.byte $88
frame1439:
	.byte $88
frame1440:
	.byte %01000001, $E5, %00001111
frame1441:
	.byte $88
frame1442:
	.byte $88
frame1443:
	.byte %01000001, $E5, %11001111
frame1444:
	.byte $88
frame1445:
	.byte $88
frame1446:
	.byte $88
frame1447:
	.byte %01000001, $D4, %00001100
frame1448:
	.byte $88
frame1449:
	.byte %01000010, $E5, %00001111, $EB, %11000000
frame1450:
	.byte %01000001, $F3, %00111111
frame1451:
	.byte %01000010, $F3, %11111111, $FB, %00001111
frame1452:
	.byte $88
frame1453:
	.byte %01000011, $E4, %00000000, $E9, %11110011, $EB, %11001100
frame1454:
	.byte %01000001, $DC, %11000000
frame1455:
	.byte %01000001, $E6, %00000011
frame1456:
	.byte $88
frame1457:
	.byte $88
frame1458:
	.byte %01000001, $D5, %00110011
frame1459:
	.byte %01000001, $E6, %00000000
frame1460:
	.byte $88
frame1461:
	.byte $88
frame1462:
	.byte $88
frame1463:
	.byte $88
frame1464:
	.byte %01000001, $D4, %11001100
frame1465:
	.byte $88
frame1466:
	.byte %01000010, $D5, %00000011, $DD, %11111111
frame1467:
	.byte $88
frame1468:
	.byte $88
frame1469:
	.byte $88
frame1470:
	.byte $88
frame1471:
	.byte %01000001, $E5, %00000011
frame1472:
	.byte $88
frame1473:
	.byte $88
frame1474:
	.byte %01000001, $E9, %00110011
frame1475:
	.byte $88
frame1476:
	.byte $88
frame1477:
	.byte $88
frame1478:
	.byte $88
frame1479:
	.byte $88
frame1480:
	.byte $88
frame1481:
	.byte $88
frame1482:
	.byte $88
frame1483:
	.byte $88
frame1484:
	.byte $88
frame1485:
	.byte $88
frame1486:
	.byte $88
frame1487:
	.byte %01000001, $E5, %00000000
frame1488:
	.byte %01000010, $D5, %00110011, $E5, %00001100
frame1489:
	.byte $88
frame1490:
	.byte %01000010, $D4, %11000000, $DE, %00110000
frame1491:
	.byte %01000011, $DC, %00000000, $E9, %11110011, $EB, %11000000
frame1492:
	.byte %01000010, $CD, %00110000, $D4, %00000000
frame1493:
	.byte %01000101, $D5, %11110011, $DC, %11000000, $DE, %00110011, $E0, %11000000, $E6, %00000011
frame1494:
	.byte %01000001, $F3, %11111100
frame1495:
	.byte %01000010, $F0, %11111100, $F2, %11110000
frame1496:
	.byte %01000011, $E8, %11111100, $E9, %11110000, $F0, %11111111
frame1497:
	.byte %01000011, $E5, %00001111, $E9, %00110000, $EB, %00000000
frame1498:
	.byte %01000100, $CD, %00110011, $D5, %11111111, $E5, %11001111, $E6, %00001111
frame1499:
	.byte %01000110, $D5, %00111111, $DC, %00000000, $E6, %00111111, $F1, %11110011, $F2, %00000000, $F3, %11001100
frame1500:
	.byte %01000110, $CC, %11000000, $DE, %11110011, $E0, %00000000, $E5, %11111111, $E9, %00000000, $F1, %11110000
frame1501:
	.byte %01000011, $E4, %00001100, $E6, %00001111, $F1, %00110000
frame1502:
	.byte %01000100, $CC, %00000000, $E6, %00111111, $E8, %11000000, $F3, %11000000
frame1503:
	.byte %01001000, $CD, %11110011, $DE, %11111111, $E6, %11111111, $E8, %00110000, $F1, %00000000, $F9, %00000011, $FA, %00000000, $FB, %00001100
frame1504:
	.byte %01000100, $D5, %11111111, $DF, %00110000, $E5, %00111111, $F9, %00000000
frame1505:
	.byte %01000001, $D6, %00110000
frame1506:
	.byte %01000111, $CE, %00110000, $E5, %00001111, $E7, %00110011, $E8, %00110011, $EE, %00001100, $F0, %11110011, $F3, %00000000
frame1507:
	.byte %01000110, $CD, %11111111, $D6, %00110011, $DD, %11111100, $E8, %00000000, $EE, %00000011, $EF, %00000011
frame1508:
	.byte %01001001, $CD, %11111100, $D6, %00000011, $DD, %11001100, $DF, %00110011, $E4, %00000000, $E5, %00111111, $E7, %11110011, $EF, %00000000, $F0, %00110011
frame1509:
	.byte %01000101, $E5, %11111111, $E7, %11111111, $F0, %00000011, $F8, %00000011, $FB, %00000000
frame1510:
	.byte %01000010, $DF, %11110011, $F0, %00000000
frame1511:
	.byte %01000101, $C5, %11000000, $D5, %11111100, $D6, %11000011, $ED, %00001100, $EF, %00001111
frame1512:
	.byte %01000011, $DF, %11111111, $EE, %00001111, $F8, %00000000
frame1513:
	.byte %01000100, $CE, %11110000, $D6, %00110011, $ED, %11001100, $EE, %00001100
frame1514:
	.byte %01000010, $EE, %11001100, $EF, %11001111
frame1515:
	.byte %01000100, $C6, %00110000, $CE, %11110011, $E5, %11111100, $ED, %11001111
frame1516:
	.byte %01000011, $D6, %00111111, $EF, %11111111, $F7, %00000011
frame1517:
	.byte %01000101, $DD, %00001100, $ED, %00001111, $EE, %11001111, $F6, %00001100, $F7, %00000000
frame1518:
	.byte %01000100, $CD, %11111111, $ED, %11001111, $EE, %11111111, $F7, %00000011
frame1519:
	.byte %01000110, $C5, %00000000, $C6, %00110011, $CE, %11111111, $E5, %11000000, $F6, %00000011, $F7, %11001111
frame1520:
	.byte %01001000, $CD, %11111100, $CF, %00110011, $D4, %11000000, $D6, %11111111, $DD, %00000000, $EE, %00111111, $F6, %00110011, $F7, %00111111
frame1521:
	.byte %01000110, $C6, %11111111, $CF, %00111111, $D5, %11110000, $D7, %00000011, $EE, %11111111, $F7, %11111111
frame1522:
	.byte %01000011, $D5, %11000000, $F5, %00001100, $F6, %00111111
frame1523:
	.byte %01001000, $CD, %00001100, $CF, %11111111, $DF, %11111100, $E5, %00000000, $ED, %11001100, $F6, %11111111, $F7, %11001111, $FF, %00001100
frame1524:
	.byte %01000101, $D7, %00111111, $DD, %00000011, $DF, %11111111, $E6, %11111100, $FE, %00001100
frame1525:
	.byte %01000110, $C7, %00110000, $CD, %00001111, $DF, %11110011, $ED, %11000000, $F5, %11001100, $F7, %11111111
frame1526:
	.byte %01000111, $C6, %11111100, $C7, %00110011, $DE, %11001111, $E6, %11001100, $F5, %11000000, $FE, %00001111, $FF, %00001111
frame1527:
	.byte %01000111, $C7, %11110011, $D7, %11111111, $DC, %11001100, $DE, %11001100, $DF, %11111111, $EE, %11111100, $F5, %11001100
frame1528:
	.byte %01001000, $C5, %11000000, $C7, %11111111, $CE, %11001111, $D6, %11111100, $DD, %00001111, $DE, %11001111, $ED, %00000000, $F5, %00001100
frame1529:
	.byte %01000010, $E6, %00001100, $EE, %11001100
frame1530:
	.byte %01000101, $CD, %00001100, $D5, %00000000, $DC, %11001111, $E6, %00000000, $EE, %11000000
frame1531:
	.byte %01000101, $DC, %00000011, $DE, %00001111, $EE, %00000000, $F5, %00000000, $F6, %11111100
frame1532:
	.byte %01000101, $C6, %11111111, $CE, %00001111, $D4, %11110000, $EF, %11111100, $F6, %11110000
frame1533:
	.byte %01000100, $E4, %00000011, $E7, %11001111, $EF, %11001100, $F6, %00110000
frame1534:
	.byte %01000111, $CD, %00000000, $CE, %00000000, $DB, %00001100, $DC, %00110011, $DD, %11111111, $E7, %11001100, $F7, %11001100
frame1535:
	.byte %01000110, $CF, %11001111, $DC, %00111100, $EF, %00001100, $F6, %00000000, $F7, %11000000, $FF, %00001100
frame1536:
	.byte %01001000, $C5, %00001100, $CF, %11001100, $DB, %11001100, $DC, %00111111, $DE, %11111111, $EF, %00000000, $F7, %00000000, $FF, %00000000
frame1537:
	.byte %01000111, $D6, %11001100, $DB, %00111111, $DC, %00001111, $E3, %11001100, $E4, %00000000, $E7, %00001100, $FE, %00000000
frame1538:
	.byte %01001001, $C5, %00000000, $CF, %00000000, $D3, %11000000, $D4, %00110000, $D6, %11000000, $DB, %11111111, $DC, %11001111, $DD, %11110011, $E5, %00001111
frame1539:
	.byte $88
frame1540:
	.byte %01000011, $C6, %11001111, $C7, %00001111, $DB, %11001111
frame1541:
	.byte $88
frame1542:
	.byte %01000010, $DA, %11000000, $DB, %00001111
frame1543:
	.byte %01000010, $C6, %00001111, $E3, %00001100
frame1544:
	.byte $88
frame1545:
	.byte %01000001, $E3, %00000000
frame1546:
	.byte %01000001, $EB, %00001100
frame1547:
	.byte %01000011, $DB, %11001111, $E3, %00001111, $EB, %00001111
frame1548:
	.byte $88
frame1549:
	.byte %01000001, $C6, %00001100
frame1550:
	.byte %01000101, $D6, %00000000, $DA, %00000000, $E6, %00000011, $E7, %00000000, $EB, %00001100
frame1551:
	.byte %01000001, $E3, %11001111
frame1552:
	.byte %01000011, $D7, %11111100, $DB, %11111111, $E7, %00000011
frame1553:
	.byte %01000011, $D4, %11110000, $DC, %00001111, $E7, %00000000
frame1554:
	.byte $88
frame1555:
	.byte %01000001, $E6, %00001111
frame1556:
	.byte %01000101, $C7, %00000011, $DB, %00111111, $E3, %11001100, $E5, %00001100, $E7, %00001100
frame1557:
	.byte %01000011, $D3, %00000000, $DD, %11111111, $DE, %11111100
frame1558:
	.byte %01000010, $DB, %11111111, $E3, %11001111
frame1559:
	.byte %01000010, $DB, %11111100, $DC, %00111111
frame1560:
	.byte %01000001, $C6, %00000000
frame1561:
	.byte %01000010, $C7, %00000000, $E7, %00001111
frame1562:
	.byte %01000001, $E4, %00000011
frame1563:
	.byte %01000010, $C7, %00001100, $EB, %00000000
frame1564:
	.byte %01000011, $D7, %11000000, $E3, %11000000, $E4, %00110011
frame1565:
	.byte %01000100, $C7, %00000000, $E3, %00000000, $E7, %00000011, $EC, %00000011
frame1566:
	.byte %01000001, $DC, %00001111
frame1567:
	.byte %01000001, $EC, %00110011
frame1568:
	.byte %01000001, $D5, %00110000
frame1569:
	.byte $88
frame1570:
	.byte $88
frame1571:
	.byte %01000010, $DE, %11111111, $E3, %00000011
frame1572:
	.byte %01000001, $E7, %00001111
frame1573:
	.byte $88
frame1574:
	.byte $88
frame1575:
	.byte %01000001, $DC, %00111111
frame1576:
	.byte %01000100, $D3, %11000000, $DB, %11111111, $DC, %00110011, $DD, %11001111
frame1577:
	.byte %01000001, $E5, %00000000
frame1578:
	.byte %01000011, $D5, %11110000, $E3, %00001100, $EC, %00000011
frame1579:
	.byte %01000010, $DC, %00000011, $E3, %11001100
frame1580:
	.byte %01000001, $D3, %11110000
frame1581:
	.byte %01000011, $DA, %00001100, $DB, %11110011, $EC, %00110011
frame1582:
	.byte %01000011, $D4, %11111111, $E3, %11000000, $E4, %00110000
frame1583:
	.byte %01000101, $D6, %00110000, $DB, %11000011, $E4, %00000000, $EB, %00001100, $EC, %00110000
frame1584:
	.byte %01000010, $DB, %00000011, $F4, %00000011
frame1585:
	.byte %01000110, $D2, %11000000, $D3, %11111100, $DB, %00000000, $EB, %11001100, $EC, %00000000, $F3, %00001100
frame1586:
	.byte %01000001, $E3, %00000000
frame1587:
	.byte %01000100, $D3, %11111111, $E6, %00001100, $F3, %11001100, $F4, %00110000
frame1588:
	.byte %01000010, $D6, %11110000, $DA, %00000000
frame1589:
	.byte %01000101, $D3, %00111111, $D5, %11110011, $DD, %00001111, $EB, %11000000, $FB, %00001100
frame1590:
	.byte %01000010, $F4, %00000000, $FC, %00000011
frame1591:
	.byte %01001101, $CB, %11000000, $CC, %00110000, $D2, %11001100, $D3, %00001111, $D5, %11111111, $D6, %11110011, $D7, %11110000, $DC, %00000000, $DD, %00001100, $E6, %00000000, $E7, %00000011, $EB, %11110000, $FC, %00000000
frame1592:
	.byte %01001011, $CB, %11110000, $CC, %11110000, $CD, %11110000, $D2, %00001100, $D3, %00000011, $D4, %00111111, $D6, %11111111, $D7, %11111111, $DD, %00000000, $DE, %11001111, $E7, %00000000
frame1593:
	.byte %01001100, $CA, %11000000, $CB, %11111111, $CC, %11111111, $CE, %11110000, $CF, %11000000, $D4, %00110011, $D5, %11001111, $DE, %00001100, $DF, %00001111, $EB, %11110011, $F3, %11001111, $FB, %00000000
frame1594:
	.byte %01001011, $CB, %00111111, $CD, %11111111, $CE, %11111111, $CF, %11111100, $D2, %00000000, $D3, %00000000, $D4, %00000011, $D5, %00001100, $DE, %00000000, $DF, %00000000, $EB, %00110011
frame1595:
	.byte %01001001, $C3, %11110000, $C4, %11110000, $C5, %00110000, $CA, %11001100, $CC, %00111111, $CF, %11111111, $D5, %00000000, $D6, %11001111, $D7, %00111111
frame1596:
	.byte %01001010, $C2, %11000000, $C5, %11110000, $C6, %11110000, $C7, %11110000, $CA, %00001100, $CB, %00000011, $CD, %11001111, $D4, %00000000, $D6, %00001100, $D7, %00001111
frame1597:
	.byte %01001010, $C3, %11111111, $C4, %11111111, $C5, %11111111, $C6, %11111111, $C7, %11111111, $CC, %00110011, $CD, %00001111, $D6, %00000000, $D7, %00000000, $F3, %00001111
frame1598:
	.byte %01001001, $C2, %11001100, $C3, %00111111, $CA, %00000000, $CB, %00000000, $CC, %00000011, $CD, %00000000, $CE, %00001111, $CF, %00001111, $EA, %00001100
frame1599:
	.byte %01001001, $C2, %00001100, $C3, %00000011, $C4, %00111111, $C5, %00001111, $CC, %00000000, $CE, %00000000, $CF, %00000000, $E3, %00110000, $F3, %00001100
frame1600:
	.byte %01001010, $C2, %00000000, $C3, %00000000, $C4, %00000011, $C5, %00000000, $C6, %00001111, $C7, %00001111, $E2, %11000000, $EA, %00000000, $EB, %11110011, $F3, %00000000
frame1601:
	.byte %01000011, $C4, %00000000, $C6, %00000000, $C7, %00000000
frame1602:
	.byte %01000010, $E2, %11001100, $EB, %11000011
frame1603:
	.byte %01000001, $EB, %00001111
frame1604:
	.byte $88
frame1605:
	.byte %01000011, $E2, %00001100, $E3, %11110011, $EB, %00001100
frame1606:
	.byte %01000001, $EB, %00000000
frame1607:
	.byte %01000001, $DA, %11000000
frame1608:
	.byte %01000010, $DA, %00000000, $E3, %11001111
frame1609:
	.byte $88
frame1610:
	.byte %01000010, $DB, %11000000, $E3, %00001111
frame1611:
	.byte %01000001, $DB, %11110000
frame1612:
	.byte %01000010, $DB, %11110011, $E3, %00000011
frame1613:
	.byte %01000001, $E3, %00000000
frame1614:
	.byte %01000001, $DB, %00110011
frame1615:
	.byte $88
frame1616:
	.byte %01000001, $D3, %00110000
frame1617:
	.byte $88
frame1618:
	.byte %01000010, $D2, %11000000, $E3, %00000011
frame1619:
	.byte %01000001, $D2, %00000000
frame1620:
	.byte %01000010, $E2, %00000000, $E3, %00000000
frame1621:
	.byte %01000001, $E3, %00000011
frame1622:
	.byte %01000010, $D3, %00110011, $E3, %00000000
frame1623:
	.byte %01000001, $DB, %11110011
frame1624:
	.byte %01000001, $DB, %00110011
frame1625:
	.byte %01000001, $DB, %00111111
frame1626:
	.byte %01000001, $DB, %00001111
frame1627:
	.byte %01000001, $DB, %00001100
frame1628:
	.byte %01000001, $D3, %11110011
frame1629:
	.byte $88
frame1630:
	.byte %01000001, $D2, %11000000
frame1631:
	.byte %01000010, $D3, %11000011, $DB, %00000000
frame1632:
	.byte %01000001, $D3, %11001111
frame1633:
	.byte %01000010, $D2, %00000000, $D3, %11111111
frame1634:
	.byte %01000010, $D3, %00111111, $D4, %00000011
frame1635:
	.byte $88
frame1636:
	.byte %01000101, $CB, %11000000, $CC, %00110000, $F0, %00110000, $F8, %00001111, $F9, %00000011
frame1637:
	.byte %01000111, $D4, %00000000, $E8, %11110011, $F0, %11111111, $F1, %11111111, $F2, %00110000, $F9, %00001111, $FA, %00001111
frame1638:
	.byte %01001011, $D8, %00110000, $E0, %11111111, $E1, %00110000, $E8, %11111111, $E9, %11111111, $EA, %11110011, $F2, %11111111, $F3, %11111111, $F4, %00110000, $FB, %00001111, $FC, %00001111
frame1639:
	.byte %01010000, $CC, %00110011, $D0, %11110000, $D8, %11111111, $D9, %11110011, $DA, %00110000, $E1, %11111111, $E2, %11111111, $E3, %00110000, $EA, %11111111, $EB, %11111111, $EC, %11110011, $F4, %11111111, $F5, %11111111, $F6, %00110000, $FD, %00001111, $FE, %00001111
frame1640:
	.byte %01010100, $C8, %11111111, $C9, %00110000, $CB, %11001100, $D0, %11111111, $D1, %11111111, $D2, %11110000, $D3, %00001111, $D9, %11111111, $DA, %11111111, $DB, %11110011, $DC, %00110000, $E3, %11111111, $E4, %11111111, $E5, %00110000, $EC, %11111111, $ED, %11111111, $EE, %11110011, $F6, %11111111, $F7, %11110011, $FF, %00001111
frame1641:
	.byte %01010011, $C0, %11111111, $C1, %11110011, $C9, %11111111, $CA, %11111111, $CB, %00110000, $CC, %00000000, $D2, %11111111, $D3, %11111111, $D4, %00110000, $DB, %11111111, $DC, %11111111, $DD, %11110011, $DE, %00110000, $E5, %11111111, $E6, %11111111, $E7, %11110000, $EE, %11111111, $EF, %11111111, $F7, %11111111
frame1642:
	.byte %01001110, $C1, %11111111, $C2, %11111111, $C3, %11110011, $CB, %00110011, $CC, %11110000, $CD, %00110000, $D3, %11110011, $D4, %11111111, $D5, %11111111, $D6, %11110000, $DD, %11111111, $DE, %11111111, $DF, %11110011, $E7, %11111111
frame1643:
	.byte %01001010, $C3, %11111111, $C4, %11111111, $C5, %11110000, $CC, %11111100, $CD, %11111111, $CE, %11110011, $CF, %00110000, $D6, %11111111, $D7, %11111111, $DF, %11111111
frame1644:
	.byte %01000111, $C3, %00111111, $C4, %11001111, $C5, %11111111, $C6, %11111111, $C7, %11110000, $CE, %11111111, $CF, %11111111
frame1645:
	.byte %01000010, $C7, %11111111, $D4, %11111100
frame1646:
	.byte %01000011, $CB, %11110011, $CC, %11001100, $D3, %11111111
frame1647:
	.byte $88
frame1648:
	.byte $88
frame1649:
	.byte %01000010, $CB, %11111111, $CC, %00001100
frame1650:
	.byte %01000001, $D4, %11111111
frame1651:
	.byte %01000001, $CC, %00110000
frame1652:
	.byte $88
frame1653:
	.byte $88
frame1654:
	.byte %01000100, $C4, %00001111, $C5, %11001111, $CB, %11110011, $CC, %11110000
frame1655:
	.byte %01000001, $CD, %11111100
frame1656:
	.byte %01000010, $C5, %11001100, $CC, %11111100
frame1657:
	.byte %01000001, $CD, %11111111
frame1658:
	.byte %01000011, $C3, %11111111, $C4, %00000011, $CB, %11111111
frame1659:
	.byte %01000001, $C5, %11111100
frame1660:
	.byte $88
frame1661:
	.byte %01000001, $CC, %11110000
frame1662:
	.byte %01000001, $CC, %11000000
frame1663:
	.byte %01000010, $C4, %00110011, $CC, %11110000
frame1664:
	.byte %01000001, $CC, %11110011
frame1665:
	.byte %01000011, $C5, %11001100, $CC, %00110011, $CD, %11111100
frame1666:
	.byte %01000010, $C4, %00111111, $CC, %11110011
frame1667:
	.byte $88
frame1668:
	.byte %01000011, $C4, %11111111, $C5, %00001100, $CC, %11111111
frame1669:
	.byte %01000010, $C5, %00000000, $CD, %11110011
frame1670:
	.byte %01000001, $CD, %11111111
frame1671:
	.byte %01000010, $C5, %00110000, $C6, %11111100
frame1672:
	.byte %01000001, $C6, %11001100
frame1673:
	.byte %01000010, $C5, %11110000, $C6, %11111100
frame1674:
	.byte %01000001, $C4, %11110000
frame1675:
	.byte $88
frame1676:
	.byte %01000010, $C4, %00110000, $C6, %11111111
frame1677:
	.byte %01000010, $C4, %00110011, $C5, %11111100
frame1678:
	.byte %01000001, $C5, %11001100
frame1679:
	.byte %01000001, $CD, %11111100
frame1680:
	.byte %01000010, $C4, %00111111, $C5, %11000000
frame1681:
	.byte %01000011, $C4, %11111111, $C5, %00000000, $CD, %11110000
frame1682:
	.byte $88
frame1683:
	.byte %01000010, $CD, %00000000, $CE, %11111100
frame1684:
	.byte %01000011, $CD, %00110011, $CE, %11001100, $D5, %11110011
frame1685:
	.byte %01000100, $C4, %11110011, $CD, %00110000, $CE, %00001100, $D6, %11111100
frame1686:
	.byte %01000110, $C4, %00110011, $C5, %00001100, $CC, %11110011, $CD, %00000000, $CE, %00001111, $D6, %11001100
frame1687:
	.byte %01001000, $C4, %00111111, $C5, %11111111, $CC, %00110011, $CD, %00001100, $D4, %11110011, $D5, %00110000, $D6, %00000000, $DE, %11111100
frame1688:
	.byte %01001001, $C4, %11111111, $CC, %00111111, $CD, %11111111, $CE, %11111111, $D4, %00000000, $D5, %00000000, $DC, %11110011, $DD, %11110000, $DE, %00110000
frame1689:
	.byte %01001010, $CC, %11111111, $D4, %00111111, $D5, %11111111, $D6, %00111111, $DC, %00000000, $DD, %00000000, $DE, %00000000, $E4, %11110000, $E5, %11110000, $E6, %11110000
frame1690:
	.byte %01001011, $D4, %11111111, $D6, %11111111, $DC, %11111111, $DD, %11111111, $DE, %00001111, $E4, %00000000, $E5, %00000000, $E6, %00000000, $EC, %00110000, $ED, %11110000, $EE, %11110011
frame1691:
	.byte %01001001, $DE, %11111111, $E4, %11111111, $E5, %00111111, $E6, %00001100, $EC, %00001111, $ED, %00000000, $EE, %00000000, $F4, %11110000, $F5, %11111100
frame1692:
	.byte %01001001, $E6, %11001111, $EC, %11111111, $ED, %00110011, $EE, %00001100, $F4, %00001111, $F5, %00000000, $F6, %11110000, $FC, %00000000, $FD, %00001100
frame1693:
	.byte %01000111, $E5, %00110000, $ED, %00000011, $EE, %11000000, $F4, %00110011, $F5, %11000000, $F6, %11111111, $FC, %00000011
frame1694:
	.byte %01000101, $DD, %11001111, $E5, %00000000, $E6, %11001100, $ED, %00000000, $EE, %11111111
frame1695:
	.byte %01000110, $DC, %00111111, $DD, %00001111, $DE, %11001111, $E6, %11111100, $F5, %00000000, $FC, %00001111
frame1696:
	.byte %01000111, $DC, %00110011, $DD, %00000000, $DE, %11111100, $E6, %11111111, $F4, %11110011, $F5, %11000000, $FD, %00001111
frame1697:
	.byte %01000101, $D5, %00001111, $DE, %11111111, $EC, %00111111, $F4, %11111111, $F5, %11110000
frame1698:
	.byte %01000110, $D4, %00001111, $D5, %11001100, $DD, %11001100, $E5, %00001100, $EC, %11111111, $F5, %11110011
frame1699:
	.byte %01000101, $D3, %00111111, $D4, %00000011, $DC, %00110000, $E4, %11110011, $F5, %11111111
frame1700:
	.byte %01000101, $CC, %00111111, $D4, %00000000, $D5, %11111111, $E5, %00000000, $ED, %11110000
frame1701:
	.byte %01000100, $CC, %11001111, $D3, %00000011, $DD, %11001111, $ED, %11111100
frame1702:
	.byte %01000110, $CB, %00111111, $D4, %00001100, $DB, %11110000, $DD, %00001111, $E5, %11000000, $ED, %11111111
frame1703:
	.byte %01000101, $CC, %11111111, $D3, %00000000, $D4, %11001100, $DC, %00000000, $DD, %00001100
frame1704:
	.byte %01000010, $D4, %11001111, $DD, %00000000
frame1705:
	.byte %01000011, $CB, %11111111, $DA, %00110011, $E5, %11111100
frame1706:
	.byte %01000001, $D3, %00001100
frame1707:
	.byte %01000100, $D5, %11001111, $DB, %11000000, $DD, %00001100, $E4, %11111111
frame1708:
	.byte %01000101, $D2, %00111111, $D3, %00001111, $D4, %00001111, $DD, %11000000, $E5, %11111111
frame1709:
	.byte %01000010, $D5, %11111111, $E2, %11110011
frame1710:
	.byte %01000010, $DC, %00110000, $DD, %11001100
frame1711:
	.byte %01000010, $D2, %11111111, $DC, %11110000
frame1712:
	.byte %01000010, $D5, %11001111, $DD, %11111100
frame1713:
	.byte %01000011, $D3, %00111111, $D5, %11111111, $E2, %11110000
frame1714:
	.byte %01000010, $DD, %11111111, $E2, %00110011
frame1715:
	.byte $88
frame1716:
	.byte %01000010, $D3, %00001111, $E2, %00000000
frame1717:
	.byte %01000001, $DC, %11111100
frame1718:
	.byte %01000010, $D4, %11001111, $DB, %11110000
frame1719:
	.byte %01000001, $D2, %00111111
frame1720:
	.byte $88
frame1721:
	.byte %01000001, $DA, %00000011
frame1722:
	.byte %01000011, $DC, %11111111, $E2, %11000000, $EA, %11110011
frame1723:
	.byte %01000001, $D4, %11111111
frame1724:
	.byte %01000010, $D2, %11111111, $EA, %11111111
frame1725:
	.byte %01000101, $D2, %00111111, $DB, %11111100, $E2, %11001100, $E9, %00110011, $EA, %11111100
frame1726:
	.byte %01000001, $DA, %00000000
frame1727:
	.byte %01000010, $EA, %11001100, $F2, %11111100
frame1728:
	.byte %01000010, $D3, %11001100, $E9, %11110011
frame1729:
	.byte %01000011, $D9, %11110011, $DB, %11111111, $E9, %00110011
frame1730:
	.byte %01000001, $F1, %11110011
frame1731:
	.byte %01000001, $D2, %00110011
frame1732:
	.byte $88
frame1733:
	.byte %01000011, $D3, %11111111, $D9, %00111111, $F2, %11001100
frame1734:
	.byte %01000001, $F1, %00110011
frame1735:
	.byte %01000001, $D2, %00000000
frame1736:
	.byte %01000010, $D2, %00001100, $DA, %11000000
frame1737:
	.byte %01000001, $E1, %00110011
frame1738:
	.byte %01000100, $D2, %11001100, $DA, %11001100, $E1, %00111100, $F1, %11110011
frame1739:
	.byte %01000001, $E1, %00110000
frame1740:
	.byte %01000010, $D1, %00111111, $D9, %00110011
frame1741:
	.byte %01000010, $D1, %00110011, $F1, %11000011
frame1742:
	.byte $88
frame1743:
	.byte %01000010, $D2, %11001111, $E1, %00000000
frame1744:
	.byte %01000011, $D2, %11111111, $E2, %11111100, $F1, %11000000
frame1745:
	.byte %01000001, $E2, %11111111
frame1746:
	.byte %01000001, $EA, %11001111
frame1747:
	.byte %01000010, $E1, %00110000, $E9, %00000011
frame1748:
	.byte $88
frame1749:
	.byte %01000011, $D1, %00110000, $D9, %00000000, $EA, %11111111
frame1750:
	.byte %01000010, $E1, %00000000, $E9, %00000000
frame1751:
	.byte $88
frame1752:
	.byte %01000001, $C9, %00111111
frame1753:
	.byte %01000001, $F1, %00000000
frame1754:
	.byte %01000001, $D1, %00000000
frame1755:
	.byte $88
frame1756:
	.byte $88
frame1757:
	.byte %01000001, $F9, %00001100
frame1758:
	.byte %01000001, $F2, %11001111
frame1759:
	.byte %01000010, $C9, %11111111, $F2, %11001100
frame1760:
	.byte %01000001, $C9, %00111111
frame1761:
	.byte %01000001, $FA, %00001100
frame1762:
	.byte $88
frame1763:
	.byte %01000010, $C9, %00001111, $DA, %11111100
frame1764:
	.byte %01000001, $D2, %11001111
frame1765:
	.byte %01000010, $D1, %00000011, $EA, %11001111
frame1766:
	.byte $88
frame1767:
	.byte $88
frame1768:
	.byte %01000010, $CA, %11001111, $EA, %11001100
frame1769:
	.byte %01000001, $C9, %00000011
frame1770:
	.byte %01000001, $E2, %11001111
frame1771:
	.byte %01000011, $E1, %00110000, $E2, %11001100, $F9, %00000000
frame1772:
	.byte %01000001, $D1, %00110011
frame1773:
	.byte %01000011, $D2, %11001100, $DA, %11001100, $E9, %00000011
frame1774:
	.byte %01000010, $CA, %11001100, $E9, %00110011
frame1775:
	.byte %01000010, $D2, %00001100, $F1, %00000011
frame1776:
	.byte %01000011, $C9, %00110000, $DA, %11000000, $FA, %00000000
frame1777:
	.byte %01000011, $D9, %00000011, $F1, %00110011, $F2, %00001100
frame1778:
	.byte %01000001, $F9, %00000011
frame1779:
	.byte %01000010, $E1, %00000000, $F2, %00000000
frame1780:
	.byte %01000010, $D9, %00110011, $EA, %00001100
frame1781:
	.byte %01000011, $C2, %11001111, $C9, %00110011, $EA, %00000000
frame1782:
	.byte %01000001, $E2, %00001100
frame1783:
	.byte $88
frame1784:
	.byte %01000001, $E2, %00000000
frame1785:
	.byte %01000011, $C2, %11111111, $CA, %11000000, $E1, %00001100
frame1786:
	.byte %01000010, $D2, %00000000, $DA, %00000000
frame1787:
	.byte %01000001, $E1, %00000000
frame1788:
	.byte %01000010, $CA, %00000000, $E1, %00110000
frame1789:
	.byte %01000010, $D1, %00111111, $E1, %00110011
frame1790:
	.byte $88
frame1791:
	.byte %01000001, $D3, %11001111
frame1792:
	.byte %01000001, $E9, %00111111
frame1793:
	.byte %01000001, $FB, %00001100
frame1794:
	.byte %01000011, $D1, %11111111, $DB, %11111100, $F3, %11001111
frame1795:
	.byte %01000001, $E9, %11111111
frame1796:
	.byte %01000011, $C9, %00111111, $D9, %11111111, $F3, %11001100
frame1797:
	.byte %01000001, $EB, %11001100
frame1798:
	.byte %01000011, $C9, %11111111, $DB, %11001100, $E3, %11001100
frame1799:
	.byte $88
frame1800:
	.byte %01000001, $F1, %00111111
frame1801:
	.byte %01000001, $C2, %00111111
frame1802:
	.byte %01000011, $D3, %11001100, $E1, %11111111, $F1, %11111111
frame1803:
	.byte %01000001, $CB, %11111100
frame1804:
	.byte %01000011, $C2, %11111111, $D3, %00001100, $F9, %00001111
frame1805:
	.byte %01000010, $CB, %11001100, $D2, %00000011
frame1806:
	.byte %01000001, $EA, %00000011
frame1807:
	.byte %01000001, $D2, %00110011
frame1808:
	.byte %01000100, $C2, %00111111, $DA, %00000011, $DB, %11000000, $FB, %00000000
frame1809:
	.byte %01000010, $EA, %00110011, $F3, %00000000
frame1810:
	.byte %01000011, $CA, %00110000, $DA, %00110011, $EB, %00001100
frame1811:
	.byte %01000101, $C3, %11001111, $D3, %00000000, $DB, %00000000, $EB, %00000000, $F2, %00000011
frame1812:
	.byte %01000001, $E3, %00000000
frame1813:
	.byte %01000001, $F2, %00110011
frame1814:
	.byte %01000100, $C2, %11111111, $CA, %00110011, $CB, %11000000, $FA, %00000011
frame1815:
	.byte %01000001, $E2, %00110000
frame1816:
	.byte %01000011, $CB, %00000000, $D2, %00111111, $D4, %11001111
frame1817:
	.byte %01000001, $E2, %11110000
frame1818:
	.byte %01000010, $E2, %00110011, $EA, %00111111
frame1819:
	.byte %01000101, $CA, %11110011, $D2, %11111111, $DA, %00111111, $DC, %11111100, $EA, %11111111
frame1820:
	.byte %01000011, $C3, %00001111, $F4, %11001111, $FC, %00001100
frame1821:
	.byte %01000001, $F2, %00111111
frame1822:
	.byte %01000111, $C3, %00111111, $D4, %11001100, $DA, %11111111, $DC, %11001100, $E4, %11001100, $F2, %11111111, $F4, %11001100
frame1823:
	.byte %01000010, $EC, %11001111, $FA, %00001111
frame1824:
	.byte %01000011, $CC, %11111100, $D4, %00001100, $EC, %11001100
frame1825:
	.byte %01000011, $C3, %11111111, $CA, %11111111, $E2, %11110011
frame1826:
	.byte %01000001, $D3, %00000011
frame1827:
	.byte %01000010, $CC, %11001100, $E2, %11111111
frame1828:
	.byte %01000001, $D4, %00001111
frame1829:
	.byte %01000001, $D4, %00001100
frame1830:
	.byte %01000001, $DC, %11000000
frame1831:
	.byte %01000010, $C3, %00111111, $DB, %00110011
frame1832:
	.byte %01000010, $D3, %00110011, $E3, %00000011
frame1833:
	.byte %01000001, $C4, %11001111
frame1834:
	.byte %01000011, $CB, %00110000, $E3, %00110011, $FC, %00000000
frame1835:
	.byte $88
frame1836:
	.byte %01000100, $C4, %11111111, $CB, %00110011, $D4, %00000000, $F4, %00001100
frame1837:
	.byte %01000001, $EB, %00000011
frame1838:
	.byte %01000010, $C3, %11111111, $F4, %00000000
frame1839:
	.byte %01000001, $EB, %00110011
frame1840:
	.byte $88
frame1841:
	.byte %01000010, $EC, %00001100, $F3, %00000011
frame1842:
	.byte %01000011, $CC, %00001100, $DC, %00000000, $F3, %00110011
frame1843:
	.byte %01000100, $CC, %00000000, $D5, %11001111, $E4, %11000000, $FB, %00000011
frame1844:
	.byte $88
frame1845:
	.byte $88
frame1846:
	.byte %01000011, $D4, %00001100, $DD, %11001111, $EC, %00000000
frame1847:
	.byte $88
frame1848:
	.byte %01000011, $D3, %00111111, $D4, %00000000, $FD, %00001100
frame1849:
	.byte %01000001, $D3, %11111111
frame1850:
	.byte %01000001, $E4, %00000000
frame1851:
	.byte %01000010, $DB, %00111111, $DD, %11001100
frame1852:
	.byte %01000010, $CB, %11110011, $F5, %11001111
frame1853:
	.byte $88
frame1854:
	.byte %01000010, $C4, %00111111, $CD, %11001111
frame1855:
	.byte %01000011, $CB, %11111111, $DB, %11111111, $E3, %00111111
frame1856:
	.byte %01000010, $DD, %11000000, $E3, %11111111
frame1857:
	.byte %01000011, $C4, %11111111, $CD, %11111111, $F5, %11001100
frame1858:
	.byte %01000001, $EB, %00111111
frame1859:
	.byte %01000001, $EB, %11111111
frame1860:
	.byte %01000001, $F3, %00111111
frame1861:
	.byte $88
frame1862:
	.byte %01000011, $CD, %11001111, $DD, %11001100, $F3, %11111111
frame1863:
	.byte $88
frame1864:
	.byte %01000001, $E5, %11111100
frame1865:
	.byte %01000001, $FB, %00001111
frame1866:
	.byte $88
frame1867:
	.byte $88
frame1868:
	.byte %01000001, $D3, %00111111
frame1869:
	.byte %01000010, $DB, %11110011, $E5, %11111111
frame1870:
	.byte %01000001, $C4, %11001111
frame1871:
	.byte %01000001, $C4, %11111111
frame1872:
	.byte %01000010, $C4, %11001111, $E3, %00110011
frame1873:
	.byte %01000010, $C4, %11111111, $CD, %11111111
frame1874:
	.byte %01000010, $D3, %00001111, $E3, %11110011
frame1875:
	.byte %01000011, $C4, %00111111, $CB, %00111111, $E3, %00110011
frame1876:
	.byte %01000010, $CB, %00110011, $ED, %11001111
frame1877:
	.byte $88
frame1878:
	.byte %01000010, $C4, %11111111, $DB, %11110000
frame1879:
	.byte %01000010, $D2, %00111111, $ED, %11001100
frame1880:
	.byte %01000001, $CD, %11001111
frame1881:
	.byte %01000100, $DA, %11110011, $E3, %11110011, $E5, %11001111, $EB, %11110011
frame1882:
	.byte %01000001, $C4, %00111111
frame1883:
	.byte %01000010, $E5, %11001100, $EB, %11111111
frame1884:
	.byte %01000010, $C4, %00001111, $CD, %11001100
frame1885:
	.byte %01000010, $CB, %11110011, $E3, %11111111
frame1886:
	.byte %01000001, $D5, %00001111
frame1887:
	.byte %01000001, $DD, %00001100
frame1888:
	.byte %01000001, $DD, %00000000
frame1889:
	.byte %01000001, $D5, %00001100
frame1890:
	.byte $88
frame1891:
	.byte $88
frame1892:
	.byte %01000001, $FD, %00000000
frame1893:
	.byte %01000011, $C4, %00111111, $D3, %00111111, $DA, %11000011
frame1894:
	.byte %01000010, $DA, %00000011, $E5, %11000000
frame1895:
	.byte %01000001, $DA, %00000000
frame1896:
	.byte $88
frame1897:
	.byte %01000011, $D3, %11111111, $E4, %00110000, $F5, %00001100
frame1898:
	.byte %01000010, $CB, %11111111, $E4, %00110011
frame1899:
	.byte %01000001, $DB, %11000000
frame1900:
	.byte %01000010, $EC, %00000011, $F5, %00000000
frame1901:
	.byte $88
frame1902:
	.byte %01000001, $C4, %11111111
frame1903:
	.byte %01000001, $D2, %11001111
frame1904:
	.byte %01000001, $C4, %00111111
frame1905:
	.byte %01000010, $D2, %11111111, $EC, %00000000
frame1906:
	.byte %01000001, $E3, %00111111
frame1907:
	.byte %01000010, $E4, %00000000, $F5, %00001100
frame1908:
	.byte %01000001, $F5, %11001100
frame1909:
	.byte %01000011, $C5, %11001111, $D9, %00111111, $FD, %00001100
frame1910:
	.byte %01000001, $DB, %00000000
frame1911:
	.byte %01000010, $C4, %00001111, $D9, %00110011
frame1912:
	.byte %01000100, $C4, %00000011, $CB, %00111111, $E3, %00110011, $FB, %00000011
frame1913:
	.byte %01000001, $EB, %11110011
frame1914:
	.byte %01000011, $CB, %00110011, $D4, %00110000, $D5, %11001100
frame1915:
	.byte $88
frame1916:
	.byte %01000001, $E3, %11110011
frame1917:
	.byte %01000001, $F3, %00111111
frame1918:
	.byte $88
frame1919:
	.byte %01000011, $D9, %11111111, $E5, %00000000, $EB, %11111111
frame1920:
	.byte %01000001, $ED, %00001100
frame1921:
	.byte %01000101, $CB, %00111111, $E2, %11111100, $ED, %00000000, $F3, %11111111, $F5, %11000000
frame1922:
	.byte $88
frame1923:
	.byte %01000011, $DA, %00001100, $E2, %11111111, $F5, %00000000
frame1924:
	.byte %01000111, $C4, %00001111, $D4, %00000000, $DA, %00001111, $DB, %00000011, $E2, %11110011, $E3, %11111111, $FB, %00001111
frame1925:
	.byte %01000100, $C4, %00111111, $C5, %11111111, $DA, %00111111, $F5, %11000000
frame1926:
	.byte %01000001, $F5, %00000000
frame1927:
	.byte %01000001, $DB, %00001111
frame1928:
	.byte %01000011, $D5, %00001100, $E2, %11111111, $E3, %11111100
frame1929:
	.byte $88
frame1930:
	.byte %01000100, $CB, %11111111, $D5, %00000000, $DA, %11111111, $F6, %11001100
frame1931:
	.byte %01000010, $E3, %11110000, $EE, %11001100
frame1932:
	.byte %01000001, $F6, %11111100
frame1933:
	.byte %01000010, $DB, %00111111, $F6, %11001100
frame1934:
	.byte %01000010, $DB, %11111111, $E3, %00000000
frame1935:
	.byte %01000001, $DC, %00000011
frame1936:
	.byte %01000010, $CD, %00001100, $E3, %00000011
frame1937:
	.byte %01000010, $E6, %11001111, $EB, %11110011
frame1938:
	.byte %01000100, $C5, %11001111, $E3, %00111111, $FD, %00000000, $FE, %00001100
frame1939:
	.byte %01000010, $CD, %00000000, $FE, %00001111
frame1940:
	.byte $88
frame1941:
	.byte %01000011, $D4, %00110000, $F3, %11110011, $FE, %00001100
frame1942:
	.byte %01000100, $DC, %00110011, $E3, %11111111, $EB, %00110011, $F3, %11111111
frame1943:
	.byte $88
frame1944:
	.byte %01000011, $E4, %00000011, $EB, %00111111, $F3, %11110011
frame1945:
	.byte %01000010, $EB, %11111111, $F3, %11111111
frame1946:
	.byte %01000001, $D3, %11110011
frame1947:
	.byte $88
frame1948:
	.byte %01000010, $C5, %11111111, $E4, %00110011
frame1949:
	.byte $88
frame1950:
	.byte %01000001, $E4, %00000011
frame1951:
	.byte %01000100, $CC, %00000011, $D3, %11111111, $E6, %11111111, $FE, %00001111
frame1952:
	.byte $88
frame1953:
	.byte %01000001, $C4, %11111111
frame1954:
	.byte $88
frame1955:
	.byte $88
frame1956:
	.byte $88
frame1957:
	.byte $88
frame1958:
	.byte %01000001, $FB, %00000011
frame1959:
	.byte %01000001, $F3, %00111111
frame1960:
	.byte %01000001, $D4, %00000000
frame1961:
	.byte %01000001, $F3, %00110011
frame1962:
	.byte %01000010, $CC, %00000000, $E6, %11001111
frame1963:
	.byte %01000010, $EB, %00111111, $FB, %00001111
frame1964:
	.byte $88
frame1965:
	.byte %01000001, $FE, %00001100
frame1966:
	.byte $88
frame1967:
	.byte %01000011, $CD, %00001100, $F3, %00000011, $FB, %00000000
frame1968:
	.byte $88
frame1969:
	.byte %01000001, $F3, %00000000
frame1970:
	.byte %01000001, $FB, %00000011
frame1971:
	.byte %01000001, $E4, %00000000
frame1972:
	.byte %01000100, $C4, %11001111, $D3, %11110011, $EB, %00110011, $F3, %00110000
frame1973:
	.byte %01000010, $EB, %00000011, $FB, %00001111
frame1974:
	.byte %01000001, $F3, %00000000
frame1975:
	.byte %01000100, $C4, %11111111, $D3, %11111111, $F2, %00111111, $F3, %11000000
frame1976:
	.byte %01000001, $F2, %00110011
frame1977:
	.byte %01000011, $E6, %11111111, $F2, %11110011, $F3, %11001100
frame1978:
	.byte %01000011, $E3, %00111111, $EA, %00111111, $EB, %00000000
frame1979:
	.byte $88
frame1980:
	.byte %01000010, $CC, %00000011, $F2, %11111111
frame1981:
	.byte %01000010, $EB, %11000000, $F3, %11111100
frame1982:
	.byte %01000001, $EA, %00110011
frame1983:
	.byte %01000011, $E3, %00001111, $F2, %11111100, $F3, %11111111
frame1984:
	.byte %01000001, $F2, %11110000
frame1985:
	.byte %01000100, $CC, %00000000, $E3, %00000011, $EE, %11001111, $F2, %11110011
frame1986:
	.byte %01000011, $E2, %00111111, $EA, %00000011, $EB, %11001100
frame1987:
	.byte %01000011, $EB, %11111100, $F6, %11111100, $FE, %00001111
frame1988:
	.byte %01000110, $CD, %00000000, $D4, %00110000, $EA, %00110000, $EE, %11111111, $F2, %11111111, $F6, %11111111
frame1989:
	.byte %01000100, $DC, %00000011, $E3, %00000000, $EC, %00110000, $F3, %11110011
frame1990:
	.byte $88
frame1991:
	.byte %01000100, $E2, %00000011, $EA, %11110011, $EB, %11111111, $F3, %11111111
frame1992:
	.byte %01000001, $CC, %00000011
frame1993:
	.byte %01000010, $DB, %00111111, $E3, %11000000
frame1994:
	.byte %01000011, $DB, %00001111, $E2, %00000000, $EC, %00000000
frame1995:
	.byte %01000011, $C5, %11001111, $E2, %00110000, $EA, %11111111
frame1996:
	.byte %01000010, $DA, %00111111, $E3, %11110000
frame1997:
	.byte %01000010, $C5, %11111111, $F4, %00000011
frame1998:
	.byte %01000010, $C4, %00111111, $F4, %00000000
frame1999:
	.byte %01000010, $E2, %00110011, $F4, %00110000
frame2000:
	.byte %01000011, $CC, %00110011, $DA, %00001111, $E4, %00110000
frame2001:
	.byte %01000100, $CE, %11001111, $D6, %11001111, $E1, %11110011, $F4, %00110011
frame2002:
	.byte %01000011, $E1, %11111111, $E4, %00000000, $EC, %00110000
frame2003:
	.byte %01000110, $C4, %11111111, $D4, %00110011, $D6, %11001100, $DA, %00000011, $DB, %00001100, $E2, %11110011
frame2004:
	.byte %01000100, $D9, %00111111, $DA, %00110011, $EC, %00000000, $F4, %00000011
frame2005:
	.byte %01000101, $D9, %11111111, $DA, %00110000, $DB, %00000000, $E3, %11111111, $F4, %00000000
frame2006:
	.byte $88
frame2007:
	.byte %01000001, $DE, %11111100
frame2008:
	.byte %01000011, $DA, %00110011, $E4, %00000011, $EE, %11001100
frame2009:
	.byte %01000101, $D2, %00111111, $DC, %00000000, $DE, %11001100, $E6, %11001111, $F6, %11111100
frame2010:
	.byte %01000100, $D2, %00001111, $D3, %11001111, $E2, %11111111, $E6, %11001100
frame2011:
	.byte %01000001, $F6, %11001100
frame2012:
	.byte %01000010, $D2, %00111100, $DB, %00110000
frame2013:
	.byte %01000011, $D2, %11110000, $D3, %00001111, $FE, %00001100
frame2014:
	.byte %01000101, $C5, %11001111, $CA, %11001111, $CC, %00000011, $D2, %11110011, $F3, %00111111
frame2015:
	.byte %01000101, $CE, %11001100, $D3, %00001100, $DA, %11110011, $DB, %11110000, $F3, %11111111
frame2016:
	.byte %01000001, $CA, %11111111
frame2017:
	.byte %01000011, $C5, %00001111, $D2, %11111111, $DA, %11111111
frame2018:
	.byte %01000010, $CA, %00111111, $D4, %00000011
frame2019:
	.byte %01000101, $D3, %00000000, $D4, %00001111, $DB, %11110011, $F3, %11110011, $F6, %00000000
frame2020:
	.byte %01000100, $CA, %00110011, $CC, %00111111, $EE, %00001100, $FE, %00000000
frame2021:
	.byte %01000010, $DC, %00110000, $F3, %11111111
frame2022:
	.byte %01000011, $CA, %11110011, $CB, %11001111, $D4, %00000011
frame2023:
	.byte %01000001, $D4, %00001111
frame2024:
	.byte %01000100, $CC, %00110011, $D4, %11001111, $DB, %11111111, $EE, %00000000
frame2025:
	.byte %01000101, $CB, %11001100, $CE, %00001100, $D6, %11000000, $E4, %00000000, $F5, %11000000
frame2026:
	.byte %01000010, $C5, %00000011, $CA, %11111111
frame2027:
	.byte %01000001, $C5, %00110011
frame2028:
	.byte %01000011, $C3, %11001111, $C5, %00111111, $E4, %00000011
frame2029:
	.byte %01000010, $D3, %00000011, $DB, %11111100
frame2030:
	.byte %01000010, $CB, %11111100, $D6, %00000000
frame2031:
	.byte %01001001, $C3, %11111111, $C5, %11111111, $CB, %11001100, $CC, %11110011, $CD, %00000011, $D3, %00110011, $DB, %11110000, $DC, %00000000, $DE, %11000000
frame2032:
	.byte %01000001, $CD, %00000000
frame2033:
	.byte %01001010, $CC, %11111111, $CD, %00000011, $D3, %00111100, $D4, %11111111, $DB, %00000011, $DC, %00001100, $DE, %00000000, $E6, %00000000, $F5, %00000000, $FF, %00001100
frame2034:
	.byte %01000100, $CB, %11001111, $CC, %00111111, $DC, %00001111, $E4, %00000000
frame2035:
	.byte %01000101, $CB, %11111111, $CE, %00000000, $D3, %11000000, $E3, %11110011, $F7, %11001111
frame2036:
	.byte %01000111, $CD, %00000000, $D3, %00000000, $DB, %00110011, $DC, %00111111, $E3, %11110000, $F3, %00111111, $F7, %11001100
frame2037:
	.byte %01000110, $C5, %00111111, $C6, %11001111, $D3, %00000011, $D4, %11110011, $E3, %00110011, $EF, %11001111
frame2038:
	.byte %01000100, $D3, %00110011, $E3, %00000011, $E7, %11001111, $EF, %11001100
frame2039:
	.byte %01000111, $D3, %00111111, $DC, %11111111, $DF, %11001100, $E3, %00110011, $E7, %11001100, $EB, %11110000, $FF, %00000000
frame2040:
	.byte %01000100, $D3, %11111111, $D7, %11001111, $F3, %11111111, $F7, %00000000
frame2041:
	.byte %01000110, $C5, %00001111, $C6, %00001111, $E4, %00001111, $EB, %00110011, $EF, %00001100, $FB, %00000011
frame2042:
	.byte %01001010, $C6, %00001100, $CC, %00001111, $CF, %11001111, $D7, %11001100, $DB, %00111111, $DC, %11001100, $E7, %00001100, $EF, %00000000, $F4, %00110000, $FB, %00001111
frame2043:
	.byte %01000101, $CF, %11001100, $DC, %11001111, $E7, %00000000, $F4, %00000000, $FC, %00000011
frame2044:
	.byte %01000101, $DB, %11111111, $DC, %11111111, $DF, %00000000, $E4, %11111100, $F3, %11110011
frame2045:
	.byte %01000110, $C5, %00000011, $C6, %00000000, $C7, %11001111, $D7, %00001100, $F3, %00110011, $FC, %00000000
frame2046:
	.byte %01000011, $CF, %00000000, $D7, %00000000, $EC, %00001100
frame2047:
	.byte %01000010, $C7, %11001100, $FB, %00000011
frame2048:
	.byte %01000011, $C7, %00001100, $CC, %00110011, $EC, %00001111
frame2049:
	.byte %01000010, $E5, %00001100, $EC, %11001111
frame2050:
	.byte %01000101, $C7, %00000000, $DC, %11001111, $E3, %00000011, $E5, %00000000, $EB, %00110000
frame2051:
	.byte %01000011, $E3, %00001111, $E4, %11111111, $EB, %00000000
frame2052:
	.byte %01000011, $DC, %11111111, $E3, %00000000, $EC, %11111111
frame2053:
	.byte %01000101, $CC, %00111111, $D4, %00110011, $DB, %00111111, $E5, %11000000, $F3, %00110000
frame2054:
	.byte %01000101, $D4, %00110000, $DB, %11111111, $E2, %00111111, $E3, %11001111, $EB, %00001100
frame2055:
	.byte %01000011, $DB, %11001111, $E3, %11001100, $EA, %11110011
frame2056:
	.byte %01000011, $DB, %11111111, $E2, %00110011, $EB, %11001100
frame2057:
	.byte %01000010, $DA, %00111111, $E3, %11001111
frame2058:
	.byte %01000110, $C5, %00001111, $DC, %11110011, $E2, %00000011, $E5, %00000000, $EA, %00110011, $FB, %00000000
frame2059:
	.byte %01000010, $CC, %11111111, $EA, %11110011
frame2060:
	.byte %01000010, $D4, %00000000, $E2, %00110011
frame2061:
	.byte %01000100, $C5, %00000011, $CC, %00111111, $DA, %11110011, $E3, %11001100
frame2062:
	.byte %01000001, $EB, %00001100
frame2063:
	.byte %01000010, $DA, %11111111, $DB, %11001111
frame2064:
	.byte %01000001, $DB, %11001100
frame2065:
	.byte $88
frame2066:
	.byte %01000010, $DB, %11111111, $EA, %11111111
frame2067:
	.byte %01000010, $DB, %11110011, $EC, %00111111
frame2068:
	.byte %01000101, $C5, %00000000, $C7, %00001100, $DB, %00110011, $E2, %11110011, $E3, %11000000
frame2069:
	.byte %01000001, $DB, %00001111
frame2070:
	.byte %01000011, $CC, %00110011, $D4, %00110000, $E3, %00000000
frame2071:
	.byte %01000010, $CC, %00000011, $E3, %11000000
frame2072:
	.byte %01000010, $DC, %00110011, $E2, %00110011
frame2073:
	.byte %01000110, $D3, %11110011, $DB, %00110011, $E3, %11001100, $E4, %00110011, $EA, %11110011, $EC, %00110011
frame2074:
	.byte %01000001, $DB, %11110011
frame2075:
	.byte %01000010, $C4, %00111111, $DB, %11111111
frame2076:
	.byte %01000011, $DB, %11001100, $E5, %00110000, $EB, %11001100
frame2077:
	.byte $88
frame2078:
	.byte %01000100, $DB, %11111111, $E2, %00000011, $EA, %00110011, $FB, %00000011
frame2079:
	.byte %01000001, $DA, %11110011
frame2080:
	.byte %01000011, $C4, %11111111, $DA, %00110011, $E3, %11001111
frame2081:
	.byte %01000100, $C5, %00000011, $C7, %11001111, $DA, %00111111, $F3, %00000000
frame2082:
	.byte %01000100, $CC, %00110011, $D3, %11111111, $DA, %11111100, $E3, %11111111
frame2083:
	.byte %01000011, $C5, %00001111, $CC, %00111111, $ED, %00000011
frame2084:
	.byte %01000001, $DA, %11111111
frame2085:
	.byte %01000011, $DA, %11111100, $ED, %00000000, $F3, %00110000
frame2086:
	.byte %01000011, $C7, %00001111, $DA, %00111100, $E3, %11001111
frame2087:
	.byte %01000011, $C5, %00000011, $C7, %00001100, $DA, %00111111
frame2088:
	.byte %01000011, $D4, %00000000, $DA, %11110011, $E3, %11001100
frame2089:
	.byte %01000011, $DA, %11111111, $DC, %11110011, $E2, %00110011
frame2090:
	.byte %01000111, $D3, %11001111, $DB, %11001100, $DC, %11111111, $E4, %00111111, $E5, %00000000, $EA, %11110011, $EB, %00001100
frame2091:
	.byte %01000010, $D3, %11111111, $D4, %00110000
frame2092:
	.byte %01000100, $C5, %00000000, $C7, %00000000, $DB, %11111111, $E4, %11111111
frame2093:
	.byte %01000001, $DB, %11110011
frame2094:
	.byte %01000010, $DB, %00110011, $EC, %00111111
frame2095:
	.byte %01000011, $DB, %00001111, $E3, %11000000, $EA, %11111111
frame2096:
	.byte %01000100, $E2, %11110011, $E3, %00000000, $E5, %11000000, $F3, %00110011
frame2097:
	.byte %01000001, $EC, %11111111
frame2098:
	.byte %01000001, $EB, %00000000
frame2099:
	.byte %01000101, $DB, %11000011, $E2, %00110011, $E3, %11001100, $EB, %00001100, $ED, %00001100
frame2100:
	.byte %01000011, $DB, %11001111, $EA, %11110011, $F3, %00110000
frame2101:
	.byte %01000101, $C5, %00000011, $CC, %00001111, $DB, %11001100, $E5, %00001100, $ED, %00000000
frame2102:
	.byte %01000100, $DB, %11111111, $E2, %00000000, $E5, %00000000, $EA, %00110011
frame2103:
	.byte %01000100, $DD, %00110000, $E3, %11001111, $E5, %00110011, $ED, %00000011
frame2104:
	.byte %01000100, $CC, %00111111, $DA, %00110011, $DD, %00110011, $E6, %00110000
frame2105:
	.byte %01000110, $C5, %00110011, $D4, %00110011, $DD, %00110000, $EB, %11001100, $ED, %00110011, $EE, %00000011
frame2106:
	.byte %01000100, $D4, %11110011, $DA, %00111111, $EE, %00000000, $F4, %00000011
frame2107:
	.byte %01000110, $CC, %11111111, $CD, %00000011, $DD, %00110011, $E6, %00000000, $EB, %00001100, $F4, %00001111
frame2108:
	.byte %01000101, $C5, %00111111, $DA, %00111100, $E5, %11111111, $ED, %00111111, $F5, %00000011
frame2109:
	.byte %01000011, $DD, %11110011, $ED, %11111111, $EE, %11001100
frame2110:
	.byte %01000100, $C5, %11111111, $D4, %11111111, $E2, %00000011, $EE, %00000000
frame2111:
	.byte %01000101, $CD, %00111111, $D5, %00110000, $E3, %11001100, $F4, %00001100, $F5, %00001111
frame2112:
	.byte %01000111, $D2, %11001111, $DA, %00110011, $DD, %11111111, $DE, %00110000, $E6, %00110011, $EE, %00110011, $EF, %00110011
frame2113:
	.byte %01000110, $C6, %00000011, $D2, %00111111, $DA, %11110011, $DB, %11001111, $E3, %00001100, $EF, %00000000
frame2114:
	.byte %01001011, $C6, %00110011, $D2, %11111111, $D3, %11001111, $DA, %11111111, $DB, %11001100, $E2, %00110011, $E3, %00000000, $EA, %11110011, $EB, %00000000, $EF, %11001100, $F6, %00000011
frame2115:
	.byte %01001001, $D5, %11110011, $DB, %00000011, $DE, %00110011, $E6, %11111111, $E7, %11000000, $EE, %11111111, $EF, %00000000, $F5, %11111111, $FB, %00001111
frame2116:
	.byte %01000100, $D3, %00110011, $DE, %11110011, $E7, %00000000, $EA, %11111111
frame2117:
	.byte %01001011, $C6, %00111111, $D3, %11111111, $D4, %11001100, $D6, %00110000, $DB, %00111111, $DC, %11001100, $DE, %11111111, $E2, %11110011, $E4, %11001100, $EC, %11001100, $F6, %00111111
frame2118:
	.byte %01001000, $D4, %11001111, $D5, %11111111, $DB, %00001111, $DF, %00110000, $E2, %11111111, $E7, %00110011, $EF, %00110011, $F4, %00000000
frame2119:
	.byte %01001001, $CD, %11111111, $D4, %00110011, $D6, %11110011, $DC, %11000011, $DF, %00110011, $E4, %11000000, $F3, %00110011, $F6, %11111111, $F7, %00000011
frame2120:
	.byte %01001001, $C6, %00001111, $D4, %11111111, $D5, %11111100, $DC, %00000011, $E4, %00000000, $E7, %11111111, $EF, %11111111, $F5, %11001111, $FD, %00001100
frame2121:
	.byte %01000111, $D5, %11001100, $D6, %11111111, $DF, %11111111, $EB, %00110000, $EC, %11000000, $F7, %00111111, $FE, %00000011
frame2122:
	.byte %01001101, $C6, %00000011, $CE, %11110000, $D5, %11001111, $D7, %11110000, $DB, %00111111, $DC, %00001100, $DD, %11111100, $E3, %00110011, $EB, %00110011, $EC, %00000000, $F3, %11110011, $FD, %00000000, $FE, %00001111
frame2123:
	.byte %01001000, $C6, %00110011, $CE, %11110011, $D5, %11001100, $D7, %11110011, $E3, %00110000, $F3, %00110011, $F7, %11111111, $FF, %00000011
frame2124:
	.byte %01000101, $CE, %11111111, $CF, %00110000, $DB, %00001111, $DC, %00000000, $DD, %11111111
frame2125:
	.byte %01001001, $CD, %11001111, $D4, %00111111, $D5, %11111100, $D7, %11111111, $DB, %00000011, $DC, %00000011, $E3, %00000000, $EB, %00110000, $FF, %00001111
frame2126:
	.byte %01001000, $C6, %11111111, $C7, %00110000, $CC, %00111111, $CD, %11111111, $CF, %11110011, $D4, %00110011, $D5, %11111111, $EB, %00000000
frame2127:
	.byte %01000100, $CF, %11111111, $DB, %00001111, $DC, %00001100, $E2, %00111111
frame2128:
	.byte %01000111, $CC, %11001111, $D4, %11001100, $DC, %11001100, $E2, %00110011, $EA, %11110011, $F3, %00110000, $FB, %00000011
frame2129:
	.byte %01000011, $C7, %11111111, $CB, %00111111, $CC, %11111111
frame2130:
	.byte %01000100, $D3, %00110011, $D4, %11111111, $DB, %00000011, $E4, %00001100
frame2131:
	.byte %01000110, $CB, %11001111, $D3, %00110000, $DC, %11001111, $EA, %00110011, $F3, %00000000, $FD, %00001100
frame2132:
	.byte %01000101, $CA, %00111111, $D3, %11001100, $E2, %00000011, $E4, %11001100, $EA, %00000000
frame2133:
	.byte %01001000, $CB, %11111111, $D2, %11110011, $D3, %11001111, $DB, %00110000, $DC, %11111111, $EC, %00001100, $F2, %11110011, $F5, %11111111
frame2134:
	.byte %01000111, $CA, %11001111, $D2, %00110000, $D3, %11111111, $DB, %00001100, $EC, %11001100, $F4, %00001100, $FB, %00000000
frame2135:
	.byte %01000010, $CA, %11111111, $D2, %00111100
frame2136:
	.byte %01000001, $DA, %11110011
frame2137:
	.byte %01000011, $CA, %11001111, $D2, %00110000, $DA, %11111111
frame2138:
	.byte %01001001, $CA, %00001111, $D2, %00110011, $D3, %11001111, $DB, %00000000, $DC, %11001111, $EC, %00000000, $F4, %00000000, $F5, %11001111, $FB, %00000011
frame2139:
	.byte %01001001, $CA, %00111111, $CB, %11001111, $D2, %11111111, $D3, %00001100, $DB, %00000011, $E4, %00000000, $EA, %00110000, $F2, %11111111, $FD, %00000000
frame2140:
	.byte %01001000, $CA, %11111111, $CB, %00110000, $D3, %00110011, $D4, %11001111, $DB, %00001111, $DC, %00001100, $E2, %00110011, $EA, %11110011
frame2141:
	.byte %01001010, $C4, %11001111, $CB, %11111111, $CC, %11001100, $D3, %11111111, $D4, %11001100, $DC, %00000000, $E5, %11001100, $EA, %11111111, $ED, %11111100, $F3, %00110000
frame2142:
	.byte %01000111, $C4, %00111111, $CC, %00110011, $D4, %00110011, $DB, %00111111, $DC, %00000011, $E2, %00111111, $ED, %11001100
frame2143:
	.byte %01001011, $C4, %11111111, $C5, %11001111, $CC, %11111111, $CD, %11001100, $D4, %11111111, $D5, %11001100, $DB, %00001111, $DC, %00000000, $DD, %11001100, $E2, %11111111, $F3, %00110011
frame2144:
	.byte %01000111, $C5, %11111111, $CD, %00000011, $D5, %11000000, $DC, %00001100, $E5, %00000000, $EB, %00110000, $F5, %11001100
frame2145:
	.byte %01001011, $CD, %00111111, $CE, %11001100, $D5, %00110011, $DB, %00111111, $DC, %00000011, $DD, %00000000, $E3, %00110000, $EB, %00110011, $ED, %11000000, $F5, %00001100, $FB, %00001111
frame2146:
	.byte %01000111, $CD, %11111111, $CE, %11000011, $D5, %00111111, $D6, %11001100, $E3, %00110011, $ED, %00000000, $FE, %00001100
frame2147:
	.byte %01000110, $CE, %00111111, $D5, %11111111, $DC, %00001111, $DE, %11111100, $E6, %11111100, $F3, %11110011
frame2148:
	.byte %01001000, $D6, %11000011, $DC, %00000011, $DD, %00001100, $E3, %11110011, $E6, %11001100, $EB, %11111111, $F3, %11111111, $F5, %00000000
frame2149:
	.byte %01001010, $CE, %11001111, $D6, %11001100, $DC, %00000000, $DD, %00000000, $DE, %11111111, $E3, %00110011, $E6, %11111100, $EB, %00110011, $F3, %11110011, $F5, %00001100
frame2150:
	.byte %01000111, $CD, %00111111, $D5, %00110011, $D6, %11111111, $E3, %00110000, $E6, %11111111, $ED, %11000000, $F3, %00110011
frame2151:
	.byte %01001010, $CD, %00001100, $CE, %11111111, $D5, %11001100, $DB, %00001111, $DD, %11001100, $E3, %00000000, $E5, %11001100, $EB, %00000000, $ED, %11001100, $FB, %00000011
frame2152:
	.byte %01001011, $CC, %00110011, $CD, %11111111, $D4, %00110011, $D5, %11111111, $DB, %00000011, $DC, %00000011, $DD, %11111111, $E2, %00110011, $ED, %11111100, $F3, %00110000, $FE, %00001111
frame2153:
	.byte %01001001, $CC, %11001111, $D4, %11001100, $DB, %00001100, $DC, %00001100, $E5, %11111111, $EA, %11110011, $ED, %11111111, $F3, %00000000, $F5, %11001111
frame2154:
	.byte %01001100, $CB, %00111111, $CC, %11111111, $D3, %00110011, $D4, %11111111, $DA, %00111111, $DB, %00000011, $DC, %11001111, $E2, %00000000, $E4, %00001100, $EA, %00110000, $EC, %11000000, $FB, %00000000
frame2155:
	.byte %01000101, $CB, %11001100, $D3, %00111100, $E4, %11001100, $EC, %11001100, $F2, %11110011
frame2156:
	.byte %01000011, $CB, %11001111, $D3, %11001100, $DC, %11111111
frame2157:
	.byte %01000011, $CA, %00111111, $CB, %11111111, $DB, %00000000
frame2158:
	.byte %01000100, $D2, %11110011, $D3, %11001111, $DB, %00001100, $EA, %00000000
frame2159:
	.byte %01000001, $E2, %00000011
frame2160:
	.byte %01000001, $CA, %11111111
frame2161:
	.byte %01000011, $CA, %11001111, $D2, %00110011, $D3, %11111111
frame2162:
	.byte %01000100, $CA, %11111111, $D2, %00111100, $DA, %11111111, $FB, %00000011
frame2163:
	.byte %01000001, $EC, %00001100
frame2164:
	.byte %01000001, $EC, %00000000
frame2165:
	.byte %01000010, $E2, %00110011, $FE, %00001100
frame2166:
	.byte %01000100, $DC, %11001111, $E4, %00001100, $F2, %11111111, $F5, %00001111
frame2167:
	.byte %01000011, $DB, %00111100, $EA, %00110011, $F5, %00001100
frame2168:
	.byte %01000111, $D2, %00110000, $DB, %00001100, $E2, %00111111, $E4, %00000000, $F3, %00110000, $F6, %11001111, $FE, %00000000
frame2169:
	.byte %01000111, $D2, %00110011, $D3, %11001111, $DB, %00000000, $DC, %00001100, $E2, %00110011, $F5, %00000000, $FB, %00001111
frame2170:
	.byte %01000101, $D2, %11110011, $ED, %11001100, $F3, %00110011, $F6, %00001111, $FF, %00001100
frame2171:
	.byte %01000101, $DB, %00000011, $E2, %11110011, $E5, %11001111, $F3, %11110011, $F6, %00001100
frame2172:
	.byte %01000111, $DC, %00000011, $E2, %11111111, $E5, %11001100, $EA, %11110011, $ED, %00001100, $FC, %00000011, $FF, %00000000
frame2173:
	.byte %01000011, $DC, %11000011, $EA, %11111111, $F7, %11001111
frame2174:
	.byte %01000011, $DB, %00110011, $DD, %11001111, $F3, %11111111
frame2175:
	.byte $88
frame2176:
	.byte %01000001, $ED, %00000000
frame2177:
	.byte %01000100, $D2, %11111111, $DB, %00110000, $DC, %11001111, $F3, %11110011
frame2178:
	.byte %01000011, $D2, %00111111, $E3, %00000011, $ED, %00001100
frame2179:
	.byte %01000101, $D3, %11111111, $DB, %00111100, $DC, %11111111, $DD, %11111111, $F7, %00111111
frame2180:
	.byte %01001010, $DA, %11110011, $DB, %00001100, $DC, %00111111, $E3, %00000000, $E4, %00001100, $ED, %11001100, $F3, %00110011, $F6, %00001111, $F7, %00001111, $FC, %00000000
frame2181:
	.byte %01000101, $D2, %11111111, $DB, %11001111, $E4, %00000000, $E5, %11001111, $F3, %00110000
frame2182:
	.byte %01000011, $E4, %00000011, $E5, %11111111, $EA, %00111111
frame2183:
	.byte %01000111, $DA, %00110011, $DC, %11111111, $E2, %00111111, $ED, %11111111, $EF, %00110011, $F6, %00000011, $F7, %00000000
frame2184:
	.byte %01001110, $C7, %00110011, $DA, %00111111, $DB, %11111111, $DC, %11001111, $E3, %00001100, $E4, %00001100, $E7, %00001111, $EA, %00110011, $EE, %00111111, $EF, %00000000, $F2, %11110011, $F3, %00000000, $F5, %00001100, $F6, %00000000
frame2185:
	.byte %01000111, $C7, %00000000, $E2, %00110011, $E4, %11001100, $E6, %00110011, $E7, %11001111, $EE, %00000000, $F5, %00000000
frame2186:
	.byte %01000111, $C6, %00111111, $CF, %11110000, $DC, %11111111, $E6, %00001100, $E7, %00111111, $EC, %00001100, $ED, %00000011
frame2187:
	.byte %01001000, $CE, %11110011, $CF, %00110000, $D7, %11110011, $E3, %11001100, $E4, %11001111, $E5, %00110011, $E7, %00001111, $ED, %00000000
frame2188:
	.byte %01001010, $C6, %00001111, $CE, %11110000, $CF, %00000000, $D7, %00110011, $E5, %00000000, $E6, %00001111, $E7, %00000000, $EC, %00000000, $F3, %00110000, $FC, %00000011
frame2189:
	.byte %01000111, $C6, %00000011, $CE, %00110000, $D7, %00000000, $DF, %11110011, $E3, %00000011, $E4, %00110011, $E5, %00001100
frame2190:
	.byte %01001010, $CD, %11110011, $CE, %00000000, $D6, %00110011, $DC, %00111111, $DF, %00110011, $E4, %00000011, $E6, %00000011, $EC, %11000000, $F2, %11111111, $FC, %00001111
frame2191:
	.byte %01001101, $C6, %00000000, $CD, %00110011, $D6, %00110000, $DA, %11111111, $DC, %11111111, $DE, %11110011, $DF, %00000000, $E3, %00000000, $E4, %00000000, $E5, %00001111, $E6, %00000000, $EC, %00000000, $F3, %11110000
frame2192:
	.byte %01000011, $D6, %00000000, $DC, %11001111, $DE, %00110011
frame2193:
	.byte %01001000, $C5, %00110011, $CD, %00000011, $DC, %11111111, $DE, %00110000, $E2, %00111111, $E4, %00001100, $E5, %00110011, $EA, %11110011
frame2194:
	.byte %01001000, $D5, %00110011, $DB, %00111111, $DD, %11110011, $DE, %00000000, $E2, %11111111, $E5, %00000011, $F3, %11110011, $F4, %00110000
frame2195:
	.byte %01000110, $C5, %00000011, $CC, %00111111, $CD, %00000000, $D5, %00110000, $DF, %11000000, $FC, %00000011
frame2196:
	.byte %01000110, $C5, %00000000, $DB, %11111111, $DF, %11001100, $E4, %00001111, $E5, %00000000, $F3, %11111111
frame2197:
	.byte %01001010, $CF, %00001100, $D4, %11110011, $D5, %00000000, $D7, %00001100, $DD, %00110000, $DF, %11111100, $E2, %00111111, $EA, %11110000, $F4, %00000000, $FC, %00001111
frame2198:
	.byte %01000110, $CF, %11000000, $D7, %11001100, $DB, %11001111, $EB, %00110000, $F7, %11001100, $FF, %00001100
frame2199:
	.byte %01000110, $C4, %00111111, $CC, %00110011, $DE, %11000000, $E4, %00000011, $E7, %00001100, $EF, %11000000
frame2200:
	.byte %01000110, $D7, %11111111, $DB, %11111111, $DF, %11111111, $E2, %00110011, $E7, %11001100, $FF, %00001111
frame2201:
	.byte %01001000, $CF, %11111100, $D4, %00110000, $DC, %11110011, $E3, %00001100, $EA, %11111100, $EF, %00000000, $F7, %11111111, $FC, %00000011
frame2202:
	.byte %01001000, $C4, %00110011, $C7, %00001100, $DD, %00000000, $E2, %00000011, $E7, %11001111, $E9, %11110011, $EF, %00110000, $F4, %00110000
frame2203:
	.byte %01000111, $CC, %00000011, $DA, %00111111, $DE, %11110000, $E7, %11111111, $EA, %11110000, $F3, %11110011, $FE, %00001100
frame2204:
	.byte %01001000, $C7, %11001100, $CC, %00000000, $CE, %11000000, $D6, %11001100, $DE, %11111100, $E4, %00000000, $F6, %11001100, $FE, %00001111
frame2205:
	.byte %01000111, $C4, %00111111, $C6, %00000011, $C7, %11001111, $CF, %11111111, $E6, %00001100, $EA, %11111100, $FC, %00000000
frame2206:
	.byte %01001011, $C4, %00001111, $C7, %11111111, $CE, %00000000, $D3, %11110011, $DA, %11111111, $DC, %11110000, $E2, %00000000, $E6, %11001100, $EE, %11000000, $EF, %00000000, $F4, %00110011
frame2207:
	.byte %01001001, $C5, %00001100, $D4, %00000000, $DD, %11000000, $E1, %00111111, $E3, %00001111, $E9, %11110000, $EA, %11110011, $F4, %00000000, $F7, %11110011
frame2208:
	.byte %01000100, $C5, %00001111, $D6, %11111100, $DE, %11111111, $F6, %11111111
frame2209:
	.byte %01000110, $C6, %00001111, $CE, %11000000, $DA, %11001111, $DC, %00110000, $EE, %11110000, $F7, %11111111
frame2210:
	.byte %01000100, $C6, %11001111, $D6, %11111111, $E6, %11001111, $FD, %00001100
frame2211:
	.byte %01000100, $C5, %11001111, $E3, %00000011, $E6, %11111111, $FB, %00000011
frame2212:
	.byte %01001000, $CB, %00111111, $CE, %11001100, $DA, %11111111, $DD, %11110000, $E1, %00110011, $E7, %00111111, $E8, %11110011, $F5, %11000000
frame2213:
	.byte %01000111, $CB, %00110011, $E1, %00000011, $E2, %00001100, $E9, %11111100, $ED, %11000000, $EE, %00110000, $F5, %11001100
frame2214:
	.byte %01000101, $D3, %00110011, $D5, %11000000, $DB, %11110011, $DD, %11111100, $F3, %00111111
frame2215:
	.byte %01000111, $C5, %00001111, $C6, %11111111, $CE, %11111100, $EA, %11110000, $ED, %11001100, $F3, %00110011, $F5, %11111100
frame2216:
	.byte %01000110, $C5, %00111111, $CE, %11111111, $D5, %11001100, $E5, %00001100, $E7, %00001111, $EF, %00110000
frame2217:
	.byte %01000110, $D3, %00110000, $D9, %00111111, $DC, %00000000, $E5, %11001100, $EB, %00000000, $FD, %00001111
frame2218:
	.byte %01000011, $E7, %00000011, $EE, %11110000, $EF, %11110000
frame2219:
	.byte %01000110, $D9, %11111111, $DB, %00110011, $E1, %00000000, $E3, %00000000, $E6, %00111111, $EF, %11000000
frame2220:
	.byte %01000101, $D5, %11111100, $DD, %11111111, $E6, %00001111, $E9, %11111111, $EA, %11110011
frame2221:
	.byte %01001011, $C4, %11001111, $C5, %11111111, $CD, %11000000, $E0, %00111111, $E5, %00001100, $E7, %00000000, $E8, %11110000, $EF, %11110000, $F3, %00000011, $F5, %11111111, $FB, %00000000
frame2222:
	.byte %01000101, $C3, %00111111, $CB, %00000011, $CD, %11001100, $E2, %00001111, $ED, %11110011
frame2223:
	.byte %01000010, $D9, %11001111, $F4, %00001100
frame2224:
	.byte %01000110, $CB, %00000000, $D5, %11111111, $DB, %00000011, $E9, %11110011, $EA, %11111111, $F3, %00000000
frame2225:
	.byte %01000100, $DB, %00000000, $E5, %00001111, $E6, %00000011, $E7, %00001100
frame2226:
	.byte %01000100, $DF, %11001111, $E0, %00110011, $E9, %11111111, $F4, %11001100
frame2227:
	.byte %01000110, $C4, %11111111, $D3, %00000000, $DB, %00000011, $DC, %00001100, $DF, %11111111, $EF, %00110000
frame2228:
	.byte %01000101, $C3, %11111111, $D9, %11111111, $E0, %00000011, $E8, %11111100, $EA, %11111100
frame2229:
	.byte %01000011, $DC, %00000000, $E7, %11001100, $FC, %00001100
frame2230:
	.byte %01000001, $DC, %11000000
frame2231:
	.byte %01000010, $DB, %00000000, $E7, %11001111
frame2232:
	.byte %01000010, $E1, %00001100, $ED, %11110000
frame2233:
	.byte %01000001, $DB, %00110000
frame2234:
	.byte %01000010, $CC, %00001100, $E9, %11111100
frame2235:
	.byte %01000100, $E5, %11111111, $E8, %11110000, $E9, %11110000, $EF, %00001100
frame2236:
	.byte %01000100, $CB, %00000011, $D8, %00111111, $DC, %11110000, $E7, %11111111
frame2237:
	.byte $88
frame2238:
	.byte %01000001, $F4, %11000000
frame2239:
	.byte %01000001, $E8, %11111100
frame2240:
	.byte %01000010, $D8, %11111111, $E6, %00001111
frame2241:
	.byte $88
frame2242:
	.byte %01000011, $CD, %11001111, $ED, %11000000, $EF, %11001100
frame2243:
	.byte %01000001, $ED, %11110000
frame2244:
	.byte %01000001, $E5, %00111111
frame2245:
	.byte %01000001, $E0, %00000000
frame2246:
	.byte %01000001, $CB, %00000000
frame2247:
	.byte %01000001, $E8, %11111111
frame2248:
	.byte $88
frame2249:
	.byte $88
frame2250:
	.byte %01000011, $CD, %11001100, $EA, %11111111, $EF, %00001100
frame2251:
	.byte $88
frame2252:
	.byte $88
frame2253:
	.byte $88
frame2254:
	.byte %01000001, $E6, %00000011
frame2255:
	.byte %01000001, $E5, %00001111
frame2256:
	.byte $88
frame2257:
	.byte %01000001, $E6, %00000000
frame2258:
	.byte %01000001, $D2, %11110011
frame2259:
	.byte $88
frame2260:
	.byte $88
frame2261:
	.byte $88
frame2262:
	.byte %01000010, $D2, %11111111, $DC, %11111100
frame2263:
	.byte %01000100, $E1, %00001111, $E5, %00111111, $E6, %00000011, $EA, %11111100
frame2264:
	.byte %01000011, $DC, %11001100, $E4, %00001100, $E6, %00001111
frame2265:
	.byte %01000100, $CB, %00000011, $CD, %11001111, $D5, %11111100, $E2, %00111111
frame2266:
	.byte $88
frame2267:
	.byte %01000010, $E1, %00001100, $E6, %00000011
frame2268:
	.byte %01000011, $D8, %00111111, $E0, %00000011, $E4, %00000000
frame2269:
	.byte %01000001, $E8, %11111100
frame2270:
	.byte %01000010, $E2, %00001111, $E5, %00001111
frame2271:
	.byte %01000010, $D5, %11111111, $DC, %11000000
frame2272:
	.byte $88
frame2273:
	.byte %01000011, $DC, %11110000, $E7, %11001111, $FC, %00000000
frame2274:
	.byte %01000001, $F4, %00000000
frame2275:
	.byte %01000110, $CB, %00000000, $CD, %11001100, $D8, %11111111, $DC, %11000000, $E9, %11111100, $EF, %00000000
frame2276:
	.byte %01000110, $CC, %00000000, $E9, %11111111, $ED, %11110011, $EE, %11111100, $EF, %11110000, $F3, %00000011
frame2277:
	.byte %01000001, $D5, %11111100
frame2278:
	.byte %01000001, $E1, %00000000
frame2279:
	.byte %01000001, $D9, %11001111
frame2280:
	.byte %01000010, $E7, %11001100, $F4, %00001100
frame2281:
	.byte %01000010, $E8, %11111111, $EF, %11110011
frame2282:
	.byte %01000001, $CC, %00001100
frame2283:
	.byte %01000001, $D5, %11111111
frame2284:
	.byte %01000010, $E9, %11110011, $FB, %00000011
frame2285:
	.byte %01000011, $DB, %11110000, $EE, %11110000, $F4, %00000000
frame2286:
	.byte %01000001, $EA, %11110000
frame2287:
	.byte %01000011, $CB, %00000011, $E0, %00001111, $F3, %00000000
frame2288:
	.byte %01000101, $CD, %11001111, $D9, %11111111, $E2, %11001111, $E8, %11110011, $F3, %00110000
frame2289:
	.byte %01000010, $E0, %00111111, $EF, %11110000
frame2290:
	.byte %01000100, $DB, %00110000, $E5, %00111111, $E8, %11110000, $E9, %11110000
frame2291:
	.byte %01000001, $DB, %00110011
frame2292:
	.byte %01000100, $CB, %00001111, $E5, %11111111, $E6, %00001111, $EF, %00110000
frame2293:
	.byte %01000001, $E9, %11110011
frame2294:
	.byte $88
frame2295:
	.byte %01000100, $CB, %00000011, $E5, %00001111, $E7, %00001100, $EF, %11110000
frame2296:
	.byte $88
frame2297:
	.byte %01000010, $DB, %11110011, $E6, %00000011
frame2298:
	.byte $88
frame2299:
	.byte $88
frame2300:
	.byte %01000010, $D5, %11111100, $DB, %11110000
frame2301:
	.byte %01000001, $E9, %11111111
frame2302:
	.byte %01000010, $E2, %00001111, $ED, %11111111
frame2303:
	.byte %01000001, $ED, %11111100
frame2304:
	.byte %01000010, $CD, %11001100, $EF, %11110011
frame2305:
	.byte $88
frame2306:
	.byte %01000011, $CC, %00000000, $E7, %00000000, $EE, %11111100
frame2307:
	.byte %01000001, $EA, %11110011
frame2308:
	.byte %01000011, $D5, %11111111, $DF, %11001111, $EE, %11111111
frame2309:
	.byte %01000010, $E8, %11110011, $EE, %11111100
frame2310:
	.byte %01000001, $EE, %11111111
frame2311:
	.byte %01000001, $EE, %11111100
frame2312:
	.byte %01000001, $EF, %11111111
frame2313:
	.byte %01000001, $DF, %11111111
frame2314:
	.byte %01000001, $EA, %11110000
frame2315:
	.byte %01000011, $D5, %11111100, $DB, %00110011, $E8, %11110000
frame2316:
	.byte %01000101, $DC, %00000000, $E3, %00000011, $ED, %11111111, $EE, %11110000, $EF, %11110011
frame2317:
	.byte %01000100, $CC, %00001100, $CD, %00001100, $E2, %11001111, $E6, %00001111
frame2318:
	.byte %01000001, $CB, %00110011
frame2319:
	.byte %01000001, $DC, %11000000
frame2320:
	.byte %01000011, $CD, %11001100, $E2, %00001111, $EF, %11110000
frame2321:
	.byte $88
frame2322:
	.byte %01000011, $CC, %00000000, $D3, %00000011, $ED, %11111100
frame2323:
	.byte %01000011, $D5, %11001100, $ED, %11110000, $FB, %00000000
frame2324:
	.byte %01000010, $DC, %00000000, $E8, %11110011
frame2325:
	.byte %01000010, $CD, %00001100, $E8, %11111111
frame2326:
	.byte %01000010, $E3, %00000000, $E6, %00111111
frame2327:
	.byte %01000100, $CB, %00000011, $D3, %00000000, $E7, %00000011, $EE, %11000000
frame2328:
	.byte %01000001, $E5, %11001111
frame2329:
	.byte %01000001, $EF, %00110000
frame2330:
	.byte %01000100, $CD, %00000000, $E2, %11001111, $EF, %00000000, $F3, %00000000
frame2331:
	.byte %01000011, $D5, %11000000, $E6, %11111111, $F2, %11110011
frame2332:
	.byte %01000011, $D9, %00111111, $E7, %00001111, $EE, %00000000
frame2333:
	.byte %01000011, $DB, %00110000, $E2, %00001111, $EA, %00110000
frame2334:
	.byte %01000001, $FC, %00001100
frame2335:
	.byte %01000001, $DB, %11110000
frame2336:
	.byte %01000001, $DC, %11000000
frame2337:
	.byte %01000100, $CE, %11001111, $D2, %11110011, $E0, %11111111, $E2, %00001100
frame2338:
	.byte %01000101, $C4, %11001111, $D5, %11000011, $DC, %00000000, $ED, %00110000, $F7, %11111100
frame2339:
	.byte %01000010, $C3, %00111111, $DC, %11000000
frame2340:
	.byte %01000101, $C4, %00001111, $DC, %00000000, $E1, %11000000, $E7, %00111111, $F6, %11111100
frame2341:
	.byte %01000011, $DB, %00110000, $DC, %11000000, $F4, %11000000
frame2342:
	.byte %01000100, $CE, %11001100, $D5, %11000000, $DA, %11001111, $E1, %00110000
frame2343:
	.byte %01000100, $C6, %11001111, $DB, %11110000, $DD, %11111100, $E1, %00110011
frame2344:
	.byte %01000111, $C5, %00111111, $D2, %11111111, $D9, %11111111, $DA, %11001100, $DC, %00000000, $E1, %11110011, $E9, %11110011
frame2345:
	.byte %01000100, $DB, %11110011, $E1, %00110011, $E2, %00000000, $F7, %11110000
frame2346:
	.byte %01000100, $DA, %11001111, $DC, %11000000, $E1, %11110011, $F6, %11110011
frame2347:
	.byte %01000101, $C5, %00001111, $D3, %00110000, $DA, %00001111, $DC, %00000000, $E1, %00110011
frame2348:
	.byte %01000011, $D5, %11001100, $E1, %00111111, $ED, %11110000
frame2349:
	.byte %01000100, $CA, %00111111, $DA, %00110011, $DC, %11000000, $EE, %00001100
frame2350:
	.byte %01000101, $C4, %00000000, $C6, %11001100, $E2, %00000011, $E5, %11001100, $E7, %11111111
frame2351:
	.byte %01000111, $C5, %00000011, $CE, %11000000, $DA, %00111111, $DB, %11000011, $DC, %00000000, $ED, %11000000, $EE, %00000000
frame2352:
	.byte %01000011, $C3, %00110011, $DA, %11111111, $DB, %00000000
frame2353:
	.byte %01000101, $C5, %00000000, $D5, %00001100, $E2, %00001111, $F4, %00000000, $FC, %00000000
frame2354:
	.byte %01000100, $C6, %00001100, $CE, %11001100, $D3, %00110011, $DB, %00000011
frame2355:
	.byte %01000110, $CD, %11000000, $D5, %00000000, $DB, %00110011, $E3, %00000011, $EE, %00000011, $F2, %11111111
frame2356:
	.byte %01000110, $CD, %00000000, $CE, %11000000, $D5, %11000000, $DB, %00111111, $EE, %00000000, $F3, %00110000
frame2357:
	.byte %01000011, $CE, %11110000, $DB, %11110011, $EF, %00000011
frame2358:
	.byte %01001000, $C3, %00111111, $C6, %11001100, $CE, %11111100, $D3, %11110011, $D5, %00000000, $DB, %11111111, $F7, %11000000, $FB, %00000011
frame2359:
	.byte %01000110, $C6, %11000000, $CA, %11111111, $E3, %00001111, $EA, %11110000, $EE, %00110000, $F6, %11111111
frame2360:
	.byte %01000001, $DD, %11001100
frame2361:
	.byte %01000101, $C6, %11001100, $DC, %00110000, $E3, %11001111, $E5, %00001100, $E9, %11111111
frame2362:
	.byte %01000110, $C3, %11111111, $C4, %00000011, $C6, %00001100, $DD, %11000000, $F3, %00110011, $FD, %00001100
frame2363:
	.byte %01001011, $CB, %00111111, $D6, %11111100, $DD, %00000000, $E1, %11111111, $E4, %00000011, $E5, %00000000, $EE, %00111100, $EF, %00001111, $F3, %11110011, $F5, %11111100, $FB, %00001111
frame2364:
	.byte %01000011, $CE, %11001100, $DC, %11110000, $F5, %11001100
frame2365:
	.byte %01001000, $C4, %00001111, $C6, %11001100, $D6, %11001100, $DC, %11110011, $DD, %11000000, $DE, %11001100, $E6, %11001100, $F7, %00000000
frame2366:
	.byte %01000011, $CB, %11111111, $D6, %00001100, $EB, %00110000
frame2367:
	.byte %01000111, $C4, %00111111, $C5, %00000011, $D4, %00110000, $DD, %00000000, $DE, %11111100, $E4, %00110011, $E6, %00000000
frame2368:
	.byte %01001000, $CE, %11000000, $D4, %00000000, $DE, %00111100, $E4, %00111111, $E6, %00000011, $EA, %11110011, $EC, %00000011, $ED, %00000000
frame2369:
	.byte %01000011, $DE, %00110000, $E6, %00110011, $E7, %11001100
frame2370:
	.byte %01000101, $CC, %00000011, $DE, %00111100, $F7, %00110000, $FC, %00000011, $FD, %00000000
frame2371:
	.byte %01000111, $DD, %00110000, $DE, %11111100, $DF, %11001111, $E7, %11111100, $EE, %00110000, $F7, %00000000, $FD, %00001100
frame2372:
	.byte %01000101, $C6, %00001100, $CC, %00110011, $D4, %00110000, $E6, %00111111, $E7, %00110000
frame2373:
	.byte %01000111, $C6, %00000000, $CE, %00000000, $D3, %11111111, $DE, %11001100, $E7, %00000000, $F7, %00110000, $FF, %00000011
frame2374:
	.byte %01000111, $D6, %00000000, $DC, %11111111, $DE, %11000000, $E6, %00001111, $EE, %00000000, $F5, %11000000, $FD, %00000000
frame2375:
	.byte %01000100, $C4, %11111111, $E6, %11001111, $EF, %11001111, $F5, %00000000
frame2376:
	.byte %01000100, $C5, %00001111, $DE, %11110000, $E6, %11001100, $E7, %11000000
frame2377:
	.byte %01000110, $CF, %11111100, $D7, %11001111, $DE, %00000000, $E3, %00001111, $E4, %11111111, $EF, %11001100
frame2378:
	.byte %01000011, $DF, %11111100, $E5, %00000011, $EF, %11111100
frame2379:
	.byte %01000101, $C7, %11111100, $DD, %00000000, $DF, %00111100, $E7, %00000011, $EF, %11001100
frame2380:
	.byte %01000100, $C7, %11001100, $CF, %11001100, $DD, %00110000, $E2, %00111111
frame2381:
	.byte %01000110, $CC, %00111111, $D7, %11001100, $DD, %11110000, $E7, %00110011, $EC, %00001111, $F6, %11111100
frame2382:
	.byte %01000110, $CF, %11000000, $DD, %00110000, $E2, %00110011, $EF, %11000000, $FC, %00001111, $FF, %00001111
frame2383:
	.byte %01000101, $D4, %11110000, $DF, %00110000, $E2, %00000011, $E6, %00001100, $F6, %11000000
frame2384:
	.byte %01000111, $C7, %11000000, $DF, %00001100, $E2, %00000000, $E5, %00001111, $EF, %11000011, $F7, %00111100, $FE, %00001100
frame2385:
	.byte %01000111, $C5, %00111111, $CC, %11111111, $CF, %00000000, $DF, %11000000, $E3, %00001100, $E6, %00000000, $EF, %00000011
frame2386:
	.byte %01000101, $C7, %00000000, $D4, %11110011, $D7, %00000000, $E7, %00111111, $F7, %00110000
frame2387:
	.byte %01000011, $DF, %00000000, $E5, %00111111, $E7, %11111111
frame2388:
	.byte %01000001, $EA, %11111111
frame2389:
	.byte %01000100, $DD, %00110011, $E7, %11111100, $EF, %00001111, $F6, %00000000
frame2390:
	.byte %01000101, $CD, %00000011, $E5, %11111111, $EF, %00001100, $F7, %00000000, $FE, %00000000
frame2391:
	.byte %01000001, $E6, %00000011
frame2392:
	.byte $88
frame2393:
	.byte $88
frame2394:
	.byte $88
frame2395:
	.byte %01000010, $C6, %00000011, $E1, %11110011
frame2396:
	.byte $88
frame2397:
	.byte $88
frame2398:
	.byte %01000001, $CC, %00111111
frame2399:
	.byte %01000001, $DA, %11001111
frame2400:
	.byte $88
frame2401:
	.byte $88
frame2402:
	.byte $88
frame2403:
	.byte %01000010, $DA, %00001111, $E7, %11110000
frame2404:
	.byte %01000011, $C5, %11111111, $D9, %00111111, $F4, %11000000
frame2405:
	.byte %01000001, $E7, %11000000
frame2406:
	.byte %01000001, $C7, %00000011
frame2407:
	.byte %01000001, $F4, %11110000
frame2408:
	.byte %01000011, $C6, %00001111, $D4, %11111111, $E7, %11110000
frame2409:
	.byte $88
frame2410:
	.byte %01000001, $EC, %00001100
frame2411:
	.byte %01000010, $D5, %00110000, $E5, %00111111
frame2412:
	.byte $88
frame2413:
	.byte $88
frame2414:
	.byte %01000001, $C7, %00000000
frame2415:
	.byte %01000001, $F3, %11111111
frame2416:
	.byte $88
frame2417:
	.byte %01000010, $C6, %00000011, $CC, %11111111
frame2418:
	.byte %01000001, $EC, %00000000
frame2419:
	.byte $88
frame2420:
	.byte %01000010, $E2, %11000000, $E7, %11000000
frame2421:
	.byte %01000101, $CD, %00000000, $D5, %00110011, $DD, %11110011, $E2, %11110000, $F5, %00110011
frame2422:
	.byte %01000011, $DB, %11001111, $DD, %00110011, $F4, %11111100
frame2423:
	.byte %01000111, $E5, %00001111, $E7, %11001100, $EB, %00110011, $EF, %11001100, $F4, %11111111, $F7, %00110000, $FD, %00000011
frame2424:
	.byte %01000011, $DA, %00001100, $DD, %11110011, $E3, %00000000
frame2425:
	.byte %01000101, $E4, %11001111, $E7, %11000000, $EB, %11110011, $EF, %00001100, $F7, %11110000
frame2426:
	.byte %01000101, $D9, %00110011, $DD, %11111111, $DE, %00110000, $E5, %00111111, $E6, %00000000
frame2427:
	.byte %01001000, $C5, %00111111, $CD, %00110000, $D5, %11111111, $DA, %00000000, $E1, %11111111, $E7, %11001100, $EF, %00000000, $F7, %11000000
frame2428:
	.byte %01000011, $D9, %00111111, $E7, %00000000, $FF, %00001100
frame2429:
	.byte %01000110, $CD, %11110011, $D9, %00110011, $DB, %00001111, $DE, %11110000, $E3, %00110000, $E5, %00001111
frame2430:
	.byte %01000110, $DB, %00001100, $DE, %11110011, $E4, %00001100, $EB, %11111111, $EC, %00110000, $F5, %11111111
frame2431:
	.byte %01001001, $C5, %00110011, $C6, %00000000, $CD, %11111111, $D2, %11001111, $D6, %00110011, $E2, %11000000, $F7, %00000000, $FD, %00001111, $FF, %00000000
frame2432:
	.byte %01000100, $CE, %00110000, $DE, %11111111, $DF, %00000011, $EC, %11110000
frame2433:
	.byte %01001011, $C5, %11111111, $CE, %00110011, $D2, %00111111, $DB, %00000000, $DC, %11001111, $DE, %00111111, $E2, %00000000, $E3, %11110011, $E4, %00000000, $EC, %11110011, $ED, %11000000
frame2434:
	.byte %01001000, $D2, %00001111, $D3, %11001111, $D6, %11111111, $D9, %11110011, $ED, %11110000, $EE, %00110000, $F6, %00110011, $FE, %00000011
frame2435:
	.byte %01001100, $C6, %00110000, $CE, %11111111, $D1, %00111111, $D2, %00001100, $D3, %00001111, $D7, %11110000, $DC, %00001100, $DF, %00001111, $E3, %11111100, $E4, %00110000, $E5, %00001100, $EC, %11111111
frame2436:
	.byte %01001000, $C6, %11110011, $D2, %00000011, $D7, %11110011, $DD, %11001111, $DE, %11111111, $DF, %00000011, $E5, %00000000, $EA, %11110011
frame2437:
	.byte %01001111, $C6, %11111111, $C7, %00110000, $CF, %00110011, $D3, %00000000, $D4, %11001111, $D7, %11111111, $DA, %00110000, $DC, %00000000, $DE, %00111111, $E3, %11001100, $E4, %11110011, $ED, %11110011, $EE, %11110000, $F6, %11111111, $FE, %00001111
frame2438:
	.byte %01001100, $C7, %00110011, $CA, %00111111, $CF, %11110011, $D1, %00110011, $D2, %00000000, $D4, %00001100, $D9, %11111111, $DD, %00001100, $DE, %11111111, $E2, %00001111, $E3, %11001111, $ED, %11111111
frame2439:
	.byte %01010010, $C7, %11110011, $CA, %11111111, $CB, %00001111, $CF, %11111111, $D5, %11001111, $DA, %11110000, $DB, %11000000, $DC, %00110000, $DD, %00000000, $DE, %00001111, $E4, %11111111, $E5, %00110000, $EA, %00110011, $EB, %11001100, $EE, %11111111, $EF, %00110011, $F7, %00110011, $FF, %00000011
frame2440:
	.byte %01001110, $C7, %11111111, $C9, %00111111, $CA, %00000011, $CB, %00001100, $CC, %11001111, $D1, %11110011, $D4, %00000000, $D5, %00001111, $DA, %11110011, $DB, %11110000, $DE, %00001100, $E3, %00001111, $E5, %11110011, $EA, %00110000
frame2441:
	.byte %01010001, $CA, %00001111, $CB, %00000000, $CC, %00001111, $D1, %11111111, $D5, %00001100, $D6, %11001111, $DC, %11110011, $DE, %00000000, $E2, %11111111, $E3, %11001111, $E6, %00110000, $EB, %11000000, $EF, %11111111, $F2, %11110011, $F3, %11111100, $F7, %11111111, $FF, %00001111
frame2442:
	.byte %01010000, $C3, %11001111, $C9, %00110011, $CA, %00000000, $CC, %00000000, $CD, %11001111, $D2, %11110000, $D5, %00000000, $D6, %00001111, $DA, %11111111, $DD, %00110000, $DF, %00000000, $E3, %11111111, $E5, %11111111, $E6, %11110000, $E7, %11000000, $EB, %00000000
frame2443:
	.byte %01001110, $C2, %00001111, $C3, %00001100, $C4, %11001111, $C9, %11111111, $CD, %00001100, $D2, %11110011, $D6, %00000000, $D7, %11001111, $DC, %11111111, $E6, %11110011, $E7, %11110000, $EA, %00000011, $F2, %00110011, $F3, %11001100
frame2444:
	.byte %01001110, $C3, %00000000, $C4, %00001111, $CA, %00110000, $CD, %00000000, $CE, %11001111, $D2, %11111111, $D3, %00000011, $D7, %00001100, $DB, %11111111, $DD, %11110011, $E6, %11111111, $EA, %00001111, $EB, %00001111, $F3, %11000000
frame2445:
	.byte %01001100, $C2, %00000000, $C4, %00000000, $C5, %00001111, $CE, %00001100, $CF, %11001111, $D3, %00000000, $D4, %11000000, $D7, %00000000, $DE, %00110000, $E7, %11111111, $EA, %00111111, $FB, %00001100
frame2446:
	.byte %01001111, $C5, %00000000, $C6, %11001111, $CA, %11110011, $CB, %00110000, $CE, %00000000, $CF, %00001100, $D3, %00110000, $D4, %11110000, $D5, %00110000, $DD, %11111111, $DE, %11110000, $EA, %11111111, $EB, %11111111, $F2, %00110000, $F3, %00000000
frame2447:
	.byte %01001100, $C2, %00110000, $C6, %00001100, $C7, %11001111, $CA, %11111111, $CB, %00000011, $CF, %00000000, $D3, %11110000, $D4, %11111100, $DE, %11110011, $DF, %11110000, $FA, %00000011, $FB, %00000000
frame2448:
	.byte %01000111, $C2, %11110011, $C6, %00000000, $C7, %00001111, $CB, %00001111, $D3, %11110011, $D5, %11110011, $F2, %00000011
frame2449:
	.byte %01001010, $C2, %11111111, $C3, %11110000, $C7, %00000000, $CB, %00000011, $D3, %11111111, $D4, %11111111, $D6, %00110000, $DE, %11111111, $DF, %11111111, $F2, %00001111
frame2450:
	.byte %01000111, $C3, %11111111, $CB, %00110000, $CC, %11000000, $CD, %00110000, $D5, %11111111, $F3, %00001111, $FA, %00000000
frame2451:
	.byte %01000111, $C3, %00111111, $CB, %11110000, $CC, %11110000, $CD, %11110000, $D6, %11110011, $D7, %11110000, $F4, %11001111
frame2452:
	.byte %01000110, $C3, %00001111, $C6, %00001100, $CB, %11110011, $CC, %11111100, $CD, %11110011, $D6, %11111111
frame2453:
	.byte %01001001, $C3, %00000000, $C5, %00110000, $C6, %00000000, $C7, %00000011, $CB, %11111111, $CC, %11111111, $CD, %11111111, $CE, %00110000, $D7, %11111111
frame2454:
	.byte %01000110, $C3, %11110000, $C4, %11110000, $C5, %11110000, $C7, %00001100, $CE, %11110011, $CF, %11110000
frame2455:
	.byte %01000111, $C3, %11110011, $C4, %11111100, $C5, %11110011, $C6, %00110000, $C7, %00000000, $CE, %11111111, $FC, %00001100
frame2456:
	.byte %01000101, $C3, %11111111, $C4, %11111111, $C5, %11111111, $C6, %11110000, $CF, %11111111
frame2457:
	.byte %01000010, $C6, %11111111, $C7, %11110000
frame2458:
	.byte %01000011, $C7, %11110011, $F3, %00000000, $FC, %00001111
frame2459:
	.byte %01000100, $C7, %11111111, $F2, %00000000, $F4, %11001100, $FA, %00000011
frame2460:
	.byte $88
frame2461:
	.byte %01000001, $F2, %00110000
frame2462:
	.byte %01000100, $EA, %00001111, $EB, %00001111, $EC, %11001111, $FA, %00001111
frame2463:
	.byte %01000010, $F2, %00110011, $F4, %11111100
frame2464:
	.byte %01000100, $EA, %00110011, $EB, %00000000, $EC, %11001100, $F2, %11110011
frame2465:
	.byte %01000010, $EC, %11000000, $FB, %00001111
frame2466:
	.byte %01000101, $E2, %00111111, $E3, %00001111, $E4, %11001111, $F2, %11111111, $F4, %11001100
frame2467:
	.byte %01000100, $E4, %00001111, $EA, %11110011, $F3, %11110000, $F4, %11111100
frame2468:
	.byte %01000011, $E2, %00110011, $E3, %00000000, $E4, %00000000
frame2469:
	.byte %01000100, $DC, %00111111, $EA, %11111111, $EC, %11001100, $F4, %11111111
frame2470:
	.byte %01000100, $DA, %00111111, $DB, %00001111, $DC, %00001111, $F3, %11111111
frame2471:
	.byte %01000010, $E2, %11110011, $E4, %11000000
frame2472:
	.byte %01000101, $DA, %00110011, $DB, %00000000, $DC, %00000000, $EB, %11110000, $EC, %11111100
frame2473:
	.byte %01000001, $E2, %11111111
frame2474:
	.byte %01000101, $D3, %00001111, $D4, %00001111, $E4, %11001100, $EB, %11111111, $EC, %11111111
frame2475:
	.byte %01000011, $D2, %00111111, $D5, %11001111, $DA, %11110011
frame2476:
	.byte %01000011, $D3, %00000000, $D4, %00001100, $E3, %00110000
frame2477:
	.byte %01000110, $D4, %00000000, $D5, %11001100, $DA, %11111111, $DC, %11000000, $E3, %11110000, $E4, %11111100
frame2478:
	.byte %01000011, $D2, %11110011, $D5, %11111100, $E3, %11110011
frame2479:
	.byte %01000100, $CB, %00001111, $CC, %11001111, $D5, %11111111, $DB, %00110000
frame2480:
	.byte %01001000, $CC, %00001111, $CD, %11001111, $D2, %11111111, $D5, %11111100, $DB, %00000000, $DC, %11001100, $E3, %11111111, $E4, %11111111
frame2481:
	.byte %01000001, $DB, %00110011
frame2482:
	.byte %01000011, $CB, %00000000, $CC, %00001100, $CD, %11111111
frame2483:
	.byte %01000010, $DB, %11110000, $DC, %11111100
frame2484:
	.byte %01000011, $CC, %00000000, $D4, %11000000, $D5, %11111111
frame2485:
	.byte %01000011, $CD, %11111100, $D3, %00110000, $DB, %11110011
frame2486:
	.byte %01000001, $C3, %00001111
frame2487:
	.byte %01000101, $C4, %11001111, $CD, %11111111, $D3, %00000000, $DB, %11111111, $DC, %11111111
frame2488:
	.byte %01000001, $CD, %11001111
frame2489:
	.byte %01000010, $C4, %00001111, $D4, %11001100
frame2490:
	.byte $88
frame2491:
	.byte %01000011, $C3, %00000011, $CD, %11001100, $D3, %00110000
frame2492:
	.byte %01000010, $C3, %00000000, $CD, %11111100
frame2493:
	.byte %01000010, $C4, %00001100, $D3, %11110000
frame2494:
	.byte %01000010, $CD, %11111111, $D4, %11111100
frame2495:
	.byte $88
frame2496:
	.byte $88
frame2497:
	.byte $88
frame2498:
	.byte $88
frame2499:
	.byte $88
frame2500:
	.byte %01000001, $CD, %11111100
frame2501:
	.byte %01000001, $CD, %11000000
frame2502:
	.byte $88
frame2503:
	.byte $88
frame2504:
	.byte %01000001, $CD, %11110000
frame2505:
	.byte %01000010, $C4, %00001111, $D4, %11001100
frame2506:
	.byte %01000010, $CD, %11111100, $D3, %00110000
frame2507:
	.byte %01000101, $C2, %00111111, $C3, %00001100, $CD, %00111100, $D4, %11000000, $D5, %11111100
frame2508:
	.byte %01000101, $C2, %11111111, $C3, %00001111, $C4, %11001111, $CD, %00001100, $D3, %00000000
frame2509:
	.byte %01000100, $C4, %11111111, $CD, %00001111, $D5, %11111111, $DC, %11111100
frame2510:
	.byte %01000101, $C3, %11001111, $CA, %11110011, $D4, %00000000, $D5, %11110011, $DB, %11110011
frame2511:
	.byte %01000101, $C3, %11111111, $CC, %00001100, $CD, %11001111, $D5, %11000000, $DB, %11110000
frame2512:
	.byte %01000101, $CA, %00110011, $CC, %00001111, $CD, %11111111, $D5, %00110000, $DC, %11001100
frame2513:
	.byte %01000111, $CA, %00111111, $CB, %00001100, $CC, %11001111, $D5, %00111100, $DB, %00110000, $DC, %11000000, $DD, %11111100
frame2514:
	.byte %01000101, $CB, %00001111, $CC, %11111111, $D5, %00001111, $DB, %00000000, $DD, %11111111
frame2515:
	.byte %01001000, $CA, %11111111, $CB, %11001111, $D2, %11110011, $D4, %00001100, $DC, %00000000, $DD, %11110011, $E3, %11110011, $E4, %11111100
frame2516:
	.byte %01000101, $CB, %11111111, $D4, %00001111, $D5, %11111111, $DD, %11000000, $E3, %11110000
frame2517:
	.byte %01000110, $D2, %00110011, $D3, %00001100, $D4, %11001111, $DD, %00110000, $E3, %00110000, $E4, %11000000
frame2518:
	.byte %01000110, $D2, %00111111, $D3, %00001111, $D4, %11111111, $DD, %00001111, $E3, %00000000, $E5, %11111100
frame2519:
	.byte %01000111, $D3, %11001111, $DA, %11110011, $DC, %00001100, $E4, %00000000, $E5, %11000011, $EB, %11110011, $EC, %11111100
frame2520:
	.byte %01000110, $D2, %11111111, $D3, %11111111, $DC, %00001111, $DD, %11111111, $E5, %00110000, $EB, %11110000
frame2521:
	.byte %01000111, $DA, %00111111, $DB, %00001100, $DC, %11001111, $E5, %00111100, $EB, %00000000, $EC, %11000000, $ED, %11111100
frame2522:
	.byte %01000110, $DB, %00001111, $DC, %11111111, $E2, %11110011, $E5, %00001111, $ED, %11110011, $F3, %11110011
frame2523:
	.byte %01001000, $DA, %11111111, $DB, %11001111, $E4, %00001100, $E5, %11001111, $EC, %00000000, $ED, %11110000, $F3, %11110000, $F4, %11111100
frame2524:
	.byte %01000111, $DB, %11111111, $E2, %00110011, $E4, %00001111, $E5, %11111111, $ED, %00110000, $F3, %00000000, $F4, %11110000
frame2525:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %11000000, %11110000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %11001100, %11111111, %11111111, %00110000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %11111111, %11111111, %11111111, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00001111, %00000011, %00000000, %00000000, %00000000

frame2526:
	.byte $88
frame2527:
	.byte %01000001, $F5, %11000011
frame2528:
	.byte %01000011, $E3, %00110000, $EB, %11110011, $F5, %11110011
frame2529:
	.byte $88
frame2530:
	.byte %01000001, $F5, %11111111
frame2531:
	.byte %01000010, $F5, %00111111, $F6, %00000011
frame2532:
	.byte %01000001, $E4, %00110000
frame2533:
	.byte %01000001, $F6, %00110011
frame2534:
	.byte %01000001, $EB, %11000011
frame2535:
	.byte %01000001, $ED, %11110000
frame2536:
	.byte $88
frame2537:
	.byte %01000010, $E2, %11110000, $EB, %11001111
frame2538:
	.byte %01000011, $EA, %11000000, $F5, %11111111, $FC, %00000000
frame2539:
	.byte %01000011, $EB, %11000000, $EC, %00111111, $F2, %11000000
frame2540:
	.byte %01000001, $EC, %00001111
frame2541:
	.byte %01000101, $E3, %11110000, $E4, %11110000, $EA, %11000011, $F3, %00111111, $F6, %00000011
frame2542:
	.byte %01000010, $E3, %00110000, $ED, %11000000
frame2543:
	.byte %01000001, $E3, %00001100
frame2544:
	.byte %01000010, $E3, %00000011, $EB, %11001100
frame2545:
	.byte %01000010, $E2, %00110000, $FC, %00001100
frame2546:
	.byte %01000011, $DB, %00110000, $E3, %00000000, $F2, %11001100
frame2547:
	.byte %01000011, $E2, %00111100, $EC, %00111100, $F3, %00110011
frame2548:
	.byte %01000010, $DB, %00000000, $F6, %00110011
frame2549:
	.byte %01000010, $DA, %11000000, $ED, %11000011
frame2550:
	.byte %01000011, $DA, %11001100, $E2, %00110011, $F6, %11110011
frame2551:
	.byte %01001000, $DA, %11000000, $E2, %00000011, $E3, %11000000, $E4, %11000000, $EA, %11110011, $EB, %00001100, $FC, %00000000, $FE, %00000011
frame2552:
	.byte %01000101, $DA, %00000000, $E5, %00110000, $EA, %11110000, $EE, %00110000, $F3, %11110011
frame2553:
	.byte %01000011, $DA, %00110000, $EB, %00000000, $EC, %00110000
frame2554:
	.byte %01000100, $D2, %00110000, $E3, %00000000, $ED, %11000000, $F2, %00001100
frame2555:
	.byte %01000101, $D2, %00000000, $DA, %00110011, $E1, %11000000, $E2, %00000000, $EC, %11110000
frame2556:
	.byte $88
frame2557:
	.byte $88
frame2558:
	.byte %01000010, $DA, %00000011, $FD, %00000011
frame2559:
	.byte %01000101, $D1, %11000000, $D2, %00110000, $DA, %00000000, $EC, %11110011, $ED, %11110000
frame2560:
	.byte %01000011, $DA, %00001100, $E9, %00001100, $EA, %11110011
frame2561:
	.byte %01000011, $DA, %00000000, $ED, %11000000, $F5, %11111100
frame2562:
	.byte %01000011, $D1, %11001100, $D2, %00110011, $E4, %11001100
frame2563:
	.byte %01000101, $D2, %00000011, $E4, %00001100, $F2, %11001100, $F4, %11001111, $F5, %00111100
frame2564:
	.byte %01000110, $C9, %11000000, $CA, %00110000, $E1, %00000000, $E4, %00111100, $EE, %00000000, $FE, %00001111
frame2565:
	.byte $88
frame2566:
	.byte %01000100, $C9, %11001100, $D2, %00000000, $E4, %00001100, $ED, %00000000
frame2567:
	.byte %01000001, $EC, %11110000
frame2568:
	.byte %01000100, $C9, %11111111, $CA, %00000000, $EB, %00110000, $EE, %00000011
frame2569:
	.byte $88
frame2570:
	.byte %01000010, $D1, %00001100, $E1, %00110000
frame2571:
	.byte %01000010, $E5, %00000000, $F6, %11000011
frame2572:
	.byte %01000010, $C8, %00001100, $C9, %11110011
frame2573:
	.byte %01000001, $D1, %00000000
frame2574:
	.byte %01000011, $E4, %00000000, $EC, %11111100, $ED, %00001100
frame2575:
	.byte %01000011, $C9, %00000011, $E4, %11000000, $F6, %11110011
frame2576:
	.byte %01000010, $E9, %11001111, $EE, %00001111
frame2577:
	.byte %01000100, $C9, %00001100, $E4, %00000000, $E5, %00000011, $ED, %00000000
frame2578:
	.byte %01000011, $C8, %00000011, $C9, %00000011, $EE, %00111111
frame2579:
	.byte %01000100, $C1, %11000000, $C8, %00001111, $EC, %11001100, $EF, %00000011
frame2580:
	.byte %01000011, $C1, %00000000, $C8, %00001100, $EC, %11000000
frame2581:
	.byte %01000011, $ED, %00110000, $EE, %00001100, $FE, %00000000
frame2582:
	.byte %01001000, $C8, %11001100, $E5, %11000011, $E9, %11000011, $EB, %00000000, $EF, %00000000, $F5, %00110011, $FC, %00000011, $FE, %00001100
frame2583:
	.byte %01000111, $E5, %11000000, $EE, %11000000, $EF, %00110000, $F2, %11001111, $F3, %00110011, $F4, %11001100, $FF, %00000011
frame2584:
	.byte %01000110, $E1, %00000000, $E9, %11000000, $F2, %00001111, $F3, %00000011, $FD, %00001111, $FE, %00000000
frame2585:
	.byte %01001001, $C8, %11000000, $C9, %00110011, $EC, %00000000, $ED, %00000000, $EE, %00000000, $EF, %11110000, $F3, %11110011, $F6, %11110000, $FE, %00001100
frame2586:
	.byte %01001000, $C8, %00000000, $EA, %00000000, $EF, %00000000, $F2, %11001111, $F5, %11110011, $F6, %11000000, $F7, %00001111, $FC, %00000000
frame2587:
	.byte %01000111, $C1, %00110000, $EE, %00000011, $F4, %11000000, $F5, %11111111, $F6, %11001100, $FB, %00000011, $FD, %00001100
frame2588:
	.byte %01001011, $C9, %11110011, $E5, %00000000, $E9, %00000000, $F2, %11000011, $F4, %00000000, $F5, %11110011, $F6, %11000000, $F7, %11000000, $FB, %00001111, $FC, %00000011, $FD, %00001111
frame2589:
	.byte %01001001, $C1, %00000000, $C9, %11000011, $EE, %00000000, $F3, %11110000, $F5, %11110000, $F6, %00110000, $F7, %11110000, $FD, %00000011, $FE, %00000011
frame2590:
	.byte %01000110, $C9, %11001111, $F3, %11000000, $F5, %11000000, $F7, %00110000, $FA, %00001100, $FD, %00001111
frame2591:
	.byte %01001000, $C9, %11001100, $F2, %11000000, $F3, %00000000, $F5, %00000000, $F6, %00000000, $F7, %00000000, $FD, %00001100, $FF, %00001100
frame2592:
	.byte %01000101, $CA, %00110000, $EE, %00110000, $FA, %00000000, $FE, %00001111, $FF, %00000000
frame2593:
	.byte %01000111, $C9, %11000000, $EE, %00000000, $F2, %00000000, $FB, %00001100, $FC, %00000000, $FD, %00000000, $FE, %00000000
frame2594:
	.byte %01000001, $F6, %00001100
frame2595:
	.byte %01000101, $C9, %00000000, $CA, %11110000, $D1, %00001100, $D2, %00000011, $FB, %00000000
frame2596:
	.byte %01000010, $D1, %00000000, $F7, %00110000
frame2597:
	.byte %01000010, $D2, %00111111, $F6, %00000000
frame2598:
	.byte %01000001, $FF, %00001100
frame2599:
	.byte %01000011, $CA, %11000000, $D2, %11001100, $D3, %00000011
frame2600:
	.byte %01000010, $DA, %00001100, $F7, %00000000
frame2601:
	.byte $88
frame2602:
	.byte %01000100, $D3, %00110011, $DA, %00000000, $DB, %00110011, $FF, %00000000
frame2603:
	.byte %01000010, $CA, %00000000, $DB, %00000011
frame2604:
	.byte %01000010, $D2, %00001100, $DB, %11000011
frame2605:
	.byte %01000001, $D3, %00110000
frame2606:
	.byte %01000001, $D2, %00000000
frame2607:
	.byte %01000011, $D3, %00000000, $DB, %00000011, $DC, %00110000
frame2608:
	.byte $88
frame2609:
	.byte %01000001, $DB, %11000011
frame2610:
	.byte %01000001, $DB, %11110000
frame2611:
	.byte $88
frame2612:
	.byte %01000010, $DB, %00000000, $DC, %00111100
frame2613:
	.byte %01000001, $DC, %00110000
frame2614:
	.byte %01000001, $E3, %00001111
frame2615:
	.byte $88
frame2616:
	.byte %01000001, $E3, %00001100
frame2617:
	.byte %01000001, $DC, %00110011
frame2618:
	.byte $88
frame2619:
	.byte %01000001, $E3, %00000000
frame2620:
	.byte %01000010, $DC, %00110000, $E4, %00000011
frame2621:
	.byte $88
frame2622:
	.byte %01000010, $DB, %00001100, $E4, %00110011
frame2623:
	.byte $88
frame2624:
	.byte %01000001, $DB, %00000000
frame2625:
	.byte %01000010, $DB, %11000000, $E4, %00000011
frame2626:
	.byte %01000001, $E4, %00001111
frame2627:
	.byte %01000010, $DB, %11110000, $DC, %11110000
frame2628:
	.byte %01000010, $DB, %11000000, $DC, %11110011
frame2629:
	.byte %01000010, $DC, %11111111, $E4, %00001100
frame2630:
	.byte %01000001, $E3, %00001111
frame2631:
	.byte %01000010, $E3, %00001100, $E4, %00000000
frame2632:
	.byte %01000001, $D4, %11110000
frame2633:
	.byte %01000001, $D4, %00110000
frame2634:
	.byte %01000011, $DB, %11001100, $DC, %00110011, $E3, %11001100
frame2635:
	.byte $88
frame2636:
	.byte %01000010, $D3, %11000000, $E3, %00001100
frame2637:
	.byte $88
frame2638:
	.byte %01000010, $E3, %00000000, $E4, %00110011
frame2639:
	.byte %01000001, $D4, %00000000
frame2640:
	.byte %01000001, $E4, %00000011
frame2641:
	.byte %01000010, $D3, %11110000, $E4, %11000011
frame2642:
	.byte %01000011, $D3, %00110000, $DB, %11001111, $E4, %00000011
frame2643:
	.byte %01000011, $DB, %11111111, $DC, %00110000, $E4, %00001111
frame2644:
	.byte %01000010, $D3, %00000000, $E3, %00001100
frame2645:
	.byte %01000001, $E4, %00000011
frame2646:
	.byte %01000001, $DC, %11110000
frame2647:
	.byte %01000010, $DA, %11000000, $DB, %11111100
frame2648:
	.byte $88
frame2649:
	.byte %01000011, $DA, %00000000, $DC, %00110000, $E3, %00001111
frame2650:
	.byte %01000011, $DB, %11110000, $DC, %00111100, $E2, %00001100
frame2651:
	.byte %01000011, $DB, %11001100, $DC, %00111111, $E2, %00000000
frame2652:
	.byte %01000011, $D4, %11000000, $DC, %00110011, $E3, %00111111
frame2653:
	.byte %01000001, $E3, %00111100
frame2654:
	.byte %01000001, $D4, %00000000
frame2655:
	.byte %01000010, $D4, %00110000, $E3, %11001100
frame2656:
	.byte %01000011, $D4, %00110011, $DB, %11000000, $EB, %00001100
frame2657:
	.byte %01000001, $D4, %00000000
frame2658:
	.byte %01000100, $D3, %00001100, $DB, %11001100, $E3, %00001100, $EB, %00000000
frame2659:
	.byte %01000011, $D3, %11001100, $E4, %00110011, $EC, %00000011
frame2660:
	.byte %01000001, $D3, %11000011
frame2661:
	.byte %01000010, $D3, %00000011, $EC, %00000000
frame2662:
	.byte %01000011, $D3, %00110000, $E4, %00000011, $EC, %00001100
frame2663:
	.byte %01000100, $DC, %11110011, $E3, %00000000, $E4, %11000011, $EC, %00000000
frame2664:
	.byte %01000010, $D3, %00000000, $DB, %11001111
frame2665:
	.byte %01000011, $DA, %00001100, $E4, %00001111, $E5, %00110000
frame2666:
	.byte %01000010, $DB, %11001100, $E3, %00001100
frame2667:
	.byte %01000011, $DA, %11000000, $E4, %00000011, $E5, %00000011
frame2668:
	.byte %01000010, $DB, %11111100, $E5, %00000000
frame2669:
	.byte %01000011, $DA, %00000000, $DD, %00110000, $E4, %00000000
frame2670:
	.byte %01000011, $DB, %11001100, $DC, %00110011, $E2, %00001100
frame2671:
	.byte %01000011, $DD, %00000011, $E2, %11000000, $E3, %00001111
frame2672:
	.byte %01000010, $DB, %11111100, $DC, %00111111
frame2673:
	.byte %01000100, $D5, %00110000, $DD, %00000000, $E2, %00000000, $E3, %00111100
frame2674:
	.byte %01000011, $DC, %00110011, $E4, %00000011, $EB, %00000011
frame2675:
	.byte %01000100, $D4, %11000000, $D5, %00000000, $DB, %11001100, $E3, %00001100
frame2676:
	.byte %01000011, $D4, %00001100, $E3, %11001100, $EB, %00000000
frame2677:
	.byte %01000010, $D4, %00111100, $EB, %00001100
frame2678:
	.byte %01000100, $D4, %00110011, $E3, %00001100, $EB, %00000000, $EC, %00110000
frame2679:
	.byte %01000100, $CC, %00110000, $D4, %00000011, $DB, %11111100, $EC, %00110011
frame2680:
	.byte %01000101, $CB, %11000000, $CC, %00000000, $D4, %00000000, $E4, %00110011, $EC, %11000000
frame2681:
	.byte %01000011, $D3, %11001100, $E4, %00000011, $EC, %00001100
frame2682:
	.byte %01000110, $CB, %00000000, $D3, %11000000, $DB, %11111111, $E4, %11000011, $EC, %00000000, $ED, %00000011
frame2683:
	.byte %01000010, $D3, %00000011, $ED, %00000000
frame2684:
	.byte %01000100, $D3, %00110000, $E3, %00001111, $E4, %00001111, $E5, %00110000
frame2685:
	.byte %01000010, $DB, %11111100, $E5, %00000011
frame2686:
	.byte %01000100, $D2, %11000000, $D3, %00000000, $DB, %11111111, $E4, %00000011
frame2687:
	.byte %01000110, $D2, %00000000, $DA, %00001100, $DC, %11110011, $DD, %11110000, $E3, %11001111, $E5, %00000000
frame2688:
	.byte %01000011, $DA, %00001111, $DB, %11111100, $DD, %00001100
frame2689:
	.byte %01000011, $DA, %11000000, $DC, %00110011, $DD, %00000011
frame2690:
	.byte %01000011, $DA, %11110000, $DC, %11111111, $DD, %00000000
frame2691:
	.byte %01000101, $D5, %00110000, $DA, %00000000, $DB, %11001100, $E2, %00001111, $E4, %00110011
frame2692:
	.byte %01000100, $D4, %11000000, $D5, %00000011, $DC, %11110011, $E2, %00001100
frame2693:
	.byte %01000011, $D4, %11001100, $D5, %00000000, $E2, %11000000
frame2694:
	.byte %01000101, $CC, %11000000, $D4, %00001100, $E2, %00000000, $E3, %11111100, $EA, %00001100
frame2695:
	.byte %01000100, $CC, %00000000, $D4, %00110000, $EA, %00000000, $EB, %00000011
frame2696:
	.byte %01000101, $CC, %00110011, $D4, %00110011, $E3, %11001100, $E4, %00111111, $EB, %00110011
frame2697:
	.byte %01000011, $CC, %00000000, $D4, %00000000, $EB, %00001100
frame2698:
	.byte %01000100, $CB, %11000000, $D3, %00001100, $E3, %00001100, $EB, %11001100
frame2699:
	.byte %01000011, $CB, %00000000, $D3, %11001100, $EB, %00000000
frame2700:
	.byte %01000100, $CB, %00110000, $D3, %11000000, $D4, %00110000, $EC, %00110011
frame2701:
	.byte %01000101, $CA, %11000000, $CB, %00000000, $D3, %00000011, $DB, %11111100, $EC, %00000000
frame2702:
	.byte %01000111, $CA, %00000000, $D2, %00001100, $D3, %00110000, $D4, %00000000, $DC, %11111111, $E4, %00001111, $EC, %11001100
frame2703:
	.byte %01000110, $D2, %11000000, $D3, %11000000, $DB, %11001100, $E4, %11001111, $EC, %00000000, $ED, %00000011
frame2704:
	.byte %01000010, $D2, %11110000, $DB, %11001111
frame2705:
	.byte %01000110, $D2, %00000000, $D3, %00000000, $DA, %00001111, $E4, %00001111, $E5, %00110000, $ED, %00000000
frame2706:
	.byte %01000010, $DB, %11001100, $E5, %11000011
frame2707:
	.byte %01000101, $D4, %00110000, $DA, %11110000, $DB, %11111100, $E4, %00000011, $E5, %00001111
frame2708:
	.byte %01000101, $DA, %11000000, $DB, %11111111, $DD, %11110000, $E2, %00000011, $E5, %00000000
frame2709:
	.byte %01000010, $DA, %00000000, $E2, %00001111
frame2710:
	.byte %01000101, $D3, %11000000, $DB, %11111100, $DD, %00001111, $E2, %11000000, $E3, %00001111
frame2711:
	.byte %01000011, $D5, %11000000, $DC, %00111111, $DD, %00000000
frame2712:
	.byte %01000100, $D5, %00110000, $E2, %00000000, $E3, %00111100, $EA, %11001100
frame2713:
	.byte %01000110, $D4, %11110000, $D5, %00000011, $DC, %00110011, $E3, %00111111, $EA, %00000000, $EB, %00000011
frame2714:
	.byte %01000111, $CD, %00110000, $D4, %00111100, $D5, %00000000, $DB, %11111111, $E3, %11001111, $E4, %00110011, $EB, %00110000
frame2715:
	.byte %01000101, $CC, %11000000, $CD, %00000000, $E4, %00000011, $EB, %11001100, $F3, %00001100
frame2716:
	.byte %01000011, $CC, %11001100, $D4, %00110011, $F3, %00000000
frame2717:
	.byte %01000101, $CC, %00110011, $E4, %00110011, $EB, %00000000, $EC, %00110011, $F4, %00000011
frame2718:
	.byte %01000110, $C4, %00110000, $CC, %00000011, $D4, %00110000, $E4, %00111111, $EC, %11000011, $F4, %00001100
frame2719:
	.byte %01000111, $C3, %11000000, $C4, %00000000, $CB, %11001100, $CC, %00000000, $D3, %11001100, $EC, %11001100, $F4, %00000000
frame2720:
	.byte %01000101, $C3, %00110000, $CB, %11000000, $E4, %11110011, $EC, %00000000, $ED, %11110011
frame2721:
	.byte %01000111, $CB, %00110011, $D4, %00110011, $DC, %11110011, $E3, %11111111, $E4, %00111111, $E5, %00110000, $ED, %00001111
frame2722:
	.byte %01001000, $C3, %00000000, $CA, %00001100, $CB, %00110000, $D3, %11000011, $E5, %11110011, $EB, %00001100, $EC, %00000011, $ED, %00001100
frame2723:
	.byte %01001001, $CA, %11000011, $CB, %00000000, $D3, %11111111, $DA, %11000000, $DD, %00110000, $E4, %11111111, $E5, %00001111, $E6, %00110000, $ED, %00000000
frame2724:
	.byte %01001010, $C9, %11001100, $CA, %00110000, $CC, %00110000, $D2, %00001100, $DC, %11111111, $DD, %11110000, $E2, %00001100, $E5, %00000000, $E6, %00001111, $EB, %00001111
frame2725:
	.byte %01001011, $C9, %00000000, $CA, %00000000, $CB, %11000000, $D1, %00001100, $D2, %00001111, $D3, %11111100, $DD, %11001111, $DE, %11110000, $E2, %11001100, $E6, %00000000, $EC, %00001111
frame2726:
	.byte %01001001, $D1, %11111100, $D2, %11110000, $D4, %11110011, $DB, %11111100, $DD, %00001111, $DE, %00001111, $E5, %00000011, $EB, %11001111, $EC, %00111111
frame2727:
	.byte %01001011, $CB, %11001100, $CC, %00110011, $D1, %11000000, $D5, %11110000, $D6, %11110000, $D9, %00001111, $DA, %00000000, $DD, %00000000, $DE, %00000000, $EA, %00001100, $EB, %11111111
frame2728:
	.byte %01001100, $D1, %00000000, $D2, %11000000, $D6, %11111100, $D7, %00000011, $D8, %11000000, $D9, %00111100, $DA, %00001111, $DB, %11001111, $E5, %00110000, $EC, %11111111, $ED, %00000011, $F3, %00001100
frame2729:
	.byte %01001101, $CB, %11111111, $D4, %11111111, $D5, %00111111, $D6, %00001111, $D7, %00000000, $D8, %00000000, $D9, %11000000, $DA, %00111111, $E0, %00001100, $E1, %00001111, $E2, %11000000, $EA, %11001100, $F4, %00000011
frame2730:
	.byte %01001101, $C3, %11000000, $D2, %00000000, $D5, %00001111, $D9, %00000000, $DA, %00111100, $DB, %11111111, $DC, %11110011, $E0, %11000000, $E1, %00111100, $E3, %11111100, $ED, %00110011, $F3, %11001111, $F4, %00111111
frame2731:
	.byte %01001101, $C4, %00110000, $D3, %11111111, $D6, %00000011, $DA, %11111100, $DC, %00110011, $E0, %00000000, $E1, %11000000, $E2, %00000011, $E8, %00001100, $E9, %00000011, $F2, %00001100, $F4, %11111111, $FB, %00001100
frame2732:
	.byte %01001000, $DA, %11001100, $E2, %00110011, $E3, %11001111, $E8, %00000000, $E9, %00111111, $F3, %11111111, $F5, %00000011, $FC, %00000011
frame2733:
	.byte %01001001, $D3, %11001111, $DC, %11110011, $E1, %00000000, $E2, %00111100, $E9, %11111100, $EA, %11000000, $F2, %11001100, $F5, %00110011, $FC, %00001111
frame2734:
	.byte %01001010, $C3, %11110000, $D5, %11111100, $E2, %11111100, $E3, %11111111, $E5, %00000000, $E9, %11000000, $EA, %00110011, $EB, %11111100, $F1, %00111100, $FB, %00001111
frame2735:
	.byte %01001011, $D3, %11111111, $D5, %11110000, $D6, %00000000, $DA, %00000000, $E2, %11001100, $E4, %00111111, $E9, %00000000, $EA, %00111100, $F1, %00001100, $F2, %11000011, $FD, %00000011
frame2736:
	.byte %01000110, $D4, %11110011, $E2, %00000000, $EA, %11111100, $EB, %11001111, $ED, %00110000, $F1, %00000000
frame2737:
	.byte %01000111, $C3, %11000000, $D5, %00000000, $DC, %11111111, $DD, %00001111, $EA, %11001100, $EB, %11111111, $F2, %00111100
frame2738:
	.byte %01001001, $C3, %00000000, $C4, %00000000, $D4, %00110011, $DC, %00111111, $DD, %00000011, $EA, %11000000, $EC, %11110011, $ED, %00000000, $F2, %11001100
frame2739:
	.byte %01000101, $D3, %11001111, $DC, %11111111, $DD, %00110000, $EA, %00000000, $F2, %00000000
frame2740:
	.byte %01000111, $DB, %11111100, $DC, %11110011, $E3, %11001111, $E5, %00000011, $EC, %00110011, $F3, %11001111, $F5, %00110000
frame2741:
	.byte %01000111, $CB, %11111100, $D3, %11111111, $DB, %11001100, $DC, %00110011, $DD, %00000000, $F2, %11000000, $F5, %00000000
frame2742:
	.byte %01001000, $CC, %00110000, $E4, %11111111, $E5, %00000000, $EB, %11111100, $F2, %00000000, $FA, %00000011, $FB, %00001100, $FD, %00000000
frame2743:
	.byte %01000011, $CB, %11110000, $E4, %11110011, $FA, %00000000
frame2744:
	.byte %01000011, $CB, %11000000, $E3, %11001100, $EC, %00111111
frame2745:
	.byte %01000101, $E4, %00110011, $EC, %11110011, $F4, %00110011, $FA, %00001100, $FC, %00000011
frame2746:
	.byte %01000101, $CC, %00000000, $DB, %11001111, $DC, %00000011, $EB, %11001100, $F4, %00111111
frame2747:
	.byte $88
frame2748:
	.byte %01000011, $CB, %00000000, $F3, %11111111, $FA, %00000000
frame2749:
	.byte %01000010, $D3, %11111100, $F4, %00110011
frame2750:
	.byte %01000010, $D3, %11001100, $F5, %00110011
frame2751:
	.byte %01000001, $F5, %00000011
frame2752:
	.byte $88
frame2753:
	.byte %01000010, $ED, %00110000, $FB, %00001111
frame2754:
	.byte %01000001, $F3, %11001111
frame2755:
	.byte %01000011, $D3, %11111100, $DC, %00110011, $EC, %11111111
frame2756:
	.byte %01000001, $FC, %00001111
frame2757:
	.byte %01000001, $EC, %00111111
frame2758:
	.byte %01000001, $F3, %11111111
frame2759:
	.byte %01000001, $DC, %00000011
frame2760:
	.byte %01000001, $F5, %00000000
frame2761:
	.byte %01000001, $EB, %11111100
frame2762:
	.byte %01000011, $D3, %11111111, $E4, %11110011, $ED, %00110011
frame2763:
	.byte $88
frame2764:
	.byte %01000010, $EC, %00110011, $ED, %00110000
frame2765:
	.byte %01000010, $ED, %00000011, $F4, %11110011
frame2766:
	.byte %01000001, $F4, %11111111
frame2767:
	.byte $88
frame2768:
	.byte %01000011, $E4, %11111111, $EC, %11110011, $ED, %00000000
frame2769:
	.byte %01000001, $D3, %11111100
frame2770:
	.byte %01000001, $EC, %11111111
frame2771:
	.byte $88
frame2772:
	.byte $88
frame2773:
	.byte %01000011, $DC, %00110011, $E3, %11001111, $F4, %11110011
frame2774:
	.byte $88
frame2775:
	.byte $88
frame2776:
	.byte %01000011, $DB, %11111111, $E4, %11110011, $EC, %11110011
frame2777:
	.byte %01000001, $E4, %11111111
frame2778:
	.byte %01000001, $D3, %11001100
frame2779:
	.byte $88
frame2780:
	.byte $88
frame2781:
	.byte %01000100, $DB, %11111100, $E2, %00001100, $EC, %11111111, $F4, %00110011
frame2782:
	.byte $88
frame2783:
	.byte %01000001, $F3, %11111100
frame2784:
	.byte $88
frame2785:
	.byte %01000001, $EB, %11001100
frame2786:
	.byte %01000001, $EB, %11001111
frame2787:
	.byte %01000001, $EB, %11001100
frame2788:
	.byte %01000011, $EC, %11110011, $F3, %11111111, $F4, %00111111
frame2789:
	.byte $88
frame2790:
	.byte %01000001, $DB, %11001100
frame2791:
	.byte %01000001, $E4, %00111111
frame2792:
	.byte %01000001, $DC, %00111111
frame2793:
	.byte %01000010, $D4, %11110011, $DB, %11111100
frame2794:
	.byte $88
frame2795:
	.byte %01000001, $F4, %11111111
frame2796:
	.byte %01000001, $EB, %11001111
frame2797:
	.byte %01000001, $EA, %00001100
frame2798:
	.byte $88
frame2799:
	.byte %01000001, $E2, %00000000
frame2800:
	.byte %01000001, $E4, %00110011
frame2801:
	.byte %01000010, $E3, %11111111, $EA, %00000000
frame2802:
	.byte %01000010, $EB, %11001100, $F4, %00111111
frame2803:
	.byte %01000010, $D4, %11111111, $DB, %11110000
frame2804:
	.byte %01000010, $CB, %11000000, $E2, %11000000
frame2805:
	.byte %01000001, $DC, %00110011
frame2806:
	.byte %01000010, $CC, %00110000, $E2, %11110000
frame2807:
	.byte %01000010, $E2, %11001100, $EB, %11111100
frame2808:
	.byte %01000010, $E2, %00001100, $E3, %11001111
frame2809:
	.byte %01000001, $DB, %11111100
frame2810:
	.byte %01000001, $E2, %00001111
frame2811:
	.byte %01000001, $DA, %11000000
frame2812:
	.byte %01000001, $E2, %00001100
frame2813:
	.byte %01000010, $DA, %11110000, $E2, %00000000
frame2814:
	.byte %01000001, $F4, %00110011
frame2815:
	.byte %01000010, $D9, %11000000, $DB, %11110000
frame2816:
	.byte $88
frame2817:
	.byte %01000001, $DA, %11000011
frame2818:
	.byte %01000100, $D9, %00000000, $DA, %11001111, $DB, %11111100, $FC, %00000011
frame2819:
	.byte %01000010, $CC, %11110000, $DA, %00001111
frame2820:
	.byte %01000001, $D9, %00001100
frame2821:
	.byte %01000001, $FC, %00001111
frame2822:
	.byte %01000010, $D2, %00110000, $DB, %11111111
frame2823:
	.byte %01000010, $CB, %00000000, $D9, %00000000
frame2824:
	.byte %01000001, $D1, %11000000
frame2825:
	.byte %01000011, $D2, %11110000, $DA, %00001100, $E4, %00000011
frame2826:
	.byte $88
frame2827:
	.byte %01000010, $DA, %00000000, $DC, %00111111
frame2828:
	.byte %01000001, $D1, %00001100
frame2829:
	.byte %01000001, $EB, %11001100
frame2830:
	.byte $88
frame2831:
	.byte %01000001, $EC, %00110011
frame2832:
	.byte %01000010, $D1, %00000000, $F4, %00111111
frame2833:
	.byte %01000011, $D2, %11110011, $D3, %00001100, $F4, %11111111
frame2834:
	.byte %01000001, $D2, %11000011
frame2835:
	.byte %01000010, $E2, %00001100, $F3, %11111100
frame2836:
	.byte $88
frame2837:
	.byte %01000001, $CC, %00110000
frame2838:
	.byte $88
frame2839:
	.byte $88
frame2840:
	.byte %01000001, $F4, %11110011
frame2841:
	.byte %01000011, $CA, %00110000, $D2, %11000000, $EB, %11001111
frame2842:
	.byte %01000011, $D3, %00111100, $EB, %11001100, $FB, %00001100
frame2843:
	.byte %01000010, $E2, %00000000, $EB, %11001111
frame2844:
	.byte $88
frame2845:
	.byte %01000001, $CC, %11110000
frame2846:
	.byte %01000010, $D2, %11001100, $E3, %11111111
frame2847:
	.byte %01000001, $F3, %11001100
frame2848:
	.byte $88
frame2849:
	.byte %01000001, $D2, %00001100
frame2850:
	.byte $88
frame2851:
	.byte $88
frame2852:
	.byte $88
frame2853:
	.byte $88
frame2854:
	.byte $88
frame2855:
	.byte $88
frame2856:
	.byte %01000010, $CA, %00000000, $EC, %11110011
frame2857:
	.byte %01000010, $D2, %11001100, $D3, %11111100
frame2858:
	.byte $88
frame2859:
	.byte %01000001, $D3, %11001100
frame2860:
	.byte %01000001, $D2, %11000000
frame2861:
	.byte %01000101, $D2, %11001100, $EC, %00110011, $F3, %11111100, $F4, %11111111, $FB, %00001111
frame2862:
	.byte %01000001, $F3, %11111111
frame2863:
	.byte %01000011, $D2, %11000000, $DA, %00001100, $E4, %00110011
frame2864:
	.byte %01000101, $CC, %00110000, $D2, %11001100, $DB, %11110011, $EB, %11111111, $EC, %11110000
frame2865:
	.byte %01000010, $CB, %11000000, $DB, %11110000
frame2866:
	.byte $88
frame2867:
	.byte %01000001, $D2, %11000000
frame2868:
	.byte %01000010, $E2, %11000000, $EC, %11110011
frame2869:
	.byte %01000101, $CB, %11001100, $D2, %00000000, $DA, %11001100, $DB, %11111100, $DC, %00110011
frame2870:
	.byte %01000011, $CC, %00110011, $DC, %11110011, $E4, %00111111
frame2871:
	.byte %01000101, $CC, %11110000, $D3, %11001111, $DA, %11000000, $DC, %11111111, $EC, %00110011
frame2872:
	.byte %01000010, $DA, %00000000, $E4, %11111111
frame2873:
	.byte %01000001, $F5, %00000011
frame2874:
	.byte %01000100, $CB, %11111100, $E2, %00000000, $EC, %00111111, $F5, %00110011
frame2875:
	.byte %01000011, $CB, %11111111, $CC, %11110011, $EC, %11111111
frame2876:
	.byte %01000010, $D3, %11111111, $E5, %00110011
frame2877:
	.byte %01000001, $FD, %00000011
frame2878:
	.byte %01000010, $ED, %00110011, $F5, %00110000
frame2879:
	.byte %01000010, $D3, %11001111, $F5, %00110011
frame2880:
	.byte %01000010, $D3, %11111111, $F3, %11001111
frame2881:
	.byte $88
frame2882:
	.byte %01000010, $D2, %00001100, $F5, %11110011
frame2883:
	.byte %01000010, $EB, %11001111, $F3, %11111111
frame2884:
	.byte %01000001, $DB, %11001100
frame2885:
	.byte %01000001, $E5, %11111111
frame2886:
	.byte %01000010, $ED, %00110000, $F3, %11111100
frame2887:
	.byte %01000100, $DB, %00001100, $E5, %00111111, $ED, %00110011, $F5, %11111111
frame2888:
	.byte %01000011, $DD, %11000000, $E5, %11111111, $E6, %00000011
frame2889:
	.byte %01000001, $EB, %11001100
frame2890:
	.byte $88
frame2891:
	.byte %01000001, $DE, %00110000
frame2892:
	.byte %01000001, $DD, %11001100
frame2893:
	.byte %01000100, $D2, %00000000, $DB, %11001100, $E3, %11001111, $E6, %00000000
frame2894:
	.byte %01000110, $D5, %11000000, $DB, %00001100, $DE, %00110011, $E3, %11001100, $ED, %11110011, $F3, %11110000
frame2895:
	.byte %01000101, $D5, %11001100, $D6, %00110000, $DB, %11001100, $DD, %11001111, $E6, %00000011
frame2896:
	.byte %01000101, $CC, %11111111, $D5, %00110000, $DD, %00000011, $ED, %11111111, $F6, %00000011
frame2897:
	.byte %01000100, $CE, %00110000, $D5, %00110011, $D6, %00110011, $EB, %00001100
frame2898:
	.byte %01000010, $FB, %00001100, $FD, %00001111
frame2899:
	.byte %01000010, $CD, %00110000, $F6, %00110011
frame2900:
	.byte %01000110, $CB, %11001111, $DB, %00001100, $DC, %11001111, $DD, %00110011, $E5, %11110011, $EB, %00000000
frame2901:
	.byte %01001000, $CB, %11001100, $CE, %00110011, $D3, %11001111, $D6, %11110011, $DB, %00000000, $E3, %00000000, $E5, %11111111, $E6, %00110011
frame2902:
	.byte %01000111, $C6, %00110011, $D3, %11001100, $DC, %11111111, $DD, %00111111, $DE, %11111111, $E6, %00111111, $F3, %11000000
frame2903:
	.byte %01000100, $DC, %11001111, $DE, %11111100, $EE, %00110011, $F4, %11111100
frame2904:
	.byte %01000101, $CD, %00110011, $CE, %11000000, $D5, %11111111, $D6, %11001100, $DC, %11111111
frame2905:
	.byte %01000100, $C6, %00000000, $DE, %11001100, $EC, %11001111, $F6, %00111111
frame2906:
	.byte %01000011, $CD, %11110011, $FB, %00000000, $FE, %00000011
frame2907:
	.byte %01000101, $CB, %00001100, $DC, %00111111, $DD, %11111111, $EC, %11001100, $F6, %11111111
frame2908:
	.byte %01000100, $CB, %00000000, $D3, %00001100, $DC, %00001111, $E6, %11111100
frame2909:
	.byte %01000101, $CE, %11001100, $DC, %00001100, $DF, %00000011, $E4, %11001111, $E6, %11111111
frame2910:
	.byte %01000111, $C6, %11000000, $D3, %00000000, $D7, %00110000, $DF, %00110011, $E4, %11001100, $E7, %00000011, $F3, %00000000
frame2911:
	.byte %01000100, $CD, %11111111, $D6, %11111100, $DC, %11001100, $DE, %11001111
frame2912:
	.byte %01000110, $C6, %11001100, $CE, %00001100, $DC, %00001100, $DE, %11000011, $EE, %00111111, $F4, %11110000
frame2913:
	.byte %01000011, $D6, %00110000, $DE, %00000000, $EE, %11111111
frame2914:
	.byte %01000011, $CE, %00000000, $D6, %00110011, $DE, %00000011
frame2915:
	.byte %01000011, $C4, %11000000, $C6, %11000000, $D7, %00110011
frame2916:
	.byte %01000100, $C6, %00000000, $CF, %00110000, $DC, %11001100, $EC, %00001100
frame2917:
	.byte %01000001, $DE, %00110011
frame2918:
	.byte $88
frame2919:
	.byte $88
frame2920:
	.byte $88
frame2921:
	.byte %01000001, $CE, %00110000
frame2922:
	.byte $88
frame2923:
	.byte %01000001, $DC, %00001100
frame2924:
	.byte %01000001, $D7, %11110011
frame2925:
	.byte %01000001, $DC, %11001100
frame2926:
	.byte %01000010, $C5, %00110000, $CF, %00110011
frame2927:
	.byte %01000010, $C7, %00110000, $DF, %00111111
frame2928:
	.byte %01000010, $D4, %11001111, $DE, %00110000
frame2929:
	.byte %01000010, $C7, %00110011, $EC, %00000000
frame2930:
	.byte $88
frame2931:
	.byte %01000100, $CE, %00110011, $DF, %11111100, $E7, %00110011, $F4, %11110011
frame2932:
	.byte %01000011, $D7, %11111111, $DE, %00110011, $E6, %11110011
frame2933:
	.byte %01001001, $C5, %11110000, $CC, %11001111, $CF, %00110000, $D7, %11001100, $DC, %00001100, $DE, %00110000, $E4, %00001100, $F4, %11111111, $FC, %00001100
frame2934:
	.byte %01000100, $D4, %11001100, $DC, %00000000, $E4, %00000000, $E6, %11111111
frame2935:
	.byte %01000011, $CF, %11110000, $D4, %00001100, $DE, %00110011
frame2936:
	.byte %01000010, $CF, %11000000, $D4, %11001100
frame2937:
	.byte %01000001, $DE, %00110000
frame2938:
	.byte %01000010, $C7, %00110000, $DF, %11111111
frame2939:
	.byte %01000100, $CC, %11111111, $CF, %00110011, $D4, %11001111, $D7, %11001111
frame2940:
	.byte %01000111, $C4, %11110000, $C7, %00000000, $D7, %11110011, $DC, %11000000, $DF, %00110011, $E4, %00001100, $E7, %00000011
frame2941:
	.byte %01001110, $C4, %11000000, $C5, %00000000, $CE, %00000000, $CF, %00000000, $D4, %11111111, $D7, %00110000, $DC, %11001100, $DF, %00000000, $E4, %11001100, $E7, %00000000, $EC, %00001100, $EE, %11110011, $F7, %00000011, $FC, %00001111
frame2942:
	.byte %01001111, $C4, %00000000, $CD, %11110011, $D3, %11001100, $D6, %11110000, $D7, %00000000, $DB, %11000000, $DC, %11111100, $DE, %00000000, $E2, %11000000, $E3, %11111111, $E4, %11111111, $E6, %00110011, $EA, %00001100, $EB, %00001100, $EC, %11001100
frame2943:
	.byte %01001110, $CB, %11000000, $CC, %11111100, $CD, %00110000, $D6, %00000000, $DB, %00001100, $DC, %11111111, $DD, %00111111, $E6, %00110000, $EB, %00001111, $EC, %11111111, $EF, %00110000, $F6, %11111100, $F7, %00110011, $FC, %00001100
frame2944:
	.byte %01001110, $CB, %00000000, $CC, %11110000, $CD, %00000000, $D3, %11111100, $D5, %11110011, $DB, %00001111, $E0, %00001111, $E1, %11001111, $E2, %11110000, $E3, %11110011, $EA, %00000000, $F4, %11001100, $F7, %00111111, $FE, %00001111
frame2945:
	.byte %01001000, $D3, %11111111, $DB, %11001111, $DD, %11001111, $E0, %00000000, $E1, %00001111, $E2, %11001111, $E3, %11111111, $E5, %11110011
frame2946:
	.byte %01001100, $CB, %00110000, $DA, %00110000, $DB, %11111111, $DD, %00111111, $E1, %00000000, $E2, %00000000, $E3, %11001111, $E6, %00000000, $EB, %00001100, $F7, %00110011, $FC, %00000000, $FF, %00000011
frame2947:
	.byte %01001011, $CB, %00000000, $D3, %11001111, $D5, %00110011, $DA, %00000000, $DD, %11111111, $E3, %00001100, $EB, %00000000, $EC, %11001111, $EF, %00000000, $F6, %11111111, $FF, %00000000
frame2948:
	.byte %01001000, $CC, %00000000, $DB, %11001100, $E3, %00000000, $E4, %11001111, $EC, %11001100, $F4, %00000000, $F7, %00000011, $FF, %00001111
frame2949:
	.byte %01001000, $D3, %11001100, $D5, %11110011, $DB, %00001100, $DE, %00111111, $E5, %11111111, $EC, %00001100, $F7, %00110000, $FD, %00001100
frame2950:
	.byte %01000111, $D3, %00001100, $DE, %11111100, $DF, %00001111, $E4, %00001100, $E6, %00110011, $EC, %00000000, $F7, %11110000
frame2951:
	.byte %01001111, $D3, %00000000, $D5, %11111111, $D6, %00110011, $DB, %00000000, $DC, %11001111, $DE, %11110011, $DF, %00111111, $E5, %11001111, $E6, %11111111, $ED, %11001100, $EE, %11111111, $EF, %00110000, $F5, %11001100, $F7, %11110011, $FD, %00000000
frame2952:
	.byte %01001101, $D4, %11000000, $D6, %11110011, $DC, %00001100, $DE, %11111111, $DF, %00111100, $E4, %00000000, $E5, %00001111, $E7, %00110011, $ED, %11000000, $EF, %11110011, $F5, %00000000, $F7, %11111111, $FE, %00001100
frame2953:
	.byte %01001111, $D4, %00000000, $D5, %11111100, $D6, %11111111, $D7, %00110011, $DC, %00000000, $DD, %11001111, $DF, %11110011, $E5, %00001100, $E6, %11001111, $E7, %11111111, $ED, %00000000, $EE, %11001100, $EF, %11111111, $F6, %11001100, $FE, %00000000
frame2954:
	.byte %01001000, $D5, %11000000, $D7, %11111111, $DD, %11001100, $DF, %11111111, $E5, %00000000, $EE, %00000000, $F6, %00000000, $FF, %00001100
frame2955:
	.byte %01001000, $D5, %00000000, $D6, %11111100, $DD, %00000000, $DE, %11001111, $E6, %11001100, $EF, %11001100, $F7, %11001100, $FF, %00000000
frame2956:
	.byte %01000101, $D6, %11000000, $DE, %00001100, $E6, %00000000, $EF, %00000000, $F7, %00000000
frame2957:
	.byte %01000101, $D6, %00000000, $D7, %11111100, $DE, %00000000, $DF, %11001111, $E7, %11001100
frame2958:
	.byte %01000011, $D7, %11001100, $DF, %11001100, $E7, %00000000
frame2959:
	.byte %01000010, $D7, %00000000, $DF, %00000000
frame2960:
	.byte %01000001, $E0, %00000011
frame2961:
	.byte %01000001, $E0, %00001111
frame2962:
	.byte %01000001, $E1, %00000011
frame2963:
	.byte %01000001, $E1, %00001111
frame2964:
	.byte %01000010, $E0, %00001100, $E2, %00000011
frame2965:
	.byte %01000001, $E2, %00001111
frame2966:
	.byte %01000001, $E0, %00000000
frame2967:
	.byte %01000010, $E1, %00001100, $E3, %00000011
frame2968:
	.byte $88
frame2969:
	.byte $88
frame2970:
	.byte %01000001, $E3, %00001111
frame2971:
	.byte %01000001, $E1, %00000000
frame2972:
	.byte $88
frame2973:
	.byte %01000001, $E4, %00000011
frame2974:
	.byte $88
frame2975:
	.byte %01000001, $E2, %00001100
frame2976:
	.byte $88
frame2977:
	.byte %01000001, $E4, %00001111
frame2978:
	.byte $88
frame2979:
	.byte $88
frame2980:
	.byte $88
frame2981:
	.byte %01000001, $E5, %00000011
frame2982:
	.byte %01000001, $E2, %00000000
frame2983:
	.byte $88
frame2984:
	.byte %01000001, $DC, %11000000
frame2985:
	.byte $88
frame2986:
	.byte %01000011, $DC, %00000000, $E3, %00001100, $E5, %00001100
frame2987:
	.byte %01000011, $E3, %00000000, $E4, %00000000, $E5, %00000000
frame2988:
	.byte %01000011, $DD, %00110000, $E5, %00000011, $E6, %00000011
frame2989:
	.byte $88
frame2990:
	.byte %01000011, $DD, %00000000, $E5, %00000000, $E6, %00000000
frame2991:
	.byte %01000001, $DE, %11000000
frame2992:
	.byte %01000010, $DD, %11000000, $E5, %00001100
frame2993:
	.byte %01000100, $DC, %11110000, $DD, %11110000, $DE, %11110000, $E5, %00000000
frame2994:
	.byte %01000010, $DB, %11110000, $DF, %00110000
frame2995:
	.byte %01000011, $DE, %11110011, $DF, %11110000, $E6, %00000011
frame2996:
	.byte %01000010, $DE, %11111100, $E6, %00001100
frame2997:
	.byte %01000001, $DB, %11000000
frame2998:
	.byte %01000100, $DE, %11110000, $DF, %11110011, $E6, %00000000, $E7, %00000011
frame2999:
	.byte %01000010, $DF, %11110000, $E7, %00000000
frame3000:
	.byte %01000001, $DB, %00000000
frame3001:
	.byte $88
frame3002:
	.byte %01000001, $DC, %11000000
frame3003:
	.byte $88
frame3004:
	.byte $88
frame3005:
	.byte $88
frame3006:
	.byte $88
frame3007:
	.byte $88
frame3008:
	.byte $88
frame3009:
	.byte %01000001, $DC, %11110000
frame3010:
	.byte %01000110, $DB, %11000000, $E7, %11001100, $EF, %11111111, $F6, %00001100, $F7, %11111111, $FF, %00001111
frame3011:
	.byte %01000110, $DB, %11110000, $E6, %11000000, $E7, %11111111, $EE, %11001100, $F6, %11111111, $FE, %00001100
frame3012:
	.byte %01001001, $E6, %11111111, $E7, %00000000, $ED, %11000000, $EE, %11111111, $EF, %00110011, $F5, %11001100, $F7, %00111111, $FE, %00001111, $FF, %00000011
frame3013:
	.byte %01001000, $E5, %11001111, $E6, %00110011, $ED, %11111100, $EF, %00000000, $F5, %11111111, $F7, %00000000, $FD, %00001111, $FF, %00000000
frame3014:
	.byte %01001111, $DF, %11111100, $E4, %00001111, $E5, %11111111, $E6, %00000011, $E7, %11000000, $EC, %11000000, $ED, %11111111, $EE, %00110011, $EF, %11111100, $F4, %11001100, $F6, %00110011, $F7, %11001100, $FC, %00001100, $FE, %00000011, $FF, %00001100
frame3015:
	.byte %01001110, $E3, %00001111, $E4, %11001111, $E5, %00111111, $E6, %00000000, $E7, %11111111, $EC, %11111100, $ED, %11110011, $EE, %11000000, $EF, %11111111, $F4, %11111111, $F6, %00000000, $F7, %11111111, $FE, %00000000, $FF, %00001111
frame3016:
	.byte %01010001, $DF, %11111111, $E2, %00001111, $E4, %11111111, $E5, %00001111, $E6, %11001100, $E7, %00110011, $EB, %11000000, $EC, %11111111, $ED, %00110000, $EE, %11111111, $F3, %11001100, $F5, %00110011, $F6, %11001111, $FC, %00001111, $FD, %00000000, $FE, %00001100, $FF, %00000011
frame3017:
	.byte %01010010, $E1, %00001100, $E3, %11001111, $E4, %00111111, $E5, %00000011, $E6, %11111111, $E7, %00000000, $EB, %11111100, $EC, %11110011, $ED, %11001100, $EF, %00110011, $F3, %11001111, $F5, %00001100, $F6, %11111111, $F7, %00000011, $FB, %00001100, $FC, %00000011, $FE, %00001111, $FF, %00000000
frame3018:
	.byte %01010110, $DE, %11111100, $DF, %00111111, $E1, %00001111, $E3, %11111111, $E4, %00001111, $E5, %11001111, $E6, %00110011, $E7, %11001100, $EB, %11111111, $EC, %00110011, $ED, %11111111, $EE, %11110011, $EF, %11001100, $F3, %11111111, $F4, %00110011, $F5, %11001100, $F6, %00110011, $F7, %11001100, $FB, %00001111, $FC, %00000000, $FD, %00001100, $FE, %00000011
frame3019:
	.byte %01010011, $DF, %11111111, $E0, %00001100, $E3, %00111111, $E5, %11111111, $E6, %00000000, $E7, %11111111, $EA, %11001100, $EC, %11000000, $EE, %00110000, $EF, %11111111, $F2, %11001100, $F4, %00000000, $F5, %11111111, $F6, %00000000, $F7, %11111111, $FA, %00001100, $FD, %00001111, $FE, %00000000, $FF, %00001100
frame3020:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11000000
	.byte %00000000, %00000000, %00000000, %11110000, %11110000, %11110000, %11111111, %00111111
	.byte %00001111, %00001111, %11001111, %00001111, %11001111, %00110011, %11001100, %11110011
	.byte %00000000, %00000000, %11111111, %00110011, %11001100, %11110011, %11001100, %11111111
	.byte %00000000, %00000000, %11111111, %00110011, %11001100, %00110011, %11001100, %00111111
	.byte %00000000, %00000000, %00001100, %00000011, %00001100, %00000011, %00000000, %00000011

frame3021:
	.byte %01010111, $DF, %00001111, $E2, %11111111, $E4, %11111111, $E5, %00000000, $E6, %11111111, $E7, %00110000, $E9, %11000000, $EB, %00000000, $EC, %11111111, $ED, %00110011, $EE, %11111111, $EF, %00110011, $F3, %00000000, $F4, %11111111, $F5, %00000000, $F6, %11001111, $F7, %00000000, $FA, %00001111, $FB, %00000000, $FC, %00001111, $FD, %00000000, $FE, %00001100, $FF, %00000000
frame3022:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11110000
	.byte %00000000, %00000000, %00000000, %11110000, %11110000, %11111100, %00111111, %11001111
	.byte %00001111, %00001111, %00111111, %11001111, %00110011, %11001100, %11110011, %11001100
	.byte %00000000, %11001100, %11110011, %11001100, %11111111, %11001100, %11111111, %11001100
	.byte %00000000, %11001100, %00111111, %11001100, %00111111, %00000000, %00110011, %00000000
	.byte %00000000, %00001100, %00000011, %00000000, %00000011, %00000000, %00000011, %00000000

frame3023:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11000000, %11111100
	.byte %00000000, %00000000, %00000000, %11110000, %11110000, %11111100, %00111111, %11111111
	.byte %00001111, %11001111, %00001111, %11001111, %00110000, %11111100, %00110011, %11111111
	.byte %00000000, %11111100, %00110011, %11111111, %00110011, %11001111, %00110011, %11111111
	.byte %00000000, %11001111, %00110011, %11001100, %00110011, %11001100, %00000011, %00001100
	.byte %00000000, %00001100, %00000000, %00001100, %00000000, %00001100, %00000000, %00000000

frame3024:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11000000, %00111111
	.byte %00000000, %00000000, %00000000, %11110000, %11110000, %11111111, %11001111, %00110011
	.byte %00001111, %11111111, %00001111, %11111111, %00000000, %11111111, %11001100, %00111111
	.byte %00000000, %11111111, %00000000, %11111111, %00000000, %11111111, %00001100, %00110011
	.byte %00000000, %11111111, %00000000, %11111111, %00000000, %00111111, %00000000, %00000011
	.byte %00000000, %00001111, %00000000, %00001111, %00000000, %00000011, %00000000, %00000000

frame3025:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11110000, %11001111
	.byte %00000000, %00000000, %00000000, %11110000, %11110000, %00111111, %11111111, %11110000
	.byte %00001111, %00111111, %11001111, %00110011, %11001100, %00110011, %11111111, %11111111
	.byte %11001100, %11111111, %11001100, %00110011, %11001100, %00110011, %11001100, %00001100
	.byte %00001100, %00111111, %00001100, %00110011, %11001100, %00110011, %00001100, %00000000
	.byte %00000000, %00000011, %00000000, %00000011, %00000000, %00000000, %00000000, %00000000

frame3026:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %11000000, %11111100, %11110011
	.byte %00000000, %00000000, %00000000, %11110000, %11111100, %00111111, %11110011, %11001100
	.byte %11001111, %00111111, %11001111, %00110000, %11111100, %00001100, %11111111, %11111111
	.byte %11001100, %00110011, %11001100, %00110011, %11111111, %00000000, %00111111, %11001111
	.byte %11001100, %00110011, %11001100, %00000011, %11001100, %00000000, %00000011, %00001100
	.byte %00001100, %00000011, %00001100, %00000000, %00001100, %00000000, %00000000, %00000000

frame3027:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %11000000, %11111111, %00110000
	.byte %00000000, %00000000, %11000000, %11110000, %11111100, %11001111, %00110000, %11111111
	.byte %11001111, %00001111, %11111111, %00000000, %11110011, %11001100, %11111111, %11111111
	.byte %11111111, %00110011, %11111111, %00000000, %11111111, %11001100, %00110011, %00110011
	.byte %11001111, %00000000, %11111111, %00000000, %00110011, %00000000, %00000000, %00000011
	.byte %00001100, %00000000, %00001100, %00000000, %00000011, %00000000, %00000000, %00000000

frame3028:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %11110000, %11110011, %00000000
	.byte %00000000, %00000000, %11000000, %11110000, %11111100, %11111111, %11001100, %00110011
	.byte %11001111, %00001111, %00110011, %11001100, %00110011, %11111111, %11001100, %11111111
	.byte %11111111, %00001100, %11111111, %11001100, %00110011, %11001111, %11001100, %11001111
	.byte %11111111, %00000000, %00110011, %00001100, %00110011, %00001100, %00001100, %11001100
	.byte %00001111, %00000000, %00000011, %00000000, %00000000, %00000000, %00000000, %00001100

frame3029:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %11110000, %00110000, %00000000
	.byte %00000000, %00000000, %11000000, %11110000, %00111111, %00110011, %11111111, %00110000
	.byte %00111111, %11001111, %00110011, %11111100, %00001100, %00111111, %11111111, %11000011
	.byte %11111111, %11001100, %00110011, %11001111, %00000000, %00110011, %11111111, %11111111
	.byte %00111111, %11001100, %00110011, %11001100, %00000000, %00000011, %00000000, %11111111
	.byte %00000011, %00000000, %00000011, %00000000, %00000000, %00000000, %00000000, %00001100

frame3030:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %11110000, %00000000, %00000000
	.byte %00000000, %00000000, %11000000, %11110000, %11001111, %00110000, %11110011, %00000000
	.byte %00111111, %11001111, %00000011, %11110011, %11001100, %11111111, %00111111, %11110011
	.byte %00110011, %11001100, %00110011, %11111111, %11001100, %00000011, %11110011, %00110011
	.byte %00110011, %11001100, %00000000, %00110011, %00000000, %00000000, %00000011, %00110011
	.byte %00000011, %00001100, %00000000, %00000000, %00000000, %00000000, %00000000, %00000011

frame3031:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11111100
	.byte %00000000, %00000000, %00000000, %00000000, %11000000, %00110000, %00000000, %11001100
	.byte %00000000, %00000000, %11110000, %11111100, %11001111, %11001100, %00110000, %00001100
	.byte %00001111, %11111111, %11000000, %00110011, %11111111, %11001100, %11111111, %00110000
	.byte %00110011, %11111111, %00001100, %00110011, %11001100, %11001100, %11001100, %11111111
	.byte %00000011, %11001111, %00000000, %00110011, %00001100, %00001100, %11001100, %11001111
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00001100, %00001100

frame3032:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11001100
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11111100
	.byte %00000000, %00000000, %00000000, %00000000, %11000000, %00110000, %00001100, %11111111
	.byte %00000000, %00000000, %11110000, %11111100, %00110011, %11001111, %00000000, %11001100
	.byte %00001111, %00111111, %11001100, %00110000, %11111111, %11111111, %11000011, %00000000
	.byte %00000000, %11111111, %11001100, %00110011, %00110011, %11001111, %11111111, %11111100
	.byte %00000000, %00110011, %11001100, %00000000, %00000011, %00000000, %11001111, %11111111
	.byte %00000000, %00000011, %00000000, %00000000, %00000000, %00000000, %00000000, %00001100

frame3033:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11001100
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11111111
	.byte %00000000, %00000000, %00000000, %00000000, %11110000, %00000000, %00001100, %00111111
	.byte %00000000, %00000000, %11110000, %00111100, %00110011, %11110011, %00000000, %00110011
	.byte %00001111, %00111111, %11111100, %11001100, %00110011, %00110011, %11110011, %11000000
	.byte %11001100, %00110011, %11001111, %00000000, %00110011, %00110011, %00110011, %00111111
	.byte %00000000, %00110011, %11001100, %00000000, %00000000, %00000011, %00110011, %11111111
	.byte %00000000, %00000011, %00000000, %00000000, %00000000, %00000000, %00000011, %00001111

frame3034:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11111111
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11000000, %11111111
	.byte %00000000, %00000000, %00000000, %00000000, %00110000, %00000000, %11001111, %00111111
	.byte %00000000, %00000000, %11110000, %11111111, %00001100, %00110000, %00001100, %00110011
	.byte %11001111, %00110011, %11110011, %11001100, %11001111, %00111111, %00110000, %11001100
	.byte %11001100, %00110011, %11111111, %11001100, %00001100, %11111111, %11111111, %11111111
	.byte %11001100, %00000011, %00000011, %00000000, %00000000, %11001100, %11001111, %11111111
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00001100, %00001111

frame3035:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00001100, %11111111
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11000000, %11111111
	.byte %00000000, %00000000, %00000000, %00000000, %00110000, %00000000, %11001111, %11001111
	.byte %00000000, %00000000, %11110000, %11001111, %11001100, %00110000, %11001100, %00001100
	.byte %11001111, %00000011, %00110011, %11111111, %11001100, %11000000, %00000000, %11111100
	.byte %11001100, %00000000, %00110011, %11001100, %11001100, %11001100, %11001100, %11111111
	.byte %11001100, %00000000, %00110011, %00000000, %00001100, %11001100, %11001100, %11111111
	.byte %00001100, %00000000, %00000000, %00000000, %00000000, %00001100, %00001100, %00001111

frame3036:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11001100, %11111111
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11001100, %11111111
	.byte %00000000, %00000000, %00000000, %11000000, %00000000, %00000000, %11111111, %11001111
	.byte %00000000, %11000000, %11110000, %00110011, %11000011, %00000000, %11001111, %11000000
	.byte %11001111, %11000011, %00110000, %11111111, %11111111, %11000011, %00000000, %11111111
	.byte %11111111, %11001100, %00110011, %00110011, %00001111, %11111111, %11111111, %11111111
	.byte %11001100, %00000000, %00000011, %00000000, %00000000, %00111111, %00111111, %11111111
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00001111, %00001111

frame3037:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11111100, %11111111
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11111111, %11111111
	.byte %00000000, %00000000, %00000000, %11000000, %00000000, %00001100, %00111111, %11111111
	.byte %00000000, %11000000, %11111100, %00110011, %11110011, %00000000, %00110011, %11001111
	.byte %00111111, %11001100, %00110000, %00110011, %00110011, %00110000, %11000000, %11111111
	.byte %11111111, %11001100, %00000011, %00110011, %00110011, %00110011, %11111111, %11111111
	.byte %00000011, %00001100, %00000000, %00000000, %00000011, %00110011, %11111111, %11111111
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00001111, %00001111

frame3038:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11111111, %11111111
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11111111, %11111111
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %11001100, %11111111, %11111111
	.byte %00000000, %11000000, %00111100, %00001111, %00110000, %00001100, %00110011, %11111111
	.byte %00111111, %11001100, %11001100, %11111111, %00111111, %00110000, %11001100, %11111111
	.byte %00110011, %11001100, %00001100, %00000011, %11111111, %11111111, %11111111, %11111111
	.byte %00110011, %11001100, %00000000, %00000000, %00001100, %11001111, %11001111, %11111111
	.byte %00000011, %00000000, %00000000, %00000000, %00000000, %00000000, %00001100, %00001111

frame3039:
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %11000000, %11111111, %11111111
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11111111, %11111111
	.byte %00000000, %00000000, %00000000, %00000000, %00000000, %11001100, %11111111, %11111111
	.byte %00000000, %11000000, %11111100, %11001100, %00110000, %11001100, %00000000, %11111111
	.byte %00111111, %11110000, %11001100, %11001100, %11000000, %00000000, %11111100, %11111111
	.byte %00110011, %11111111, %11001100, %11001100, %11001100, %11001100, %11001111, %11111111
	.byte %00110011, %00000000, %00000000, %00000000, %11001100, %11001100, %11111111, %11111111
	.byte %00000000, %00000000, %00000000, %00000000, %00001100, %00001100, %00001111, %00001111

frame3040:
	.byte %01010100, $C6, %11111100, $CD, %11001100, $D6, %11001111, $D9, %11110000, $DB, %11000011, $DC, %00000000, $DE, %11001100, $E1, %00110011, $E2, %11001111, $E4, %11000011, $E9, %00110011, $EC, %11111111, $ED, %11110000, $EE, %11111111, $F0, %00000011, $F1, %00000011, $F4, %00001100, $F5, %00001111, $FC, %00000000, $FD, %00000000
frame3041:
	.byte %01010010, $C6, %11111111, $D5, %11111111, $D6, %11111111, $DA, %00111111, $DD, %00001111, $E0, %00001111, $E2, %11111111, $E3, %11111111, $E6, %11111111, $E8, %00000011, $EA, %00000011, $EB, %00001100, $EC, %00110011, $ED, %00110011, $F0, %00000000, $F4, %00110011, $F5, %00110011, $FD, %00001111
frame3042:
	.byte %01010101, $C5, %11110000, $CD, %11001111, $D5, %00111111, $DB, %00110011, $DD, %00110011, $DE, %11001111, $DF, %11110011, $E0, %11000011, $E1, %00110000, $E2, %00110011, $E3, %00110011, $E4, %00110000, $E5, %11000000, $E8, %00001100, $EA, %00110011, $EB, %00110011, $EC, %11110011, $ED, %11111100, $F1, %00000000, $F5, %11111111, $FD, %00001100
frame3043:
	.byte %01001011, $CD, %11111111, $D5, %11111111, $DB, %00110000, $DE, %11111111, $E3, %00111111, $E5, %11001100, $E8, %11001100, $E9, %00000011, $EB, %11111111, $F4, %11001111, $F5, %11001100
frame3044:
	.byte %01010011, $C7, %11110011, $D4, %11000000, $DA, %00001111, $DC, %00001100, $DD, %00000011, $DF, %00110000, $E0, %11001111, $E1, %11001100, $E2, %11110011, $E9, %00000000, $EA, %00000011, $EB, %11001111, $EC, %11001100, $ED, %11001100, $F0, %00001100, $F3, %00001100, $F4, %11001100, $FC, %00001100, $FD, %00001111
frame3045:
	.byte %01010100, $C7, %00110011, $CC, %11001100, $CF, %11110011, $D4, %11001100, $D5, %11001111, $DA, %11001111, $DB, %00000000, $DC, %11001100, $DD, %00001100, $E2, %11001111, $E3, %11000000, $E4, %00000000, $E5, %11111100, $E9, %00001100, $EA, %00001100, $EB, %11001100, $ED, %11001111, $F3, %11001100, $F5, %11111111, $FC, %00000000
frame3046:
	.byte %01010000, $C4, %11000000, $C5, %11000000, $C7, %00110000, $D5, %11111111, $D7, %00110011, $DA, %11000011, $DF, %00000000, $E2, %11001100, $E3, %11000011, $E7, %11110011, $E9, %11001100, $EA, %11001100, $EC, %11110000, $ED, %11111111, $F3, %00001100, $F4, %00000011
frame3047:
	.byte %01010001, $C5, %11110000, $C6, %11110011, $CF, %00110011, $D4, %11111100, $D8, %11000000, $D9, %11111100, $DD, %11001100, $E0, %11110011, $E5, %11111111, $E7, %00110011, $E8, %11001111, $EB, %11111111, $EC, %00110011, $F0, %00000000, $F3, %00000000, $F4, %00110011, $FF, %00000011
frame3048:
	.byte %01010000, $C6, %11110000, $C7, %00000000, $CC, %11111100, $CF, %00110000, $D9, %00111100, $DC, %11001111, $DE, %11110011, $E2, %11111100, $E8, %00110011, $E9, %00001100, $EA, %00001100, $EB, %00110011, $EF, %11110011, $F3, %00000011, $F7, %00110011, $FC, %00001100
frame3049:
	.byte %01010011, $CC, %11111111, $CF, %00000000, $D7, %00000011, $DA, %00110000, $DC, %00111111, $DD, %11001111, $DE, %00110011, $E0, %00110011, $E1, %11111111, $E2, %11110011, $E3, %00110000, $E4, %11000000, $E7, %00110000, $E9, %00000000, $EA, %00000011, $EC, %00111111, $EF, %00110011, $F3, %00110011, $F4, %11110011
frame3050:
	.byte %01001100, $C4, %00000000, $D4, %00111111, $D7, %00000000, $DC, %00110011, $E1, %00110011, $E2, %00111111, $E9, %00000011, $EA, %00110011, $EB, %11110011, $EC, %11111100, $F0, %00000011, $F4, %11001100
frame3051:
	.byte %01001000, $C6, %00110000, $D4, %11111111, $E7, %00000000, $EC, %11001100, $EF, %11110011, $F3, %00001111, $F7, %00000011, $FF, %00000000
frame3052:
	.byte %01001000, $CE, %00110011, $E4, %11001100, $E9, %00110011, $EA, %11111111, $EB, %11111111, $EF, %11111100, $F3, %11001100, $F7, %00001100
frame3053:
	.byte %01000111, $D6, %00111111, $DD, %11111111, $DE, %00000000, $EB, %11001100, $EF, %11001100, $F0, %00000000, $F7, %11001100
frame3054:
	.byte %01001011, $C4, %11000000, $CB, %11000000, $DB, %00001100, $E0, %00110000, $E2, %00110011, $E3, %00000000, $E6, %11110011, $E8, %00000011, $E9, %00000011, $EA, %11001111, $F2, %00001100
frame3055:
	.byte %01001100, $D3, %11000000, $D6, %00110011, $D9, %00001100, $DA, %00000000, $DB, %11001100, $DC, %00001111, $E1, %11110011, $E2, %11110011, $EA, %11001100, $F3, %00001100, $F4, %11111100, $FC, %00001111
frame3056:
	.byte %01001010, $C6, %00000000, $CB, %11001100, $D9, %11000000, $DE, %00000011, $E2, %11110000, $E4, %11111100, $E6, %00110011, $EC, %11001111, $F2, %11001100, $F7, %00001100
frame3057:
	.byte %01001010, $D4, %11001111, $DE, %00000000, $E1, %11111111, $E8, %00000000, $E9, %00000000, $EB, %11000000, $EC, %11111111, $F4, %11111111, $F6, %00111111, $FE, %00000011
frame3058:
	.byte %01001000, $D9, %11000011, $DC, %00001100, $E0, %00000000, $E2, %11000000, $EB, %11110000, $EF, %11110000, $F3, %00000000, $F7, %00000000
frame3059:
	.byte %01000100, $E0, %11001100, $E9, %00001100, $EE, %11110011, $F6, %00110011
frame3060:
	.byte %01000010, $DC, %11001100, $F2, %00001100
frame3061:
	.byte $88
frame3062:
	.byte $88
frame3063:
	.byte $88
frame3064:
	.byte $88
frame3065:
	.byte $88
frame3066:
	.byte $88
frame3067:
	.byte %01000010, $E1, %11111100, $E7, %00110000
frame3068:
	.byte %01000010, $E1, %11001100, $EF, %00110000
frame3069:
	.byte $88
frame3070:
	.byte %01000010, $DC, %00001100, $EF, %00110011
frame3071:
	.byte $88
frame3072:
	.byte %01000001, $E7, %11110000
frame3073:
	.byte $88
frame3074:
	.byte $88
frame3075:
	.byte $88
frame3076:
	.byte $88
frame3077:
	.byte $88
frame3078:
	.byte $88
frame3079:
	.byte %01000011, $CE, %00110000, $EE, %00110011, $F7, %00000011
frame3080:
	.byte %01000010, $D4, %11111111, $EB, %00110000
frame3081:
	.byte %01000001, $CC, %11111100
frame3082:
	.byte %01000001, $E6, %11110011
frame3083:
	.byte %01000001, $E1, %11001111
frame3084:
	.byte $88
frame3085:
	.byte %01000001, $DC, %11001100
frame3086:
	.byte $88
frame3087:
	.byte %01000010, $CE, %00000000, $DC, %00001100
frame3088:
	.byte %01000001, $CC, %11111111
frame3089:
	.byte %01000001, $E0, %00111100
frame3090:
	.byte %01000001, $D6, %00000011
frame3091:
	.byte %01000011, $D3, %11001100, $E1, %11111111, $E3, %00110000
frame3092:
	.byte %01000010, $DD, %11110011, $E0, %00110000
frame3093:
	.byte %01000101, $C5, %00110000, $D8, %11110000, $D9, %00000011, $E9, %00000000, $EB, %11000000
frame3094:
	.byte %01000001, $D6, %00000000
frame3095:
	.byte %01000101, $D6, %00000011, $D9, %00001111, $DA, %00110000, $E8, %00000011, $EB, %11001100
frame3096:
	.byte %01000101, $D3, %11111100, $D9, %00111111, $DD, %11111111, $E1, %11110011, $E2, %11000011
frame3097:
	.byte %01000101, $DD, %11110011, $E0, %00110011, $E1, %00110011, $E2, %11001111, $E7, %00110000
frame3098:
	.byte %01000011, $C4, %11110000, $CB, %00001100, $E2, %11111111
frame3099:
	.byte %01000010, $D3, %11001100, $DD, %11111111
frame3100:
	.byte %01000010, $E2, %00111111, $E3, %11110000
frame3101:
	.byte %01000010, $CB, %00000000, $D3, %11001111
frame3102:
	.byte %01000010, $C5, %11110000, $E9, %00000011
frame3103:
	.byte %01000010, $D3, %11001100, $D9, %00110011
frame3104:
	.byte %01000001, $CB, %11000000
frame3105:
	.byte %01001001, $C4, %11000000, $D3, %00001100, $D9, %00111111, $DB, %00001100, $DC, %00001111, $DD, %11110011, $E2, %00110011, $E8, %00110011, $F3, %00001100
frame3106:
	.byte %01000100, $D9, %00001111, $DA, %00110011, $DB, %00000000, $E0, %00111111
frame3107:
	.byte %01000101, $E0, %00111100, $E3, %11000000, $E8, %00000011, $EA, %11001111, $F2, %00000000
frame3108:
	.byte %01000100, $DA, %00000011, $E0, %00001100, $E7, %00000000, $E8, %00000000
frame3109:
	.byte %01001000, $D9, %11001111, $DA, %11000011, $DC, %00111111, $E0, %11001100, $E9, %00000000, $EA, %00001111, $EB, %11001111, $EE, %00111111
frame3110:
	.byte %01000011, $CB, %00000000, $DC, %11001111, $E1, %00001100
frame3111:
	.byte %01000100, $DC, %11001100, $E6, %11110000, $E7, %00110000, $EA, %00000011
frame3112:
	.byte %01000010, $CE, %00000011, $E6, %00110000
frame3113:
	.byte %01000010, $D4, %11001111, $E3, %11110000
frame3114:
	.byte %01000001, $F3, %11001100
frame3115:
	.byte %01000100, $CE, %00000000, $D6, %00110011, $DD, %11111111, $EE, %00110011
frame3116:
	.byte $88
frame3117:
	.byte %01000011, $E8, %00001100, $EA, %00000000, $EE, %00000011
frame3118:
	.byte %01000001, $F7, %00000000
frame3119:
	.byte %01000011, $E6, %00000000, $F3, %00001100, $F6, %00110000
frame3120:
	.byte %01000010, $E1, %11001100, $E7, %11110000
frame3121:
	.byte %01000100, $E4, %11111111, $E7, %11111100, $EB, %11111111, $FE, %00000000
frame3122:
	.byte %01000010, $C4, %11110000, $D6, %00000011
frame3123:
	.byte %01000001, $D9, %11000011
frame3124:
	.byte %01000010, $DA, %00000011, $E9, %00001100
frame3125:
	.byte %01000010, $DA, %00110011, $F6, %00000000
frame3126:
	.byte %01000011, $D9, %00000011, $DD, %11110011, $E3, %11000000
frame3127:
	.byte %01000001, $F3, %00001111
frame3128:
	.byte $88
frame3129:
	.byte %01000011, $E3, %11110000, $E6, %00110000, $F3, %00000011
frame3130:
	.byte $88
frame3131:
	.byte %01000001, $EF, %00111111
frame3132:
	.byte %01000001, $D6, %00000000
frame3133:
	.byte $88
frame3134:
	.byte %01000010, $DA, %00110000, $E0, %11001111
frame3135:
	.byte %01000001, $EE, %00110011
frame3136:
	.byte %01000001, $E1, %11001111
frame3137:
	.byte $88
frame3138:
	.byte $88
frame3139:
	.byte %01000010, $D9, %00110011, $F3, %00001111
frame3140:
	.byte $88
frame3141:
	.byte %01001000, $CB, %11000000, $E1, %00001111, $E2, %00111111, $E8, %11001100, $E9, %00000000, $EA, %00001100, $EF, %00001111, $F3, %00001100
frame3142:
	.byte %01001000, $D4, %11111111, $E1, %00000011, $E2, %11111111, $E3, %11000000, $E7, %11001100, $E8, %00001100, $EB, %11001111, $EF, %11001111
frame3143:
	.byte %01000111, $C5, %00110000, $CB, %11001100, $DC, %11001111, $E0, %11001100, $EB, %11001100, $EF, %11001100, $F6, %00000011
frame3144:
	.byte %01001000, $D3, %00001111, $DC, %11111100, $E6, %11110000, $E8, %00000000, $EA, %00001111, $EE, %00111111, $EF, %00001100, $F6, %00000000
frame3145:
	.byte %01000101, $DD, %00110011, $E6, %11000000, $E7, %11000000, $EE, %11001111, $FB, %00001100
frame3146:
	.byte %01001001, $D5, %00111111, $D9, %00111111, $DD, %00110000, $E7, %11110011, $EA, %11001111, $EB, %00001111, $EE, %11001100, $EF, %00000000, $F3, %00000000
frame3147:
	.byte %01001010, $CD, %00110011, $E0, %00001100, $E1, %00110011, $E3, %00000000, $E6, %11000011, $E7, %00110011, $EA, %11001100, $EB, %00000011, $EF, %00000011, $F3, %11000000
frame3148:
	.byte %01001000, $DC, %11111111, $DF, %11000000, $E2, %11001111, $E3, %00110000, $E5, %11110011, $E6, %11001111, $EE, %00001100, $EF, %00110011
frame3149:
	.byte %01001011, $C3, %11000000, $D8, %11000000, $E1, %00111111, $E2, %11001100, $E3, %00111100, $E5, %11111111, $E6, %00111111, $E7, %11111111, $EB, %00110011, $ED, %11001111, $EE, %00000000
frame3150:
	.byte %01001010, $C5, %00000000, $D5, %00110011, $E3, %11111100, $E7, %11111100, $E9, %00000011, $EE, %00000011, $EF, %00001111, $F3, %11001100, $F5, %11111100, $FB, %00001111
frame3151:
	.byte %01010000, $D3, %11001111, $D5, %00000011, $DB, %11000000, $DF, %11110000, $E0, %00001111, $E6, %11111111, $E7, %11001100, $E9, %00000000, $EA, %00001100, $EB, %00111111, $ED, %00000011, $EE, %00110011, $EF, %00000000, $F3, %11001111, $F5, %00110000, $FD, %00000011
frame3152:
	.byte %01001111, $CB, %11111111, $CD, %00110000, $D5, %00000000, $DD, %00000000, $DF, %00111100, $E0, %11000011, $E1, %11111111, $E5, %00111111, $E7, %00000011, $E8, %00110011, $EB, %11111111, $ED, %00110011, $EE, %00111111, $F3, %11111100, $F5, %00110011
frame3153:
	.byte %01001100, $CD, %00000000, $D2, %00001100, $D8, %00000000, $D9, %00111100, $DC, %11110011, $DE, %11000000, $DF, %11111100, $E3, %11111111, $E5, %00110011, $E6, %11001100, $E7, %00001111, $EE, %00001100
frame3154:
	.byte %01001001, $DF, %11110011, $E0, %11001100, $E5, %11111111, $E6, %00000000, $E7, %00111111, $EC, %11110011, $EE, %00000000, $FA, %00001100, $FB, %00001100
frame3155:
	.byte %01001011, $DA, %00000000, $DE, %11110000, $E0, %11111100, $E1, %00111111, $E2, %11000011, $E6, %00000011, $E7, %11001100, $E8, %00110000, $EB, %11001111, $EC, %00110011, $FB, %00001111
frame3156:
	.byte %01001110, $C3, %11110000, $C4, %00110000, $D4, %00111111, $DA, %11110000, $DE, %11111100, $E1, %00110011, $E5, %11111100, $E6, %00110011, $E7, %00001100, $E8, %00001111, $EC, %00111111, $ED, %00000000, $F3, %11111111, $F5, %00000000
frame3157:
	.byte %01010001, $D9, %11001100, $DA, %11110011, $DB, %11001100, $DC, %00110011, $DD, %11000000, $DE, %11001111, $DF, %00110000, $E0, %11000000, $E1, %00111111, $E3, %11001111, $E5, %00000011, $E6, %00111100, $E7, %11001111, $E8, %00111111, $EC, %11111111, $F2, %11000000, $FD, %00000000
frame3158:
	.byte %01001000, $D4, %00110011, $D9, %11000000, $DE, %11111111, $E3, %11111111, $E5, %00001111, $E6, %00000000, $F3, %11001111, $FA, %00000000
frame3159:
	.byte %01001101, $D3, %11111111, $D9, %00000000, $DA, %11111111, $DB, %11111100, $DC, %11110011, $DD, %00111100, $DE, %11110011, $DF, %00000000, $E0, %00000000, $E1, %00111100, $E2, %00001111, $E9, %00000011, $FA, %00001100
frame3160:
	.byte %01001101, $CA, %11000000, $CC, %00111111, $DA, %11111100, $DE, %00110000, $E1, %11111100, $E3, %11111100, $E5, %00001100, $E7, %11000011, $E8, %11111100, $EA, %00000000, $EB, %11001100, $EC, %00111111, $F4, %11110011
frame3161:
	.byte %01001101, $CA, %11001100, $DA, %11000000, $DD, %00111111, $E1, %11000000, $E2, %00111111, $E5, %00000000, $E6, %00001100, $E7, %00000011, $E8, %11000000, $E9, %00111111, $EC, %00110011, $F0, %00000011, $F4, %00110011
frame3162:
	.byte %01001011, $DB, %11111111, $DD, %11000011, $DE, %00000000, $E1, %00000000, $E2, %11111111, $E3, %11111111, $E4, %00111111, $E7, %00000000, $E9, %11111100, $EA, %00000011, $F0, %00001111
frame3163:
	.byte %01001110, $DA, %00000000, $DB, %11111100, $DC, %11111111, $DD, %11110000, $E2, %11000000, $E6, %00000011, $E8, %00000000, $E9, %11000000, $EA, %00111111, $EB, %11111111, $F0, %00000000, $F1, %00001111, $F2, %00000000, $F3, %11111111
frame3164:
	.byte %01000111, $DD, %00110011, $E2, %00000000, $E6, %00000000, $E9, %00000000, $EA, %11110000, $F1, %11111100, $F2, %00111111
frame3165:
	.byte %01001000, $C4, %11110000, $DC, %11110011, $E4, %11111111, $EA, %00000000, $EC, %11111111, $F1, %00000000, $F2, %11001100, $F4, %11111111
frame3166:
	.byte %01000111, $DD, %00110000, $E5, %00110011, $EC, %11110011, $ED, %00110000, $F2, %00000000, $F5, %00110000, $FA, %00000000
frame3167:
	.byte %01000110, $D2, %00000000, $DB, %11111111, $DD, %11111100, $E5, %11001111, $ED, %00000000, $F5, %00000000
frame3168:
	.byte %01001110, $CA, %11000000, $DC, %00110011, $DD, %11110000, $DE, %00110011, $E4, %00111111, $E5, %11000011, $E6, %11110000, $EC, %00110011, $ED, %11000000, $EE, %11111100, $EF, %00110000, $F4, %00110011, $F6, %11111100, $F7, %11110011
frame3169:
	.byte %01001110, $D4, %00111111, $DD, %11000000, $DE, %11110011, $E5, %00001111, $E6, %11000000, $E7, %00110000, $EB, %11001111, $EC, %11111111, $ED, %00000000, $EE, %00000000, $EF, %11000011, $F4, %11110011, $F6, %00000000, $F7, %00001111
frame3170:
	.byte %01001110, $CA, %00000000, $CC, %11111111, $D4, %11111111, $DA, %11111100, $DB, %11111100, $DC, %11110011, $DD, %00000000, $DE, %11111100, $DF, %00110000, $E4, %11111111, $E6, %00000000, $E7, %11110011, $EF, %11001100, $F7, %00000000
frame3171:
	.byte %01000101, $CD, %00000011, $DA, %11110011, $E7, %11000000, $EB, %11001100, $EF, %00000000
frame3172:
	.byte %01000111, $D2, %00001100, $D9, %11001100, $DA, %11000011, $DC, %11111111, $DE, %11110000, $DF, %11110000, $E7, %11001100
frame3173:
	.byte %01001001, $C4, %00110000, $CD, %00110011, $D2, %00000000, $D9, %00111100, $DA, %11110000, $E5, %00000011, $E7, %00001100, $EB, %11111100, $F4, %11111111
frame3174:
	.byte %01000100, $D8, %11000000, $D9, %00111111, $E3, %11001111, $E6, %00000011
frame3175:
	.byte %01000010, $D9, %00001111, $E3, %11111111
frame3176:
	.byte %01000010, $D8, %11110000, $D9, %11000011
frame3177:
	.byte %01000100, $C3, %11000000, $D5, %00110000, $DA, %00000000, $EB, %11111111
frame3178:
	.byte %01000110, $D3, %11001111, $D5, %00110011, $D8, %00110000, $D9, %11110011, $DF, %00110000, $E5, %00001111
frame3179:
	.byte %01000101, $D8, %11110000, $DC, %11110011, $DD, %00000011, $E5, %00001100, $E6, %00001111
frame3180:
	.byte %01000100, $D4, %00111111, $D9, %00110011, $E1, %00001100, $E2, %00000011
frame3181:
	.byte %01000011, $DB, %11110000, $DE, %11000000, $E0, %00000011
frame3182:
	.byte %01000010, $D9, %11110000, $E1, %00001111
frame3183:
	.byte %01000001, $E7, %00001111
frame3184:
	.byte %01000100, $D8, %11000000, $E6, %00000011, $F3, %11111100, $FA, %00001100
frame3185:
	.byte %01000001, $E1, %00001100
frame3186:
	.byte %01000010, $DF, %00000000, $E7, %00001100
frame3187:
	.byte %01000011, $DE, %00000000, $E0, %00001111, $E7, %00000000
frame3188:
	.byte %01000011, $CD, %00110000, $E1, %00111100, $E7, %11000000
frame3189:
	.byte %01000101, $C3, %00000000, $DE, %00110000, $E0, %00000011, $E1, %00001100, $F3, %11111111
frame3190:
	.byte %01000101, $E1, %11001100, $E5, %00000000, $E6, %00000000, $F2, %11000000, $FD, %00000011
frame3191:
	.byte %01000111, $C4, %00000000, $D8, %00000000, $E0, %00001111, $E1, %11001111, $E6, %00001100, $E7, %11000011, $F4, %11110011
frame3192:
	.byte %01000001, $DC, %11110000
frame3193:
	.byte %01000100, $D3, %11111111, $E2, %00110011, $E5, %11001100, $E6, %00001111
frame3194:
	.byte %01000010, $D9, %00110000, $E5, %11001111
frame3195:
	.byte %01000111, $D4, %11111111, $DB, %11111100, $E0, %11111111, $E2, %00110000, $EB, %11001111, $F2, %11001100, $FA, %00000000
frame3196:
	.byte %01000011, $D3, %11001111, $E1, %00000011, $FA, %00000011
frame3197:
	.byte %01000101, $E0, %00111111, $E7, %11000000, $E8, %00000011, $EA, %00001100, $F2, %00111100
frame3198:
	.byte %01000100, $E5, %00001111, $E6, %11001111, $F1, %11000000, $FA, %00000000
frame3199:
	.byte %01000100, $D4, %00111111, $EA, %11001111, $F1, %00000000, $F2, %00111111
frame3200:
	.byte %01000101, $E2, %00000000, $E5, %00111111, $E8, %00000000, $EA, %11001100, $F1, %00001100
frame3201:
	.byte %01000011, $E7, %11001100, $F2, %00000011, $F5, %00110000
frame3202:
	.byte %01000111, $DC, %00110000, $E1, %11000000, $E2, %00110000, $E6, %00001111, $E9, %11000000, $EA, %11001111, $F1, %00000000
frame3203:
	.byte %01000010, $EA, %11111111, $EF, %00001100
frame3204:
	.byte %01000011, $E2, %11110000, $EA, %11111100, $F2, %00000000
frame3205:
	.byte %01000110, $D8, %11000000, $DF, %00110000, $E5, %00001111, $E7, %11111100, $E9, %11001100, $EF, %00000000
frame3206:
	.byte %01000001, $EF, %00000011
frame3207:
	.byte %01000010, $D4, %00110011, $EF, %00000000
frame3208:
	.byte %01000011, $C4, %00110000, $DC, %11110000, $E9, %11000000
frame3209:
	.byte %01000010, $D5, %00110000, $EA, %11110000
frame3210:
	.byte %01000101, $C3, %11000000, $E2, %11111100, $E7, %00110000, $EA, %11000000, $EF, %00001100
frame3211:
	.byte %01000001, $F1, %00001100
frame3212:
	.byte %01000010, $D9, %00000000, $F2, %00000011
frame3213:
	.byte %01000011, $DE, %00000000, $E9, %00000000, $F4, %11111111
frame3214:
	.byte %01000011, $DC, %11110011, $EF, %00000000, $F1, %00001111
frame3215:
	.byte %01000100, $DE, %00001100, $E6, %11001111, $E7, %00000000, $EF, %00000011
frame3216:
	.byte %01000001, $F1, %00001100
frame3217:
	.byte %01000011, $E6, %11000011, $E7, %00001100, $EF, %00000000
frame3218:
	.byte %01000010, $D5, %00110011, $E6, %00000011
frame3219:
	.byte %01000101, $D4, %00111111, $E1, %00000000, $E5, %11001111, $E6, %00110011, $E7, %11001100
frame3220:
	.byte $88
frame3221:
	.byte %01000010, $DE, %00000000, $E6, %00000000
frame3222:
	.byte %01000010, $E7, %11001111, $EF, %00001100
frame3223:
	.byte %01000001, $DE, %00110000
frame3224:
	.byte %01000010, $D9, %11000000, $EF, %00000000
frame3225:
	.byte %01000010, $DD, %00000000, $E7, %11111111
frame3226:
	.byte $88
frame3227:
	.byte %01000011, $DD, %00000011, $E1, %00000011, $E2, %11001100
frame3228:
	.byte %01000010, $E5, %00001111, $E7, %11001111
frame3229:
	.byte %01000011, $E0, %11111111, $E5, %00110011, $E6, %00001100
frame3230:
	.byte %01000001, $E6, %11001100
frame3231:
	.byte $88
frame3232:
	.byte $88
frame3233:
	.byte %01000010, $E0, %00111111, $E6, %00001100
frame3234:
	.byte $88
frame3235:
	.byte $88
frame3236:
	.byte %01000010, $ED, %00000011, $F3, %11111100
frame3237:
	.byte %01000001, $EE, %00000011
frame3238:
	.byte %01000001, $E6, %00111100
frame3239:
	.byte %01000001, $ED, %00000000
frame3240:
	.byte %01000001, $CD, %00110011
frame3241:
	.byte %01000001, $E5, %00110000
frame3242:
	.byte %01000001, $E5, %00000000
frame3243:
	.byte $88
frame3244:
	.byte %01000100, $D9, %11110000, $DE, %00000000, $E1, %11000011, $F4, %11110011
frame3245:
	.byte %01000011, $E2, %00001100, $E9, %00001100, $F5, %00110011
frame3246:
	.byte $88
frame3247:
	.byte %01000010, $DB, %11110000, $FD, %00000000
frame3248:
	.byte %01000001, $FD, %00001100
frame3249:
	.byte %01000100, $DE, %11000000, $E2, %00000000, $EC, %00111111, $F5, %11110011
frame3250:
	.byte %01000001, $F5, %11000011
frame3251:
	.byte %01000010, $DB, %11000000, $E6, %11111100
frame3252:
	.byte %01000011, $ED, %00110000, $F5, %11001111, $FD, %00000000
frame3253:
	.byte %01000011, $E7, %11111111, $ED, %00111100, $F6, %00000011
frame3254:
	.byte %01000100, $E1, %11110011, $EE, %00110011, $F5, %00001100, $F6, %00000000
frame3255:
	.byte %01000001, $E0, %00111100
frame3256:
	.byte %01000010, $ED, %11111100, $EF, %00001100
frame3257:
	.byte $88
frame3258:
	.byte %01000010, $E9, %00000000, $F5, %00000000
frame3259:
	.byte %01000001, $EE, %00110000
frame3260:
	.byte %01000101, $E0, %11111100, $E1, %00110011, $ED, %00111100, $EE, %00000000, $F5, %00001100
frame3261:
	.byte %01000010, $ED, %00110000, $F6, %00000011
frame3262:
	.byte $88
frame3263:
	.byte %01000010, $DB, %11110000, $E6, %11001100
frame3264:
	.byte %01000001, $F6, %00001111
frame3265:
	.byte %01000011, $E0, %11111111, $E1, %00000011, $E6, %00001100
frame3266:
	.byte %01000001, $F6, %00000000
frame3267:
	.byte $88
frame3268:
	.byte $88
frame3269:
	.byte %01000001, $E8, %00000011
frame3270:
	.byte $88
frame3271:
	.byte %01000010, $E0, %11111100, $F6, %11000000
frame3272:
	.byte $88
frame3273:
	.byte $88
frame3274:
	.byte %01000001, $C4, %11110000
frame3275:
	.byte %01000001, $DB, %11111100
frame3276:
	.byte %01000001, $E0, %00111100
frame3277:
	.byte $88
frame3278:
	.byte $88
frame3279:
	.byte %01000011, $D8, %00000000, $E5, %00110000, $F1, %00111100
frame3280:
	.byte $88
frame3281:
	.byte %01000001, $E2, %11000000
frame3282:
	.byte $88
frame3283:
	.byte %01000010, $E0, %11111100, $F6, %11110011
frame3284:
	.byte $88
frame3285:
	.byte %01000011, $D9, %00110000, $DF, %00000000, $F1, %11111100
frame3286:
	.byte $88
frame3287:
	.byte %01000001, $ED, %00110011
frame3288:
	.byte $88
frame3289:
	.byte %01000001, $C3, %11110000
frame3290:
	.byte $88
frame3291:
	.byte $88
frame3292:
	.byte %01000010, $E6, %11001100, $EF, %11001100
frame3293:
	.byte $88
frame3294:
	.byte %01000010, $EA, %11001100, $EF, %11001111
frame3295:
	.byte %01000001, $E6, %11111100
frame3296:
	.byte %01000001, $EF, %00001111
frame3297:
	.byte %01000001, $E1, %00110011
frame3298:
	.byte %01000010, $E7, %00111111, $EF, %00000011
frame3299:
	.byte %01000100, $E1, %11110011, $E8, %00000000, $EA, %11000000, $EF, %00000000
frame3300:
	.byte %01000001, $E8, %00001100
frame3301:
	.byte %01000001, $E8, %00000000
frame3302:
	.byte %01000001, $EE, %00001100
frame3303:
	.byte %01000001, $E0, %11001100
frame3304:
	.byte %01000001, $E7, %00001111
frame3305:
	.byte $88
frame3306:
	.byte %01000011, $E0, %00001100, $ED, %00110000, $EE, %00000000
frame3307:
	.byte $88
frame3308:
	.byte $88
frame3309:
	.byte %01000001, $E2, %00000000
frame3310:
	.byte %01000011, $E5, %00111100, $E7, %00000011, $EE, %00000011
frame3311:
	.byte %01000001, $E5, %00111111
frame3312:
	.byte %01000010, $E5, %00110011, $E7, %00000000
frame3313:
	.byte %01000010, $E5, %00001111, $E9, %00001100
frame3314:
	.byte %01000001, $F1, %11110000
frame3315:
	.byte %01000010, $E0, %00000000, $E1, %11000011
frame3316:
	.byte $88
frame3317:
	.byte %01000010, $E2, %00001100, $E6, %00111100
frame3318:
	.byte $88
frame3319:
	.byte %01000001, $E1, %11001111
frame3320:
	.byte $88
frame3321:
	.byte %01000001, $E2, %00001111
frame3322:
	.byte %01000001, $D3, %11111111
frame3323:
	.byte %01000001, $E6, %00111111
frame3324:
	.byte %01000010, $F0, %11000000, $F6, %00110011
frame3325:
	.byte %01000001, $EC, %11111111
frame3326:
	.byte $88
frame3327:
	.byte %01000001, $F0, %00000000
frame3328:
	.byte %01000001, $E2, %00111111
frame3329:
	.byte %01000001, $F3, %11111111
frame3330:
	.byte %01000010, $E5, %11001111, $EB, %11111111
frame3331:
	.byte $88
frame3332:
	.byte %01000001, $F4, %11111111
frame3333:
	.byte $88
frame3334:
	.byte %01000001, $EC, %00111111
frame3335:
	.byte %01000001, $F5, %00001111
frame3336:
	.byte %01000001, $F6, %00110000
frame3337:
	.byte %01000011, $DF, %11000000, $EB, %11001111, $F1, %11000000
frame3338:
	.byte $88
frame3339:
	.byte %01000001, $F2, %00001111
frame3340:
	.byte %01000001, $E0, %00000011
frame3341:
	.byte $88
frame3342:
	.byte $88
frame3343:
	.byte %01000001, $E9, %11001100
frame3344:
	.byte $88
frame3345:
	.byte %01000010, $CA, %11000000, $E7, %00001100
frame3346:
	.byte $88
frame3347:
	.byte %01000001, $D8, %00110000
frame3348:
	.byte $88
frame3349:
	.byte $88
frame3350:
	.byte %01000001, $E6, %11111111
frame3351:
	.byte $88
frame3352:
	.byte %01000001, $CA, %00000000
frame3353:
	.byte %01000110, $D8, %00000000, $DC, %11110000, $E0, %00000000, $E7, %00000000, $F1, %11110000, $F6, %00110011
frame3354:
	.byte %01000100, $D4, %11111111, $D9, %00000000, $F0, %11000000, $F6, %11110011
frame3355:
	.byte %01000011, $D8, %11000000, $E1, %11111111, $F7, %00110000
frame3356:
	.byte %01000010, $DF, %00000000, $F1, %11111111
frame3357:
	.byte %01000010, $DC, %11110011, $F6, %11111111
frame3358:
	.byte %01000011, $F0, %00000000, $F6, %11001111, $F7, %00000000
frame3359:
	.byte %01000011, $EB, %11111111, $F1, %00111100, $F6, %11000011
frame3360:
	.byte %01000010, $DF, %11000000, $ED, %00000000
frame3361:
	.byte %01001001, $D8, %00110000, $D9, %00110000, $E0, %00000011, $E1, %11001111, $E7, %00001100, $E9, %00001100, $F0, %00001100, $F1, %00111111, $F6, %11001111
frame3362:
	.byte %01000101, $DF, %11000011, $E5, %11000011, $E6, %00111111, $EC, %11111111, $F7, %00000011
frame3363:
	.byte %01000110, $D8, %00111100, $D9, %00000000, $E2, %00111100, $E5, %11000000, $F1, %11111111, $F6, %11111111
frame3364:
	.byte %01000110, $D9, %11110000, $DE, %11111100, $DF, %11001100, $E2, %00110000, $E5, %00000000, $E7, %00000000
frame3365:
	.byte %01001010, $D7, %00110000, $D8, %00110011, $D9, %11110011, $DA, %11110000, $DC, %11110000, $DD, %11110011, $E0, %00000000, $E1, %11001100, $E2, %00110011, $E6, %00110011
frame3366:
	.byte %01001010, $D0, %11000000, $DF, %00001100, $E2, %11000011, $EA, %11001100, $ED, %00110000, $F0, %11001100, $F1, %11110011, $F2, %00111111, $F5, %11001111, $F7, %00110011
frame3367:
	.byte %01001101, $C3, %11111100, $CD, %11110011, $D3, %11001111, $D6, %11000000, $D8, %00000011, $DD, %00110011, $DE, %11111111, $DF, %00000000, $E9, %00000000, $EE, %00000000, $F0, %11000000, $F1, %11110000, $F6, %11111100
frame3368:
	.byte %01001001, $D7, %11000000, $D8, %00000000, $D9, %11111111, $DA, %11000000, $DD, %00000011, $DF, %00000011, $E2, %11000000, $F1, %11110011, $F6, %11110000
frame3369:
	.byte %01001001, $C4, %11110011, $D1, %00110000, $D3, %00001111, $D8, %00001100, $DA, %00000000, $DD, %00110011, $DE, %11111100, $E2, %11001100, $F7, %00110000
frame3370:
	.byte %01000101, $D3, %11001111, $D7, %11110000, $DD, %00111111, $E5, %00000011, $F6, %11111100
frame3371:
	.byte %11111111, %11111111, %11111111, %00000011, %00001100, %11111111, %11111111, %11111111
	.byte %11111111, %11111111, %11111111, %00000000, %00000000, %00001100, %11111111, %11111111
	.byte %00111111, %11001111, %11111111, %00110000, %00000000, %11001100, %00111111, %11001111
	.byte %11110000, %00000000, %00111111, %00000011, %00001111, %11000000, %00000011, %00111100
	.byte %11111100, %00110011, %00110011, %00000000, %00000000, %11111100, %11111100, %11111111
	.byte %11111111, %11111111, %00110011, %00000000, %00000000, %11001100, %11111111, %11111111
	.byte %00111111, %00001100, %11000000, %00000000, %00000000, %00110000, %00000011, %11001111
	.byte %00001111, %00001111, %00001111, %00000000, %00000000, %00001111, %00001111, %00001111

frame3372:
	.byte $88
frame3373:
	.byte %01000010, $C3, %00110011, $D5, %11000000
frame3374:
	.byte %01000011, $CD, %00000000, $D0, %11111111, $D1, %11111111
frame3375:
	.byte %01000010, $D5, %11001100, $D8, %11000000
frame3376:
	.byte %01000001, $CD, %00000011
frame3377:
	.byte $88
frame3378:
	.byte %01000001, $D8, %11001100
frame3379:
	.byte $88
frame3380:
	.byte $88
frame3381:
	.byte %01000001, $D0, %00111111
frame3382:
	.byte %01000010, $C3, %00000011, $E6, %11001100
frame3383:
	.byte %01000001, $CD, %00000000
frame3384:
	.byte %01000001, $DF, %00111111
frame3385:
	.byte %01000010, $D5, %11000000, $FF, %00001100
frame3386:
	.byte %01000001, $D5, %00000000
frame3387:
	.byte %01000011, $C4, %00000000, $D8, %11111100, $DF, %00110011
frame3388:
	.byte %01000011, $D1, %11001111, $DA, %00110011, $FE, %00000011
frame3389:
	.byte %01000100, $D7, %11111111, $DC, %00001100, $E7, %11110011, $F1, %00001111
frame3390:
	.byte %01000001, $E0, %11111111
frame3391:
	.byte %01000011, $D5, %00000011, $D8, %11111111, $F0, %00001111
frame3392:
	.byte $88
frame3393:
	.byte %01000111, $C5, %11001111, $DA, %00110000, $F0, %00001100, $F6, %00001111, $F7, %00000011, $F9, %00001100, $FE, %00000000
frame3394:
	.byte %01000001, $D7, %00111111
frame3395:
	.byte %01000101, $DE, %00000000, $E5, %11001100, $E6, %11111100, $E7, %11111111, $F0, %00001111
frame3396:
	.byte %01000001, $D0, %11111111
frame3397:
	.byte %01000011, $C5, %00001111, $CA, %11110011, $E1, %11110011
frame3398:
	.byte %01000011, $D5, %00110011, $D8, %11111100, $F7, %00001111
frame3399:
	.byte %01000001, $D7, %00111100
frame3400:
	.byte %01000011, $C3, %00000000, $D0, %11001111, $F0, %00000011
frame3401:
	.byte %01000100, $C5, %00001100, $F8, %00000011, $F9, %00000000, $FF, %00000000
frame3402:
	.byte %01000001, $D4, %00110000
frame3403:
	.byte %01000011, $D3, %00111100, $F7, %00001100, $F8, %00000000
frame3404:
	.byte %01000010, $D6, %11111111, $DB, %00000000
frame3405:
	.byte %01000100, $D3, %00110000, $DA, %00110011, $DE, %11000000, $F1, %00111111
frame3406:
	.byte %01000101, $C2, %00111111, $D3, %00111100, $D9, %00110000, $DA, %00000011, $F6, %11001111
frame3407:
	.byte %01000010, $D4, %11110000, $D8, %11110000
frame3408:
	.byte %01001000, $D0, %11000011, $D3, %00110000, $D4, %11000000, $D9, %00110011, $DC, %00000000, $DD, %00000000, $DE, %11001100, $F0, %00001111
frame3409:
	.byte %01000100, $D5, %00110000, $D7, %00000000, $DF, %00110000, $F2, %11001100
frame3410:
	.byte %01000011, $C5, %00000000, $C6, %11001111, $CA, %11111111
frame3411:
	.byte %01000010, $D0, %00000011, $D5, %00110011
frame3412:
	.byte %01000010, $D0, %00000000, $F7, %00001111
frame3413:
	.byte %01000011, $C6, %11001100, $D4, %00000000, $D8, %11000000
frame3414:
	.byte %01000010, $D6, %11001111, $DA, %00000000
frame3415:
	.byte %01000011, $D7, %00001100, $D9, %00111111, $EA, %00000011
frame3416:
	.byte %01000011, $E1, %11111111, $F0, %00111111, $F1, %00001111
frame3417:
	.byte %01001011, $C2, %00110011, $D0, %00000011, $D1, %00001111, $D6, %11001100, $D9, %00111100, $DE, %11000000, $E2, %00110000, $E6, %11111111, $F0, %00001111, $F6, %00001111, $F7, %00000011
frame3418:
	.byte %01000111, $D0, %00110011, $D1, %00111111, $D4, %11000000, $D7, %11001100, $D9, %11111100, $DE, %11110011, $F0, %11001111
frame3419:
	.byte %01001001, $CB, %11000000, $CE, %11001100, $CF, %00111111, $D2, %11001111, $D3, %00110011, $D8, %00000000, $D9, %11001100, $E5, %11000000, $F7, %00110011
frame3420:
	.byte %01000101, $D6, %00001100, $DE, %00110011, $DF, %00000000, $ED, %00001100, $F5, %00110011
frame3421:
	.byte %01000111, $C8, %11001111, $CA, %11110011, $D1, %00001111, $D5, %00110000, $DF, %00001100, $EA, %00000000, $F7, %00111111
frame3422:
	.byte %01000011, $D5, %00110011, $D8, %00000011, $DF, %11001100
frame3423:
	.byte %01000100, $CB, %00000000, $D3, %00000011, $D8, %00110011, $E2, %00000000
frame3424:
	.byte %01000110, $CA, %11111111, $D4, %00000000, $D7, %00001100, $E5, %11110000, $EA, %11000000, $ED, %00000000
frame3425:
	.byte %01000011, $C2, %11110011, $D0, %00000011, $E1, %11111100
frame3426:
	.byte %01001001, $D1, %11001111, $D7, %00000011, $D8, %11110011, $DF, %11111100, $E3, %11000000, $E4, %11111100, $E5, %11111111, $F0, %11111111, $F1, %00000011
frame3427:
	.byte %01001000, $C5, %11000000, $D7, %00110011, $D8, %11111111, $DF, %11111111, $E3, %11110000, $E4, %11111111, $E5, %00111111, $F7, %11111111
frame3428:
	.byte %01001001, $CD, %00001100, $D0, %11000000, $D5, %00111111, $D8, %11111100, $DF, %11110011, $E2, %11110000, $E3, %11111111, $E4, %00111111, $E5, %00001111
frame3429:
	.byte %01001001, $C2, %00110011, $CA, %11110011, $CD, %00111100, $D4, %00001100, $E2, %11111100, $E3, %00111111, $E4, %00001111, $E5, %11001111, $FA, %00000011
frame3430:
	.byte %01001000, $CB, %00001100, $CD, %11111100, $D6, %00000000, $E1, %11111111, $E2, %11111111, $E3, %00001111, $E5, %00001111, $F2, %00001100
frame3431:
	.byte %01001110, $CA, %11111111, $CB, %00000000, $D0, %11001100, $D2, %11111111, $D5, %11111111, $D9, %11000000, $DE, %00110000, $E2, %00001111, $EA, %00000000, $F2, %00000000, $F5, %00000011, $F8, %00000011, $FD, %00001100, $FF, %00001100
frame3432:
	.byte %01000101, $CB, %00001100, $D2, %00111111, $D5, %11110011, $D8, %11000000, $DF, %00110000
frame3433:
	.byte %01001001, $CB, %00000000, $CE, %00001100, $D0, %00001100, $D1, %11111100, $D2, %00111100, $D7, %00000011, $DE, %11110000, $F5, %00000000, $F6, %00001100
frame3434:
	.byte %01000101, $CC, %11000000, $CE, %00000000, $D6, %11000000, $D9, %00110000, $DE, %11000000
frame3435:
	.byte %01001000, $C6, %00001100, $CB, %00110000, $D1, %00110000, $D5, %11000011, $D8, %00000000, $DE, %11001100, $DF, %11000000, $F2, %00110000
frame3436:
	.byte %01001000, $C6, %00000000, $D3, %00000000, $D4, %00000000, $D7, %00000000, $D8, %00110000, $D9, %00110011, $E9, %00111111, $F8, %00000000
frame3437:
	.byte %01000101, $C2, %11110011, $D0, %00000000, $D8, %00110011, $DF, %11001100, $FF, %00000000
frame3438:
	.byte %01000010, $C3, %11000000, $D7, %11000000
frame3439:
	.byte %01000110, $C3, %00000000, $CF, %11111111, $D0, %00110011, $D7, %11001100, $E1, %00111111, $E6, %11001111
frame3440:
	.byte %01000010, $E9, %00110011, $EE, %11001111
frame3441:
	.byte %01000100, $C5, %00000000, $CF, %11001111, $D1, %00110011, $D2, %00110000
frame3442:
	.byte %01000100, $C2, %00110011, $D0, %00000011, $D7, %00001100, $F5, %11000000
frame3443:
	.byte %01001001, $C5, %11000000, $C8, %00001111, $CB, %00110011, $D2, %00000000, $D5, %00000000, $DF, %11000000, $E6, %11111111, $EE, %11001100, $F0, %00111111
frame3444:
	.byte %01000111, $CD, %00111100, $CE, %00110000, $CF, %11001100, $D7, %00000000, $D8, %11110000, $DF, %11110000, $F2, %00110011
frame3445:
	.byte %01001100, $C2, %11110011, $C6, %00000011, $C7, %11001100, $C9, %00111111, $CB, %00000011, $CC, %00000000, $CD, %00111111, $CE, %00000000, $CF, %11001111, $D0, %00000000, $D8, %11000000, $DF, %00110000
frame3446:
	.byte %01001100, $C3, %00001100, $C9, %00001111, $CE, %00000011, $CF, %11001100, $D0, %00001100, $D1, %00000011, $D6, %00000000, $D7, %00000011, $D8, %11001100, $DF, %00110011, $E6, %11001111, $F7, %11001111
frame3447:
	.byte %01000111, $C3, %00000000, $C5, %00000000, $C6, %00110011, $C8, %00111111, $CF, %00001100, $D9, %00110000, $DE, %11000000
frame3448:
	.byte %01000110, $C8, %00001111, $CA, %00111111, $CC, %00001100, $D0, %11001100, $D7, %00110011, $F1, %00000000
frame3449:
	.byte %01000111, $C3, %00110000, $CF, %00000000, $D1, %00000000, $D9, %00000000, $DE, %00000000, $F5, %11001100, $F9, %00001100
frame3450:
	.byte %01000100, $C5, %11000000, $CD, %00001111, $E9, %00000011, $EA, %00110000
frame3451:
	.byte %01000100, $EA, %00000000, $F2, %00110000, $F6, %00000000, $FA, %00000000
frame3452:
	.byte %01001010, $C2, %11111111, $C3, %00000000, $C8, %11001100, $CB, %00000000, $DF, %11110011, $E9, %00000000, $EE, %00001100, $F2, %00000000, $F5, %11000000, $FD, %00000000
frame3453:
	.byte %01000111, $C5, %11001100, $C7, %11000000, $C9, %00111111, $CC, %00000000, $CE, %00110000, $D8, %11111100, $F5, %00000000
frame3454:
	.byte %01001000, $C5, %11111100, $C9, %00110011, $CA, %00001111, $D1, %00001100, $DF, %11111111, $E1, %00001111, $E6, %00001111, $EE, %00000000
frame3455:
	.byte %01000111, $C3, %00110000, $C7, %00000000, $C8, %11000000, $C9, %00000000, $CA, %00000011, $D8, %11111111, $FE, %00000011
frame3456:
	.byte %01001000, $C5, %11001100, $C6, %11110011, $CD, %00001100, $CF, %11000000, $D1, %00000000, $D7, %11110000, $E6, %11001111, $F1, %11000000
frame3457:
	.byte %01000101, $C4, %11000000, $C6, %11111111, $C8, %11110000, $D0, %11111100, $E6, %00001111
frame3458:
	.byte %01000100, $C5, %11111100, $D0, %00110000, $D7, %11111100, $F0, %00110011
frame3459:
	.byte %01000110, $C3, %00000000, $C4, %00000000, $CA, %00000000, $D0, %00110011, $D7, %11001100, $E8, %00111111
frame3460:
	.byte %01000110, $C3, %00000011, $C6, %11001111, $C8, %00110000, $CE, %00000000, $F0, %00000011, $F7, %11001100
frame3461:
	.byte %01001011, $C2, %00111111, $C5, %11001100, $C6, %00001111, $C8, %00111111, $CD, %00000000, $D8, %11110011, $DF, %11111100, $E8, %00110011, $EF, %11001111, $F1, %11001100, $F6, %00110000
frame3462:
	.byte %01000001, $C1, %11001111
frame3463:
	.byte %01000110, $C0, %00001111, $C5, %11001111, $D8, %00110011, $DF, %11001100, $E0, %00111111, $EF, %11001100
frame3464:
	.byte %01001000, $C2, %00001111, $C3, %00000000, $C7, %00000011, $C8, %00110011, $C9, %00000011, $CE, %00001100, $CF, %00000000, $F1, %00000000
frame3465:
	.byte %01000101, $C5, %00001111, $CF, %11000000, $E7, %11001111, $F6, %00000000, $F9, %00000011
frame3466:
	.byte %01000101, $C2, %00000011, $C5, %00001100, $F0, %00000000, $F7, %00001100, $FE, %00000000
frame3467:
	.byte %01000011, $C6, %00000011, $CF, %00001100, $E8, %00000011
frame3468:
	.byte %01000111, $C1, %00001100, $C2, %00000000, $C7, %11000000, $C8, %00000011, $CE, %00000000, $D0, %00110000, $F7, %00000000
frame3469:
	.byte %01001000, $C0, %00110011, $C5, %00000000, $C9, %00000000, $CF, %00000000, $D7, %11000000, $D8, %00110000, $E8, %00000000, $EF, %00001100
frame3470:
	.byte %01000100, $C0, %00110000, $C8, %00000000, $F1, %00110000, $FE, %00001100
frame3471:
	.byte %01000100, $D0, %00000000, $D7, %00000000, $E0, %00001111, $EF, %00000000
frame3472:
	.byte %01000100, $C1, %00000000, $C7, %00000000, $DF, %11000000, $E7, %00001111
frame3473:
	.byte %01000010, $C0, %00000000, $C6, %00000000
frame3474:
	.byte %01000010, $F1, %00000000, $F9, %00000000
frame3475:
	.byte %01000011, $C7, %00001100, $D8, %00000000, $FE, %00000000
frame3476:
	.byte %01000010, $C7, %00000000, $DF, %00000000
frame3477:
	.byte %01000011, $C0, %00001100, $C7, %00000011, $F8, %00001100
frame3478:
	.byte $88
frame3479:
	.byte %01000100, $C7, %00000000, $DC, %11110000, $DD, %11110000, $DE, %00110000
frame3480:
	.byte %01000100, $C0, %00000000, $DB, %11000000, $DE, %11110000, $DF, %11110000
frame3481:
	.byte %01000001, $DB, %11110000
frame3482:
	.byte %01000001, $F8, %00000000
frame3483:
	.byte %01000001, $DA, %11000000
frame3484:
	.byte %01000001, $DA, %11110000
frame3485:
	.byte $88
frame3486:
	.byte %01000001, $D9, %11000000
frame3487:
	.byte %01000101, $E3, %00000000, $E4, %00000000, $E5, %00000000, $E6, %00000000, $E7, %00001100
frame3488:
	.byte %01000100, $D9, %11110000, $E2, %00000000, $E7, %00000000, $F8, %00000011
frame3489:
	.byte %01000011, $E1, %00000011, $E7, %00001100, $F8, %00000000
frame3490:
	.byte %01000011, $D8, %11000000, $DF, %11111100, $E1, %00000000
frame3491:
	.byte %01000001, $E0, %00000011
frame3492:
	.byte %01000010, $DF, %11110000, $E0, %00000000
frame3493:
	.byte %01000011, $D8, %11110000, $DF, %11110011, $E7, %00001111
frame3494:
	.byte $88
frame3495:
	.byte $88
frame3496:
	.byte %01000010, $DF, %11110000, $E7, %00001100
frame3497:
	.byte %01000011, $DE, %11111100, $E6, %00001100, $E7, %00001111
frame3498:
	.byte $88
frame3499:
	.byte %01000010, $DE, %11110000, $E6, %00000000
frame3500:
	.byte $88
frame3501:
	.byte $88
frame3502:
	.byte %01000001, $DE, %11110011
frame3503:
	.byte $88
frame3504:
	.byte %01000010, $DE, %11111100, $E6, %00001100
frame3505:
	.byte %01000010, $DE, %11110000, $E7, %11001111
frame3506:
	.byte %01000001, $DF, %11111100
frame3507:
	.byte %01000010, $DD, %11111100, $EF, %00001100
frame3508:
	.byte %01000010, $DE, %00110011, $EF, %11001100
frame3509:
	.byte %01000101, $DA, %00110000, $DB, %00000000, $DC, %00000000, $DD, %00110000, $DF, %11111111
frame3510:
	.byte %01000110, $CE, %00001100, $D7, %11000000, $DA, %00000000, $DD, %11000000, $DE, %00110000, $EF, %11001111
frame3511:
	.byte %01000011, $D9, %00110000, $E7, %11111111, $F7, %11001100
frame3512:
	.byte %01000101, $CE, %00000000, $DD, %11001100, $DE, %11110000, $FD, %00000011, $FF, %00001100
frame3513:
	.byte %01000100, $D7, %11110000, $D9, %00000000, $DD, %11111111, $DE, %11001100
frame3514:
	.byte %01000001, $F7, %11001111
frame3515:
	.byte %01000111, $DD, %11001100, $E6, %11001100, $EE, %00001100, $EF, %11111111, $F4, %11000000, $F7, %11111111, $FF, %00001111
frame3516:
	.byte %01000100, $D8, %00110000, $DD, %11000000, $DE, %11111100, $E6, %11001111
frame3517:
	.byte %01000010, $D7, %00110000, $DD, %11110011
frame3518:
	.byte %01000011, $D6, %11000000, $DE, %11111111, $EE, %11001100
frame3519:
	.byte %01000110, $C7, %00001100, $D8, %00000000, $DF, %11110011, $F6, %11001100, $FD, %00001100, $FE, %00001100
frame3520:
	.byte %01000100, $DF, %00110011, $E6, %11111111, $E7, %11110011, $EF, %11110011
frame3521:
	.byte %01000110, $C7, %11001100, $D7, %00000000, $DC, %11001100, $E7, %00110011, $EF, %00110011, $FF, %00000011
frame3522:
	.byte %01000101, $C7, %11000000, $CF, %00001100, $F4, %00000000, $F7, %11110011, $FE, %00001111
frame3523:
	.byte %01001000, $C7, %00000011, $DC, %00000000, $DD, %11111100, $EE, %11111100, $F4, %00000011, $F5, %00110000, $F7, %00110011, $FF, %00001111
frame3524:
	.byte %01000111, $D6, %11110000, $DC, %00001100, $DF, %00000000, $E7, %00110000, $EE, %11111111, $EF, %00110000, $F6, %11111111
frame3525:
	.byte %01000100, $C7, %00110011, $CF, %11001100, $E7, %00000000, $EF, %00000000
frame3526:
	.byte %01000110, $C7, %00110000, $CF, %11000011, $E5, %11000000, $F4, %00000000, $F7, %11000000, $FF, %00000011
frame3527:
	.byte %01000110, $C7, %00000000, $D6, %00110000, $DA, %00001100, $F5, %11110000, $F7, %11110000, $FF, %00000000
frame3528:
	.byte %01000100, $C6, %00001100, $DB, %00001100, $DC, %00001111, $E5, %11001100
frame3529:
	.byte %01000101, $DB, %00001111, $DE, %11110011, $ED, %00001100, $F4, %00001100, $FD, %00001111
frame3530:
	.byte %01001001, $C6, %11000000, $CF, %11110000, $DC, %00001100, $DE, %00110011, $E6, %00111111, $ED, %11001100, $EE, %00110011, $F5, %11111100, $F7, %00111100
frame3531:
	.byte %01000111, $CE, %00001100, $DA, %00001111, $DC, %00001111, $DD, %11111111, $E6, %00110011, $F7, %00001111, $FC, %00001100
frame3532:
	.byte %01000010, $C6, %00000000, $F6, %11110011
frame3533:
	.byte %01000111, $C7, %11000000, $CE, %00000000, $CF, %11111100, $D5, %11000000, $D6, %00000000, $F6, %00111111, $FC, %00001111
frame3534:
	.byte %01000010, $CE, %11000000, $F7, %00000011
frame3535:
	.byte %01000101, $C6, %00110000, $C7, %11001100, $F5, %11111111, $F7, %00000000, $FB, %00001100
frame3536:
	.byte %01000110, $C6, %00000000, $DE, %00000000, $E5, %11001111, $E6, %00000011, $EE, %00110000, $EF, %00110000
frame3537:
	.byte %01000111, $C7, %11111100, $CE, %11000011, $CF, %11111111, $EE, %00000000, $F4, %11001100, $FC, %00001100, $FF, %00000011
frame3538:
	.byte %01000111, $DC, %00000011, $E5, %11111111, $E6, %00000000, $EC, %00110000, $ED, %11111111, $F3, %11000000, $F6, %00110011
frame3539:
	.byte %01000110, $C7, %11110000, $CE, %00000000, $EE, %11000000, $F4, %11110000, $FC, %00001111, $FE, %00000011
frame3540:
	.byte %01000101, $CE, %00111100, $E0, %00000011, $EF, %00000000, $F6, %00110000, $FB, %00000000
frame3541:
	.byte %01000101, $C6, %11000000, $C7, %00110000, $CE, %11111100, $DC, %00001111, $F4, %11111100
frame3542:
	.byte %01000101, $CE, %11001100, $D5, %00000000, $E0, %00110011, $E8, %00000011, $EE, %11110000
frame3543:
	.byte %01000100, $CF, %11110011, $D8, %00110011, $EE, %00110000, $FF, %00000000
frame3544:
	.byte %01000010, $E5, %00111111, $E8, %00110011
frame3545:
	.byte %01000110, $C7, %00000000, $CE, %11001111, $DD, %11110011, $ED, %11110011, $F3, %11110000, $FE, %00000000
frame3546:
	.byte %01000110, $CE, %11111111, $D5, %00110000, $DD, %00110011, $EC, %11110000, $F5, %11110011, $F6, %11110000
frame3547:
	.byte %01000110, $C6, %11110000, $E0, %00111111, $EE, %00000000, $F3, %00110000, $F6, %11000000, $FB, %00001100
frame3548:
	.byte %01000010, $E5, %00110011, $F4, %11111111
frame3549:
	.byte %01001100, $CD, %00001100, $CE, %00111111, $CF, %00110000, $D7, %00001100, $D8, %00110000, $DC, %11001111, $E0, %11111111, $E4, %00001100, $E8, %00111111, $EE, %00000011, $F3, %00000000, $F5, %11111111
frame3550:
	.byte %01000100, $C6, %00110000, $D8, %11111100, $E0, %11001111, $ED, %00110011
frame3551:
	.byte %01001001, $C5, %11000000, $CE, %00001111, $D7, %00000000, $D8, %11001100, $E0, %11001100, $E4, %11001100, $E8, %00111100, $EC, %11111100, $F6, %00000000
frame3552:
	.byte %01000010, $E8, %00001100, $EC, %11001100
frame3553:
	.byte %01000010, $C5, %11001100, $F3, %00001100
frame3554:
	.byte %01000011, $C5, %11111100, $CE, %00000011, $ED, %00111111
frame3555:
	.byte %01000011, $C5, %11111111, $EB, %00001100, $F3, %11001100
frame3556:
	.byte %01000100, $C6, %00000000, $CD, %00000000, $CE, %11000011, $EE, %00000000
frame3557:
	.byte %01000001, $D5, %00000000
frame3558:
	.byte %01000001, $EC, %11111100
frame3559:
	.byte %01000101, $C4, %00001100, $CF, %00000000, $F3, %11001111, $F5, %00111111, $F6, %00000011
frame3560:
	.byte %01000110, $C5, %11001111, $CD, %00001100, $D7, %00000011, $D8, %11000000, $E5, %00000011, $ED, %00001111
frame3561:
	.byte %01000101, $C5, %11000011, $E1, %00110000, $E5, %00000000, $ED, %00001100, $F5, %00110011
frame3562:
	.byte %01000100, $D9, %00110000, $E8, %00000000, $ED, %00001111, $F3, %11000011
frame3563:
	.byte %01000100, $CE, %11000000, $D7, %00000000, $D8, %00000000, $ED, %00000011
frame3564:
	.byte %01000100, $D9, %00110011, $E0, %00001100, $E1, %00110011, $F6, %00000000
frame3565:
	.byte %01000011, $C5, %11110011, $E0, %00000000, $E9, %00000011
frame3566:
	.byte %01000010, $C4, %00001111, $C5, %00110011
frame3567:
	.byte %01000001, $DA, %00001100
frame3568:
	.byte %01000001, $FD, %00000011
frame3569:
	.byte $88
frame3570:
	.byte %01000001, $C4, %00111111
frame3571:
	.byte %01000001, $C3, %00001100
frame3572:
	.byte %01000010, $C5, %00110000, $CE, %00000000
frame3573:
	.byte $88
frame3574:
	.byte $88
frame3575:
	.byte $88
frame3576:
	.byte $88
frame3577:
	.byte %01000001, $CE, %11000000
frame3578:
	.byte %01000010, $C3, %00000000, $C4, %00001111
frame3579:
	.byte %01000001, $DA, %00001111
frame3580:
	.byte %01000010, $DB, %00000011, $E8, %00001100
frame3581:
	.byte %01000011, $CE, %00000000, $DA, %00000011, $DB, %00000000
frame3582:
	.byte %01000001, $DA, %00000000
frame3583:
	.byte $88
frame3584:
	.byte %01000010, $C4, %00001100, $D2, %11110000
frame3585:
	.byte %01000001, $EB, %00000000
frame3586:
	.byte %01000011, $C4, %00001111, $D2, %11000000, $D3, %00110000
frame3587:
	.byte %01000001, $FB, %00001111
frame3588:
	.byte %01000010, $D2, %00000000, $DD, %00000011
frame3589:
	.byte %01000101, $E5, %11000000, $EB, %00001100, $EC, %11111111, $ED, %00110011, $F5, %11110011
frame3590:
	.byte %01001000, $D4, %11000000, $DD, %00000000, $E4, %11111100, $E5, %00000000, $EB, %11001100, $ED, %11110000, $F3, %11001111, $FB, %00000011
frame3591:
	.byte %01001001, $D2, %00000011, $D3, %00000000, $D4, %11110000, $DC, %11111111, $E4, %11111111, $E5, %00110000, $F3, %11001100, $F5, %00110011, $FD, %00000000
frame3592:
	.byte %01000101, $C3, %00001111, $C4, %11001111, $EB, %11111100, $ED, %00000000, $FC, %00000011
frame3593:
	.byte %01001000, $C2, %00001100, $C3, %00000011, $C4, %11111111, $D2, %00001100, $E4, %11110011, $E5, %00000011, $EB, %11110000, $FC, %00000000
frame3594:
	.byte %01001010, $C2, %00001111, $C4, %11001111, $D3, %11000000, $D9, %00110000, $DC, %00111111, $DD, %00110000, $E2, %11000000, $EB, %11111100, $ED, %00000011, $F5, %00000011
frame3595:
	.byte %01001101, $C2, %11001111, $C3, %00000000, $D2, %00000000, $D4, %00110011, $D9, %00110011, $E2, %00000000, $E3, %11111100, $E4, %00111111, $E5, %00000000, $EA, %11000000, $EB, %11001100, $EC, %11110011, $FC, %00001100
frame3596:
	.byte %01001011, $C1, %00001100, $C2, %11110011, $C4, %11001100, $CA, %00110000, $D3, %11001100, $DB, %11001100, $DC, %00110011, $EB, %11001111, $ED, %00000000, $F3, %00001100, $F4, %11001111
frame3597:
	.byte %01001000, $C1, %11001100, $C2, %00110000, $CA, %00110011, $CC, %00001100, $DD, %00000000, $E4, %00110011, $F3, %00111100, $F5, %00000000
frame3598:
	.byte %01001011, $C1, %11110000, $C2, %00000000, $C5, %00000000, $C9, %00001100, $DC, %00000011, $E3, %11001100, $E4, %11110011, $E5, %00110000, $EA, %00000000, $EB, %11111111, $F4, %00001111
frame3599:
	.byte $88
frame3600:
	.byte %01001010, $C1, %00110000, $C5, %00110000, $C8, %00001100, $C9, %11111111, $CA, %00000000, $D4, %00000011, $DC, %11000011, $F3, %00111111, $F4, %00000011, $FC, %00000000
frame3601:
	.byte %01000110, $C1, %00000000, $C8, %11001100, $C9, %00110011, $CA, %00110000, $CB, %11000000, $CC, %00111100
frame3602:
	.byte %01001000, $C4, %11001111, $C8, %11111111, $C9, %00110000, $D3, %11001111, $DB, %11111100, $E3, %11111100, $EA, %00001100, $F4, %00110011
frame3603:
	.byte %01001010, $C5, %00110011, $C8, %11110000, $C9, %00000000, $CC, %00001100, $CD, %00001111, $D0, %00001111, $D4, %00000000, $DB, %11111111, $EA, %00000000, $FC, %00000011
frame3604:
	.byte %01000101, $C4, %11000011, $C8, %00110000, $CC, %00000000, $CD, %00000011, $EA, %00001100
frame3605:
	.byte %01000100, $C4, %11000000, $C8, %00000000, $D0, %00110011, $FB, %00000000
frame3606:
	.byte %01000111, $C5, %11111111, $CB, %11110000, $D0, %00110000, $DB, %11001111, $DC, %11000000, $E4, %11110000, $EC, %00110011
frame3607:
	.byte %01001000, $C4, %11001100, $CA, %00000000, $CD, %00000000, $D0, %00000000, $D3, %00111111, $DB, %11111111, $E3, %11111111, $E5, %00000000
frame3608:
	.byte %01000110, $C4, %00001100, $D7, %11000000, $DA, %11000000, $DC, %00000000, $E4, %11000000, $F4, %00000000
frame3609:
	.byte %01000011, $D1, %00110000, $E2, %00000011, $EA, %00000011
frame3610:
	.byte %01000101, $C6, %00110011, $D3, %11111111, $D7, %00000000, $DB, %00110011, $FC, %00000000
frame3611:
	.byte %01000010, $E2, %00001111, $F3, %00001111
frame3612:
	.byte %01000101, $D3, %11110011, $DA, %00000000, $DC, %00110000, $E2, %11001111, $EA, %00000000
frame3613:
	.byte %01000010, $C6, %00111111, $D3, %00110011
frame3614:
	.byte %01000010, $CA, %11000000, $D6, %00001100
frame3615:
	.byte %01000100, $D7, %00110000, $E2, %11001100, $E4, %00000000, $EC, %00110000
frame3616:
	.byte %01001001, $C1, %00000011, $C5, %11111100, $C6, %11111111, $D6, %00000000, $D7, %00000000, $DA, %00001100, $E2, %00111100, $E3, %11110011, $EA, %11000000
frame3617:
	.byte %01000100, $C1, %11000011, $D2, %11000000, $EA, %11001100, $F3, %00001100
frame3618:
	.byte %01000001, $D2, %11001100
frame3619:
	.byte %01000100, $C1, %11000000, $CA, %11000011, $E1, %11110011, $EC, %00000000
frame3620:
	.byte %01000001, $E2, %11000000
frame3621:
	.byte %01000010, $C1, %00000000, $CE, %00001100
frame3622:
	.byte %01000010, $E1, %00110011, $E2, %11001100
frame3623:
	.byte %01000011, $C6, %11110011, $CE, %00001111, $D2, %11000000
frame3624:
	.byte %01000001, $C4, %00000000
frame3625:
	.byte %01000001, $CE, %11001111
frame3626:
	.byte %01000011, $CB, %11110011, $CF, %00000011, $D2, %00000000
frame3627:
	.byte %01000100, $CB, %11111100, $CF, %00000000, $DA, %00111100, $E4, %11000000
frame3628:
	.byte %01000110, $C5, %00111100, $C6, %11110000, $CE, %00001111, $D3, %11110011, $DA, %11110000, $E3, %11111111
frame3629:
	.byte %01000011, $CA, %11000000, $CB, %11110000, $DC, %00000000
frame3630:
	.byte %01000100, $D3, %11111111, $DB, %00111111, $E4, %00110000, $F3, %00001111
frame3631:
	.byte %01000110, $C6, %11111111, $CA, %00000000, $CE, %00001100, $DB, %11111111, $E2, %00001100, $F3, %00000011
frame3632:
	.byte %01000011, $CC, %00110000, $DA, %00110000, $DF, %11000000
frame3633:
	.byte %01000111, $C5, %00110000, $CE, %00000000, $CF, %00000011, $DF, %00000000, $E4, %00110011, $F3, %00110011, $FC, %00000011
frame3634:
	.byte %01001001, $CB, %11000000, $CC, %00110011, $D3, %11001100, $D4, %00000011, $DB, %11001111, $DC, %00000011, $E4, %00111111, $F3, %00111111, $F4, %00110000
frame3635:
	.byte %01000111, $C5, %00000000, $CC, %00110000, $CF, %00000000, $DA, %00000000, $DC, %11000011, $E4, %00001111, $EC, %00110000
frame3636:
	.byte %01000011, $DB, %11111111, $E2, %11000000, $EC, %00111111
frame3637:
	.byte %01000100, $DB, %11111100, $DD, %00001100, $E4, %00001100, $E5, %00000011
frame3638:
	.byte %01000101, $C4, %00001100, $E5, %11000011, $EA, %11000000, $EE, %11000011, $F7, %00000011
frame3639:
	.byte %01000011, $E4, %00111100, $F4, %00110011, $F7, %11000011
frame3640:
	.byte %01000010, $DD, %00000000, $E3, %11001111
frame3641:
	.byte %01000100, $C4, %00000000, $C6, %11110011, $EA, %00000000, $EC, %11111111
frame3642:
	.byte %01000001, $CE, %00000011
frame3643:
	.byte %01000010, $E4, %00111111, $F7, %00000011
frame3644:
	.byte %01000100, $C6, %00110011, $DB, %11111111, $EE, %00000011, $F7, %00000000
frame3645:
	.byte %01000101, $C6, %11110011, $E2, %11110000, $E3, %11111111, $E5, %00000011, $EE, %00000000
frame3646:
	.byte $88
frame3647:
	.byte %01000001, $C6, %11110000
frame3648:
	.byte %01000010, $E4, %00110011, $E5, %00000000
frame3649:
	.byte $88
frame3650:
	.byte %01000011, $C5, %11000000, $C6, %00110000, $D4, %00000000
frame3651:
	.byte %01000011, $CD, %00001100, $DC, %11110011, $E5, %00000011
frame3652:
	.byte %01000001, $DC, %11000011
frame3653:
	.byte %01000011, $D3, %11001111, $E2, %00110000, $EC, %11110011
frame3654:
	.byte %01000001, $E5, %00000000
frame3655:
	.byte %01000010, $C5, %11001100, $C6, %00110011
frame3656:
	.byte %01000011, $CE, %00000000, $EC, %00110011, $F7, %00110000
frame3657:
	.byte %01000011, $CD, %00000000, $F6, %00001100, $F7, %00000000
frame3658:
	.byte %01000010, $DB, %11001111, $EE, %00110000
frame3659:
	.byte %01000101, $CB, %11110000, $E2, %00000000, $E4, %00110000, $F4, %00110000, $F6, %00000000
frame3660:
	.byte %01000011, $D4, %00110000, $EE, %00000000, $F6, %11000000
frame3661:
	.byte %01000101, $C5, %11001111, $D4, %00000000, $DC, %00000011, $ED, %00001100, $F6, %00000011
frame3662:
	.byte %01000110, $C3, %11000000, $C5, %00001111, $C6, %00110000, $DB, %11111111, $DC, %00001100, $EF, %00001100
frame3663:
	.byte %01000111, $C3, %00000000, $D3, %11111111, $E5, %00110000, $ED, %00000000, $EF, %00000000, $F5, %11001100, $F6, %00000000
frame3664:
	.byte %01000101, $D4, %00001100, $E5, %00000000, $ED, %00110011, $F5, %00110011, $FD, %00000011
frame3665:
	.byte %01000101, $CC, %00000000, $D4, %00110000, $ED, %00000000, $F5, %00000000, $FD, %00000000
frame3666:
	.byte %01000011, $D5, %00111100, $E4, %00110011, $EA, %11000000
frame3667:
	.byte %01000100, $D5, %11000000, $DA, %00110000, $E4, %00110000, $EA, %00000000
frame3668:
	.byte %01000100, $D2, %11000011, $D4, %11110000, $D5, %00000000, $DC, %00000000
frame3669:
	.byte %01000100, $D2, %00000000, $DB, %11001111, $DD, %00001100, $E2, %00110000
frame3670:
	.byte %01000111, $C3, %11001100, $CC, %00110011, $D4, %11111100, $D5, %00110000, $DA, %00000000, $DD, %11000000, $F3, %00110011
frame3671:
	.byte %01001000, $C3, %00000000, $C4, %00001100, $CC, %00000000, $D4, %11110000, $D5, %00000011, $DB, %11111111, $DD, %00000011, $E1, %11110011
frame3672:
	.byte %01000110, $C5, %11001111, $CD, %00110011, $D4, %00110000, $DC, %11000000, $DD, %00000000, $E1, %00110011
frame3673:
	.byte %01000101, $C5, %00001111, $C6, %11110000, $CD, %11000000, $DC, %00000000, $E4, %00000000
frame3674:
	.byte %01000110, $C6, %00110000, $CD, %00000000, $CE, %00111100, $CF, %00000011, $D1, %00000000, $DB, %11001111
frame3675:
	.byte %01001001, $C4, %11001100, $C5, %00111111, $CC, %11000000, $CE, %00000000, $CF, %00000000, $D2, %00000011, $D4, %00111100, $D5, %00000000, $DB, %11001100
frame3676:
	.byte %01000100, $D4, %00001100, $D5, %00001100, $D6, %11000000, $DF, %00001100
frame3677:
	.byte %01000101, $CC, %00000000, $D2, %00000000, $D6, %00110000, $DE, %00001100, $DF, %00110000
frame3678:
	.byte %01001000, $D4, %00001111, $D5, %11000000, $D6, %00000000, $DE, %00110000, $DF, %00000000, $E2, %00000000, $E6, %11000011, $EE, %00001100
frame3679:
	.byte %01000110, $D5, %00000000, $DD, %11001100, $DE, %00000000, $E5, %11001100, $E6, %00000000, $EE, %00000011
frame3680:
	.byte %01001010, $C5, %00001111, $D4, %00000011, $D5, %00110011, $DA, %11000000, $DD, %00110011, $E4, %00110000, $E5, %00110011, $ED, %00110011, $EE, %00000000, $F3, %00000011
frame3681:
	.byte %01000111, $CC, %00000011, $D5, %00110000, $DD, %00000011, $E4, %11111100, $E5, %00000000, $E9, %00001111, $ED, %00000000
frame3682:
	.byte %01000101, $C4, %00001100, $D5, %00110011, $DC, %11001100, $DD, %00000000, $E4, %00110011
frame3683:
	.byte %01000100, $D5, %00000011, $DC, %00111100, $E4, %00110000, $F3, %00110011
frame3684:
	.byte %01000011, $CA, %00001100, $CD, %11000000, $DC, %00000000
frame3685:
	.byte %01000100, $C4, %00000000, $CA, %00000000, $CE, %00000011, $E8, %00000000
frame3686:
	.byte %01000100, $CB, %11000000, $D4, %00001111, $DB, %11001111, $EA, %11000000
frame3687:
	.byte %01000001, $F3, %00111111
frame3688:
	.byte %01000011, $C5, %00001100, $D3, %11111100, $D7, %11000000
frame3689:
	.byte %01000011, $CC, %00110011, $D5, %00000000, $D7, %00000000
frame3690:
	.byte $88
frame3691:
	.byte %01000011, $CE, %00000000, $EC, %00111111, $F4, %00110011
frame3692:
	.byte %01000010, $D5, %00001100, $E4, %00000000
frame3693:
	.byte %01000100, $C6, %00000000, $D4, %00111100, $E2, %11000000, $FB, %00000011
frame3694:
	.byte %01000101, $D3, %11001100, $D5, %00000000, $D9, %00110000, $E0, %11000000, $E9, %00001100
frame3695:
	.byte %01000101, $C6, %11000011, $CC, %00110000, $D4, %00111111, $E9, %00111100, $F2, %00001100
frame3696:
	.byte %01000011, $C6, %00000011, $E1, %00110000, $E9, %00001100
frame3697:
	.byte %01000110, $CE, %00110000, $D5, %00111100, $DC, %00001111, $E9, %00111100, $EC, %00110011, $F3, %11111111
frame3698:
	.byte %01000110, $C6, %00110011, $CE, %00111100, $DA, %00000000, $DC, %00111111, $E9, %00110000, $ED, %00110000
frame3699:
	.byte %01000011, $C6, %00111111, $D8, %11000000, $EA, %11000011
frame3700:
	.byte %01000101, $C5, %00000000, $D5, %00111111, $D9, %00000000, $E8, %00001100, $EA, %00110011
frame3701:
	.byte %01001000, $C6, %11111111, $CD, %00000000, $CE, %00110000, $CF, %00000011, $D4, %11111111, $D8, %11001100, $E9, %00110011, $EA, %00000011
frame3702:
	.byte %01000110, $CC, %00110011, $CF, %00000000, $D5, %00000011, $E0, %11001100, $E4, %00110000, $ED, %00000000
frame3703:
	.byte %01000101, $C7, %00000011, $D6, %00000011, $DC, %00110011, $E3, %11111100, $E8, %00111100
frame3704:
	.byte %01000110, $C6, %11001111, $C7, %00110011, $CF, %00001100, $E1, %00000000, $E2, %00000000, $E9, %11110011
frame3705:
	.byte %01001011, $C6, %11001100, $C9, %11000000, $CE, %11110000, $CF, %00000011, $D5, %11001111, $DD, %00000011, $E9, %11000011, $EC, %11110011, $F2, %11001100, $F4, %11111111, $FB, %00001111
frame3706:
	.byte %01000110, $C7, %00111111, $CE, %11000000, $DB, %11111111, $DC, %11110011, $E4, %00110011, $F0, %00001100
frame3707:
	.byte %01001001, $C6, %00001100, $C7, %11111111, $C9, %00000000, $CE, %00000000, $CF, %00000000, $D4, %11110011, $D5, %11001100, $E8, %11111100, $EA, %00001111
frame3708:
	.byte %01000100, $C4, %11000000, $CF, %00001100, $DA, %00110000, $EA, %00001100
frame3709:
	.byte %01000110, $C7, %00001111, $CF, %00111100, $D5, %00110000, $D6, %00111111, $E2, %00001100, $FC, %00001111
frame3710:
	.byte %01001000, $C6, %00000000, $CB, %11001100, $D5, %11110000, $DD, %00001100, $E1, %00000011, $F1, %00000011, $F2, %11000000, $F5, %00000011
frame3711:
	.byte %01000110, $CC, %11110011, $CF, %00000000, $D6, %00110000, $DC, %00110011, $EA, %00111100, $FA, %00001100
frame3712:
	.byte %01000101, $CF, %11000000, $D6, %11110000, $D7, %00000011, $DD, %00111100, $F0, %00000000
frame3713:
	.byte %01000101, $C7, %00001100, $C8, %00000011, $DA, %00000000, $E4, %00111111, $E9, %00000011
frame3714:
	.byte %01000111, $C7, %00000000, $C8, %00000000, $CF, %00000000, $DD, %00110000, $DE, %00000011, $EA, %00110000, $F9, %00000011
frame3715:
	.byte %01000100, $D5, %00110000, $D7, %00000000, $E2, %00000000, $F9, %00000000
frame3716:
	.byte %01001000, $D6, %00110000, $D7, %00001100, $DD, %11000000, $DE, %00001111, $E8, %11001100, $E9, %00110011, $EC, %00110011, $F1, %00001111
frame3717:
	.byte %01001001, $C6, %00001100, $CC, %11111111, $D6, %00000000, $D7, %00111100, $DC, %00111111, $DD, %11001111, $E3, %11111111, $EA, %11110000, $F0, %11001100
frame3718:
	.byte %01000101, $D5, %00000000, $E4, %00110011, $E5, %00000011, $E9, %00000011, $F1, %00001100
frame3719:
	.byte %01000101, $D7, %00110000, $E2, %00000011, $E4, %11110011, $EA, %11000000, $F5, %11000011
frame3720:
	.byte %01000001, $F2, %00000000
frame3721:
	.byte %01000111, $C4, %11110000, $C6, %00000000, $D7, %00000000, $DD, %00001111, $DE, %00111111, $F1, %00111100, $F2, %00000011
frame3722:
	.byte %01000011, $E2, %11000011, $E9, %00000000, $F0, %11000000
frame3723:
	.byte %01000001, $D7, %11000000
frame3724:
	.byte %01000100, $DE, %11111111, $E5, %00001111, $F0, %00000000, $F1, %00110000
frame3725:
	.byte %01000101, $E2, %11000000, $E5, %00001100, $EA, %00000000, $F6, %00110000, $FD, %00000011
frame3726:
	.byte %01000011, $DE, %11110011, $F1, %11110000, $F8, %00000011
frame3727:
	.byte %01000100, $DF, %00000011, $F2, %00001111, $F5, %00000011, $F8, %00001111
frame3728:
	.byte %01000001, $E1, %00001111
frame3729:
	.byte %01000010, $DD, %00000011, $DE, %11110000
frame3730:
	.byte %01000010, $DE, %11000000, $E6, %00000011
frame3731:
	.byte %01000111, $C3, %11000000, $D3, %11000000, $DD, %11110011, $DE, %00110000, $E2, %00000000, $E5, %00111100, $F1, %11000000
frame3732:
	.byte %01000100, $D3, %11001100, $DD, %11110000, $F0, %11000000, $F8, %00001100
frame3733:
	.byte $88
frame3734:
	.byte %01000010, $DF, %00001111, $F5, %11000011
frame3735:
	.byte %01000110, $C0, %00000011, $D3, %11000000, $E2, %00110000, $F2, %00001100, $F5, %11001111, $F6, %00000000
frame3736:
	.byte %01000100, $C4, %11111100, $CC, %00111111, $D4, %00110011, $F5, %00001111
frame3737:
	.byte %01000100, $C0, %00000000, $DC, %11111111, $E1, %00000011, $EC, %11110011
frame3738:
	.byte %01000011, $D3, %11001100, $DE, %00000000, $F9, %00000011
frame3739:
	.byte %01000101, $CB, %11111100, $D7, %00000000, $F0, %00000000, $F2, %00111100, $F5, %00001100
frame3740:
	.byte %01000010, $D3, %11111100, $D4, %00110000
frame3741:
	.byte %01000001, $E6, %00000000
frame3742:
	.byte %01000001, $E5, %11111100
frame3743:
	.byte %01000010, $C2, %00000011, $DD, %00110000
frame3744:
	.byte %01000011, $DF, %00000011, $E4, %00110011, $F6, %00000011
frame3745:
	.byte %01000010, $C2, %00000000, $F8, %00000000
frame3746:
	.byte $88
frame3747:
	.byte %01000011, $CB, %11111111, $CC, %00110011, $E5, %00111100
frame3748:
	.byte %01000011, $E1, %11000011, $E2, %00000000, $F1, %00000000
frame3749:
	.byte $88
frame3750:
	.byte $88
frame3751:
	.byte %01000110, $D3, %11111111, $DC, %11110011, $DD, %00000000, $E5, %11111100, $EC, %11111111, $FD, %00000000
frame3752:
	.byte %01000010, $D4, %00110011, $E5, %11111111
frame3753:
	.byte $88
frame3754:
	.byte %01000010, $D8, %11000000, $EF, %00110000
frame3755:
	.byte %01001000, $D3, %11111100, $D8, %11001100, $DF, %00110011, $E1, %11000000, $E8, %00001100, $EA, %00001100, $EF, %00000000, $F9, %00001111
frame3756:
	.byte %01001000, $C4, %11001100, $D3, %11111111, $D4, %00110000, $E0, %11111111, $E2, %00001100, $E4, %00000011, $E5, %00111111, $E8, %00111100
frame3757:
	.byte %01001111, $C3, %11110000, $C4, %11110000, $D8, %00000000, $DA, %11001100, $DC, %00110011, $DF, %00110000, $E0, %00000000, $E1, %00110000, $E4, %00000000, $E8, %00000000, $EC, %00111111, $F2, %11110000, $F4, %11110011, $F5, %00001111, $F9, %00001100
frame3758:
	.byte %01001001, $C7, %00001100, $D4, %00000000, $DE, %00110000, $DF, %00000000, $E4, %00001100, $EA, %00001111, $F2, %11111100, $F4, %00110011, $F6, %00000000
frame3759:
	.byte %01001101, $C6, %00001100, $C7, %11111111, $CA, %11000000, $CF, %11111111, $D3, %11111100, $D7, %00001100, $DE, %00111100, $E2, %11001100, $EA, %11001111, $F2, %11001100, $F4, %00111111, $FA, %00001111, $FC, %00000011
frame3760:
	.byte %01010001, $C4, %00110000, $C6, %11111111, $CA, %11001100, $CC, %00000011, $CE, %11111111, $D2, %11001100, $D3, %11111111, $D6, %11001100, $D7, %11111111, $DE, %11110000, $DF, %00001111, $E1, %00000000, $E6, %00001100, $E9, %00001100, $EC, %00111100, $ED, %00000011, $F5, %00000011
frame3761:
	.byte %01001011, $C5, %11111100, $CD, %11001111, $D2, %00001100, $D5, %11001100, $D6, %11111111, $DE, %11111111, $DF, %11111111, $E1, %00110000, $E6, %00000000, $F5, %00000000, $F9, %00000000
frame3762:
	.byte %01001101, $C3, %00110000, $C4, %11111100, $C5, %11111111, $CC, %11111111, $CD, %11111111, $D4, %11001100, $D5, %11111111, $DC, %00111111, $DD, %11001111, $E1, %00000000, $E5, %00111100, $E6, %00000011, $E7, %00001111
frame3763:
	.byte %01010001, $C3, %00000000, $C4, %11111111, $CA, %00000000, $D2, %00000000, $D4, %11111111, $DA, %00000000, $DC, %11111111, $DD, %11111111, $E2, %00000000, $E4, %00111111, $E5, %00111111, $E6, %00001111, $E9, %00000000, $EA, %00001100, $EC, %11111100, $F2, %11000000, $FA, %00001100
frame3764:
	.byte %01001111, $C3, %11001100, $CB, %11111100, $D3, %11001111, $E2, %11000000, $E3, %11001100, $E5, %11111111, $E6, %11111111, $EA, %00000000, $EC, %11110011, $ED, %00001111, $F2, %00000000, $F4, %11111111, $F5, %00000011, $FA, %00000000, $FC, %00001111
frame3765:
	.byte %01001111, $C3, %11111111, $C7, %00110011, $CB, %11111111, $CF, %11110011, $D2, %00001100, $D3, %11111111, $E2, %00000000, $E3, %11111111, $E4, %11111111, $E7, %00000011, $EB, %11001100, $EC, %11111111, $ED, %00111111, $F3, %11001100, $FB, %00001100
frame3766:
	.byte %01010001, $C2, %11001100, $C7, %00110000, $CA, %11001100, $CF, %11001111, $D2, %11001100, $DA, %11001100, $E2, %00001100, $E7, %11001100, $EB, %00000000, $EE, %00000011, $EF, %11111100, $F3, %00000000, $F5, %00111111, $F7, %11111111, $FB, %00000000, $FD, %00000011, $FF, %00001111
frame3767:
	.byte %01010100, $C7, %00000011, $CF, %00000011, $D2, %11111111, $D7, %00111111, $DA, %11111100, $E2, %11001100, $E7, %00001111, $EB, %00001100, $EC, %11001111, $ED, %11111111, $EE, %00110011, $EF, %00000000, $F4, %11001100, $F5, %11111111, $F6, %00110011, $F7, %00000000, $FC, %00001100, $FD, %00001111, $FE, %00000011, $FF, %00000000
frame3768:
	.byte %01001111, $C2, %11111100, $C6, %00111111, $CA, %11111111, $CE, %11110011, $D6, %11110011, $D7, %00000000, $DA, %11111111, $E2, %11111111, $EA, %00001100, $EB, %00001111, $EC, %00001111, $EE, %11001111, $F4, %00000000, $F6, %11111111, $FE, %00001111
frame3769:
	.byte %01001011, $C2, %11111111, $C6, %11111100, $C7, %00000000, $CE, %11001111, $D9, %11001100, $E1, %00001100, $E7, %00000011, $EA, %00001111, $ED, %11001111, $EE, %11111111, $FC, %00000000
frame3770:
	.byte %01010011, $C6, %00110000, $C7, %11001100, $CE, %00000011, $D1, %11001100, $D5, %11111100, $D6, %11110000, $D7, %11111100, $DF, %00111100, $E1, %11001111, $E6, %00111111, $E7, %00110000, $E9, %00001100, $EB, %00111111, $ED, %11001100, $EE, %00110011, $F5, %11001100, $F6, %00110011, $FD, %00001100, $FE, %00000011
frame3771:
	.byte %01010001, $C7, %00110000, $CD, %00111111, $CE, %11000000, $D5, %00110011, $D6, %11000000, $D7, %11001100, $D9, %11111100, $DE, %11110011, $DF, %00110000, $E6, %11111111, $E7, %00000000, $EA, %11001111, $EB, %11111111, $ED, %11001111, $EE, %00111111, $F5, %11111100, $FD, %00001111
frame3772:
	.byte %01001110, $C5, %00110011, $C6, %00000011, $C7, %11110000, $C9, %11001100, $CD, %11001111, $D4, %11110011, $D7, %11111100, $DD, %11110011, $DF, %00000011, $E1, %11111111, $E6, %00111111, $EC, %00111111, $F5, %11111111, $FE, %00001111
frame3773:
	.byte %01010010, $C5, %00110000, $C6, %00000000, $C7, %00000000, $C9, %11000000, $CD, %11111100, $CE, %11001100, $CF, %00110000, $D4, %11111111, $D5, %00001100, $D6, %00000000, $D7, %11110011, $E6, %00110011, $E9, %00001111, $EA, %11111111, $ED, %00111111, $EE, %11111111, $F5, %11110011, $F6, %00111111
frame3774:
	.byte %01010011, $C6, %00110000, $CD, %00111111, $CF, %00000000, $D1, %11111100, $D5, %00000000, $D6, %00000011, $D7, %11110000, $DD, %00110000, $DE, %11111100, $E0, %00001100, $E5, %11110011, $E9, %11001111, $EC, %00110011, $ED, %00110011, $F4, %11000000, $F5, %00110011, $F6, %11110011, $FC, %00001100, $FD, %00000011
frame3775:
	.byte %01001011, $C2, %11111100, $C4, %11110011, $CD, %00111100, $CE, %00000000, $D4, %11110011, $DE, %11001100, $DF, %00001111, $E5, %11111111, $EC, %00000011, $ED, %00111111, $FE, %00000011
frame3776:
	.byte %01010000, $C5, %00000000, $CD, %00001100, $D4, %11000011, $D5, %00110000, $D6, %11001111, $D7, %00111100, $D9, %11111111, $DE, %11001111, $E5, %11110011, $ED, %00001111, $EE, %11001111, $F4, %11001100, $F5, %00110000, $F6, %11111111, $FD, %00000000, $FE, %00000000
frame3777:
	.byte %01010001, $C4, %00110011, $C6, %00000000, $C9, %00000000, $CD, %11000000, $CE, %11000000, $D4, %11001111, $D6, %00000011, $D7, %00001100, $DE, %11111100, $DF, %00000011, $E0, %11001100, $E5, %00110011, $E9, %11111111, $EC, %11000011, $EE, %11001100, $F5, %00000000, $F6, %11111100
frame3778:
	.byte %01001111, $C2, %11001100, $C4, %00110000, $C5, %11000000, $CC, %11110011, $CD, %00000000, $CE, %00000011, $D5, %11000000, $D6, %11000011, $D7, %00000000, $DC, %11110000, $DD, %11110000, $E5, %11110011, $E6, %11110011, $EC, %11001111, $ED, %00000011
frame3779:
	.byte %01001010, $C2, %11000000, $C5, %00000000, $CE, %00000000, $D1, %11001100, $D5, %11000011, $D6, %00000011, $DC, %11110011, $DF, %11000011, $F6, %11001100, $FE, %00001100
frame3780:
	.byte %01000111, $CA, %11111100, $D4, %11111111, $D5, %11110000, $DC, %11110000, $DD, %00000000, $DF, %00000000, $E5, %11110000
frame3781:
	.byte %01001010, $C2, %00000000, $C3, %11110000, $CD, %11000000, $D4, %11110011, $D5, %00000011, $DC, %00110000, $DD, %11000000, $DE, %11110000, $DF, %00110000, $E0, %11000000
frame3782:
	.byte %01001000, $CC, %00110011, $D1, %11000000, $D4, %11000011, $D9, %11111100, $DD, %11000011, $DF, %00110011, $E5, %11110011, $E6, %11000011
frame3783:
	.byte %01000110, $C4, %00000000, $CA, %11001100, $D5, %00000000, $D6, %00110011, $DF, %00000000, $F7, %00000011
frame3784:
	.byte %01001000, $CD, %00000000, $D6, %00000011, $DC, %11110000, $DD, %00000011, $DE, %11111100, $DF, %00000011, $ED, %00110011, $FE, %00000000
frame3785:
	.byte %01001011, $CA, %11000000, $D4, %11110011, $D6, %00000000, $D9, %11001100, $DE, %11110000, $DF, %00000000, $E0, %00000000, $E5, %11000000, $E8, %00000011, $E9, %11001111, $EE, %11001111
frame3786:
	.byte %01001000, $DD, %00001100, $E5, %00000000, $E6, %00000011, $E8, %00110011, $ED, %00110000, $EE, %11000011, $F0, %00110011, $F8, %00000011
frame3787:
	.byte %01000111, $C3, %11000000, $D5, %00111100, $DC, %11111100, $E7, %11000000, $EE, %00000011, $EF, %00110000, $F7, %00110000
frame3788:
	.byte %01001000, $C3, %00000000, $D0, %00001100, $D2, %11111100, $D5, %00000000, $DF, %00110000, $E7, %00000011, $E8, %00001100, $F6, %00000000
frame3789:
	.byte %01001110, $CA, %00000000, $D0, %00000000, $D4, %00111111, $DC, %11111111, $DD, %00000000, $DE, %11000000, $DF, %00000000, $E5, %00000011, $E6, %00001111, $E8, %11001100, $F0, %00001111, $F7, %00110011, $F8, %00001111, $FF, %00000011
frame3790:
	.byte %01000101, $D5, %00111100, $DC, %00111111, $DF, %00110011, $EE, %00000000, $F8, %00001100
frame3791:
	.byte %01001010, $D1, %00000000, $D4, %11111111, $D6, %00110000, $DD, %00001100, $DE, %00000011, $DF, %11110000, $EC, %11111111, $ED, %00110011, $EF, %00110011, $F0, %11001100
frame3792:
	.byte %01001000, $D5, %00110000, $DC, %00110011, $DE, %00110000, $DF, %00110000, $E5, %11001111, $E6, %00000000, $ED, %00000011, $F7, %00111111
frame3793:
	.byte %01000101, $D5, %00000000, $E6, %00001100, $EE, %00001100, $F7, %00110011, $FF, %00000000
frame3794:
	.byte %01000100, $D6, %00110011, $DD, %00000000, $E7, %00000000, $F7, %11111111
frame3795:
	.byte %01001001, $DC, %11110011, $DE, %11111100, $E5, %11000011, $E7, %00000011, $E8, %00001100, $EC, %00111111, $EF, %11000011, $F7, %11001100, $FF, %00001100
frame3796:
	.byte %01000110, $D6, %00110000, $E8, %00000000, $EC, %11111111, $ED, %00001100, $EF, %11000000, $F2, %00000011
frame3797:
	.byte %01001100, $CD, %00110000, $D6, %00000000, $DC, %11111111, $DD, %00110000, $DE, %11000000, $DF, %00000000, $E5, %11000000, $E6, %00111100, $ED, %00111100, $EF, %11001100, $F1, %00000011, $F3, %00000011
frame3798:
	.byte %01001001, $C9, %00001100, $CD, %00000000, $D5, %00001100, $DD, %00110011, $DF, %00110000, $E5, %00001100, $E7, %00000000, $F0, %00001100, $FF, %00000000
frame3799:
	.byte %01001000, $C9, %00000000, $D6, %00110000, $DE, %00000000, $E7, %00000011, $EE, %00000000, $EF, %00001100, $F7, %11000000, $F8, %00000000
frame3800:
	.byte %01000110, $DD, %00110000, $DF, %00000000, $E9, %11111111, $ED, %00111111, $EF, %00000000, $F7, %00000000
frame3801:
	.byte %01001001, $D5, %00000000, $D6, %00000000, $E5, %00000000, $E6, %00001100, $ED, %00110011, $F0, %00000000, $F2, %00001111, $F3, %00001111, $F4, %11000000
frame3802:
	.byte %01000101, $D1, %11000000, $D6, %00110000, $E7, %00000000, $F1, %00110011, $F9, %00000011
frame3803:
	.byte %01000111, $CC, %11110011, $DE, %00000011, $DF, %11000000, $E5, %00000011, $E6, %00000000, $EF, %00110000, $F0, %11000000
frame3804:
	.byte %01000010, $E5, %00000000, $E8, %00001100
frame3805:
	.byte %01000011, $DD, %00110011, $E7, %00000011, $F4, %11001100
frame3806:
	.byte %01000110, $D2, %11111111, $DE, %00110000, $DF, %00000000, $E5, %00111100, $EF, %00000000, $F1, %00111111
frame3807:
	.byte %01000111, $D9, %11001111, $DE, %00000000, $DF, %11000000, $E0, %11000000, $E6, %11000000, $E7, %00000000, $F4, %11001111
frame3808:
	.byte %01001000, $CD, %00110000, $D6, %00000000, $D9, %11111111, $DC, %11110011, $DE, %00110000, $E7, %00110000, $E8, %11001100, $EF, %11000000
frame3809:
	.byte %01000111, $C3, %11110000, $CA, %11000000, $CD, %00000000, $D1, %11110000, $D5, %00001100, $E0, %11001100, $E7, %00000000
frame3810:
	.byte %01000101, $D1, %11111100, $DD, %00110000, $E7, %00000011, $EF, %00000000, $F8, %00001100
frame3811:
	.byte %01001010, $CA, %11001100, $D4, %00111111, $D5, %00000000, $DD, %00111100, $DF, %00000000, $E0, %11111100, $E5, %11110000, $E6, %11001100, $E8, %11001111, $FC, %00001111
frame3812:
	.byte %01001101, $CC, %00110011, $D8, %11001100, $DC, %11111111, $DD, %00001100, $DE, %00000000, $E0, %11111111, $E5, %00000011, $E6, %00111100, $E7, %00000000, $E8, %11111111, $ED, %00111111, $F0, %00001100, $F4, %00001111
frame3813:
	.byte %01001100, $C2, %11000000, $D0, %11000000, $D1, %11111111, $D4, %00110011, $D5, %00110000, $DD, %11000000, $E5, %00001100, $E6, %11110000, $F0, %11001100, $F4, %00110011, $F8, %00001111, $FC, %00000011
frame3814:
	.byte %01001001, $CA, %11111111, $D5, %00000000, $DD, %00110000, $DE, %11000000, $E5, %00000000, $E6, %11111100, $ED, %00000000, $F0, %11001111, $F8, %00001100
frame3815:
	.byte %01001000, $D0, %11111100, $D4, %11110011, $D8, %11111111, $DD, %00110011, $DE, %00000000, $E6, %00111100, $F2, %00111111, $FB, %00001100
frame3816:
	.byte %01001110, $C2, %11110000, $C3, %00110000, $C8, %00001100, $C9, %11000000, $CC, %00110000, $D0, %11111111, $D4, %00110011, $DC, %11110011, $DD, %00000011, $E5, %11000000, $ED, %00000011, $F3, %11111111, $F4, %00000011, $FC, %00000000
frame3817:
	.byte %01010000, $C1, %11000000, $C8, %11000000, $C9, %11111100, $CC, %00000000, $D4, %00000000, $DC, %11110000, $DD, %00110000, $DE, %00110000, $E4, %00111111, $E6, %00000011, $EC, %00110011, $F1, %11111111, $F2, %11001111, $F3, %11001111, $F4, %00000000, $FB, %00001111
frame3818:
	.byte %01001111, $C1, %11001100, $C2, %11110011, $C8, %11110000, $C9, %11111111, $D4, %00110000, $DC, %00111100, $DD, %00000000, $DE, %00000000, $E4, %00110011, $E5, %00110000, $E6, %00000000, $EC, %00111111, $ED, %00000000, $F3, %00111111, $FB, %00000011
frame3819:
	.byte %01010000, $C1, %11111111, $C8, %11111100, $CB, %00110011, $D3, %00110011, $D4, %00000000, $DB, %11110011, $DC, %00110000, $DD, %11000000, $E4, %00110000, $E5, %00111100, $EC, %00000000, $F2, %11111111, $F3, %00001111, $F8, %00001111, $FA, %00001100, $FB, %00000000
frame3820:
	.byte %01001100, $C0, %11001100, $C3, %00000000, $C8, %11111111, $DB, %00110011, $DC, %00000000, $DD, %00000000, $E4, %11001100, $E5, %00110000, $EC, %00000011, $F1, %00111111, $F3, %00000011, $FA, %00001111
frame3821:
	.byte %01001110, $C0, %11111111, $CB, %00000000, $D3, %00110000, $DB, %00110000, $E3, %00110011, $E4, %11111100, $E5, %00000000, $EB, %00111111, $EC, %00000000, $F1, %11111111, $F2, %00111111, $F3, %00000000, $F9, %00001111, $FA, %00000011
frame3822:
	.byte %01001010, $C2, %00110000, $CA, %00110011, $D2, %00110011, $DA, %11110011, $DB, %00000011, $E3, %11110000, $E4, %00001111, $EB, %00000000, $F2, %00000011, $FA, %00000000
frame3823:
	.byte %01001010, $C2, %00000000, $CA, %00000000, $D2, %00001100, $D3, %00000000, $DB, %00000000, $E3, %11111100, $E4, %00000000, $F0, %11111111, $F2, %00000000, $FA, %00000011
frame3824:
	.byte %01000111, $C1, %00110011, $C9, %00110011, $D2, %00110000, $DA, %00110011, $E3, %00000011, $EA, %00110011, $F2, %00110011
frame3825:
	.byte %01001001, $C1, %00000000, $C6, %00000011, $C9, %11000000, $DA, %11111111, $E2, %00111111, $E3, %00000000, $E6, %00001100, $EA, %00111111, $FA, %00001111
frame3826:
	.byte %01001011, $C0, %00110011, $C6, %00000000, $C8, %00110011, $C9, %00000000, $D0, %11110011, $D2, %11110011, $E2, %11111111, $E6, %00000000, $E8, %11001111, $F0, %11111100, $F2, %11111111
frame3827:
	.byte %01000111, $C8, %00110000, $C9, %11110000, $CA, %00110000, $D0, %11110000, $D2, %11111111, $EA, %11111111, $F3, %00110000
frame3828:
	.byte %01000110, $C0, %00000000, $C8, %00000000, $CA, %11110000, $D8, %11001111, $E8, %11000000, $FB, %00000011
frame3829:
	.byte %01001001, $C9, %11111100, $D0, %11000000, $D3, %00110011, $D8, %11001100, $DB, %00000011, $E0, %11001111, $E8, %11001100, $F0, %11001100, $F3, %00110011
frame3830:
	.byte %01001010, $CA, %11111111, $CB, %00110000, $D0, %11000011, $D8, %11000000, $DB, %00110011, $E3, %00000011, $EB, %00110011, $F4, %11000000, $F8, %00001100, $FC, %00001100
frame3831:
	.byte %01000100, $D0, %11000000, $E3, %00110011, $F4, %00000000, $FC, %00000000
frame3832:
	.byte %01000101, $E0, %11001100, $F3, %11110011, $F7, %11000000, $FB, %00001111, $FF, %00000011
frame3833:
	.byte %01000100, $CB, %00110011, $E8, %11000000, $F7, %00000000, $FF, %00001100
frame3834:
	.byte %01000100, $D8, %00000000, $DB, %00111111, $F3, %11111111, $FF, %00000000
frame3835:
	.byte %01000100, $C9, %11111111, $DB, %00110011, $E7, %00110000, $F3, %11110011
frame3836:
	.byte %01000001, $E0, %00001100
frame3837:
	.byte %01000011, $C1, %11000000, $E3, %00001111, $E7, %00000000
frame3838:
	.byte %01000010, $C2, %00110000, $E8, %11001100
frame3839:
	.byte %01000100, $D0, %11001100, $D8, %11000000, $E0, %00000000, $F3, %00110011
frame3840:
	.byte %01000010, $CB, %00110000, $E0, %11000000
frame3841:
	.byte %01000010, $F0, %11111100, $F8, %00001111
frame3842:
	.byte %01000001, $E0, %00000000
frame3843:
	.byte %01000101, $C1, %11110000, $C8, %11000000, $D0, %11001111, $D8, %11001100, $E0, %00001100
frame3844:
	.byte %01000001, $E0, %00000000
frame3845:
	.byte %01000100, $C8, %11001100, $E0, %11001100, $EB, %00110000, $F0, %11111111
frame3846:
	.byte $88
frame3847:
	.byte %01000011, $D3, %00110000, $DB, %00110000, $E3, %00000011
frame3848:
	.byte %01000010, $CB, %00000000, $E8, %11111100
frame3849:
	.byte %01000010, $C2, %00110011, $D3, %00000000
frame3850:
	.byte %01000010, $DB, %00000000, $E8, %11111111
frame3851:
	.byte %01000001, $C0, %11000000
frame3852:
	.byte %01000010, $D0, %11111111, $D8, %11111100
frame3853:
	.byte %01000010, $E0, %11001111, $E3, %00000000
frame3854:
	.byte %01000010, $C2, %00110000, $D8, %11111111
frame3855:
	.byte %01000011, $C1, %11111100, $D0, %11001111, $E3, %00110000
frame3856:
	.byte %01000011, $D0, %11111111, $E3, %00000000, $EB, %00000000
frame3857:
	.byte %01000001, $C2, %00000000
frame3858:
	.byte %01000010, $C0, %00000000, $CA, %11110011
frame3859:
	.byte %01000010, $E0, %00001111, $EB, %00110000
frame3860:
	.byte $88
frame3861:
	.byte $88
frame3862:
	.byte $88
frame3863:
	.byte %01000001, $CA, %11111111
frame3864:
	.byte %01000001, $D8, %11111100
frame3865:
	.byte %01000010, $C2, %00110000, $E8, %11001100
frame3866:
	.byte $88
frame3867:
	.byte %01000011, $EB, %00110011, $F0, %11111100, $F3, %11111111
frame3868:
	.byte %01000100, $D0, %11001111, $D3, %00110000, $D8, %11001100, $DB, %00110000
frame3869:
	.byte %01000101, $C2, %11110000, $CB, %00110000, $E0, %00001100, $E3, %00110000, $F8, %00001100
frame3870:
	.byte %01000100, $C1, %11110000, $D3, %00110011, $E0, %00001111, $E3, %00110011
frame3871:
	.byte %01000100, $C2, %11110011, $DB, %00110011, $F0, %11001100, $F9, %00001100
frame3872:
	.byte %01000100, $C8, %11000000, $CB, %00110011, $E0, %00001100, $EB, %11110011
frame3873:
	.byte $88
frame3874:
	.byte %01000001, $D8, %11000000
frame3875:
	.byte %01000011, $C8, %00000000, $E8, %11000000, $F9, %00001111
frame3876:
	.byte %01000010, $D0, %11001100, $D8, %00000000
frame3877:
	.byte $88
frame3878:
	.byte %01000011, $E0, %00000000, $E3, %00111111, $E8, %00000000
frame3879:
	.byte %01000011, $E0, %11000000, $F0, %11000000, $F8, %00000000
frame3880:
	.byte %01000011, $C1, %11000000, $DB, %11110011, $E0, %00000000
frame3881:
	.byte %01000001, $F0, %00000000
frame3882:
	.byte %01000101, $C2, %00110000, $D0, %11000000, $E1, %11001111, $EB, %11111111, $FC, %00000011
frame3883:
	.byte %01000010, $C1, %00000000, $E1, %11111111
frame3884:
	.byte $88
frame3885:
	.byte %01000001, $F4, %00110000
frame3886:
	.byte %01000001, $C9, %11111100
frame3887:
	.byte %01000001, $E3, %11111111
frame3888:
	.byte $88
frame3889:
	.byte %01000011, $E1, %11001111, $E4, %00110000, $E9, %11111100
frame3890:
	.byte %01000011, $D3, %11110011, $DB, %11111111, $E1, %00001111
frame3891:
	.byte %01000100, $CE, %00110000, $D3, %11111111, $E3, %00111111, $E4, %00000000
frame3892:
	.byte %01000101, $C2, %11110000, $CB, %11110011, $CE, %00000000, $E1, %11001111, $E9, %11001100
frame3893:
	.byte %01000001, $D9, %11111100
frame3894:
	.byte %01000001, $E9, %11111100
frame3895:
	.byte %01000101, $C1, %11000000, $D0, %00000000, $E3, %11111111, $E9, %11001100, $F4, %00110011
frame3896:
	.byte %01000100, $C3, %00110000, $C9, %11001100, $D9, %11001100, $F1, %11111100
frame3897:
	.byte %01000010, $CB, %11111111, $F1, %11001100
frame3898:
	.byte %01000001, $EC, %00110000
frame3899:
	.byte %01000001, $C2, %11111100
frame3900:
	.byte $88
frame3901:
	.byte $88
frame3902:
	.byte %01000010, $DC, %00110000, $EC, %00110011
frame3903:
	.byte %01000010, $C3, %11110000, $C7, %11000000
frame3904:
	.byte %01000010, $C7, %00000000, $E4, %00110011
frame3905:
	.byte %01000101, $C1, %00000000, $D1, %11001111, $D4, %00000011, $DC, %00110011, $E1, %11001100
frame3906:
	.byte $88
frame3907:
	.byte %01000100, $CC, %00110000, $D4, %00110011, $E1, %00001100, $E4, %00000011
frame3908:
	.byte %01000011, $C2, %11110000, $C3, %11110011, $ED, %00000011
frame3909:
	.byte %01000101, $C9, %11000000, $D1, %11111100, $E1, %11001100, $E9, %11000000, $F4, %11110011
frame3910:
	.byte %01000101, $C3, %00110011, $E1, %11111100, $E4, %00110011, $ED, %00000000, $F4, %00110011
frame3911:
	.byte %01000010, $C2, %11000000, $E1, %11001100
frame3912:
	.byte %01000010, $D1, %11001100, $E4, %11110011
frame3913:
	.byte %01000010, $E3, %00111111, $E9, %11001100
frame3914:
	.byte %01000001, $E4, %00110011
frame3915:
	.byte %01000010, $CC, %00000000, $D1, %11111100
frame3916:
	.byte %01000100, $C2, %11110000, $C9, %11001100, $D4, %00110000, $E4, %00000011
frame3917:
	.byte %01000001, $F1, %11111111
frame3918:
	.byte %01000011, $DC, %00110000, $EC, %00110000, $FB, %00000011
frame3919:
	.byte %01000011, $D4, %00000000, $E3, %11111111, $E9, %11111100
frame3920:
	.byte %01000011, $D1, %11111111, $EC, %00000000, $FB, %00001111
frame3921:
	.byte %01000010, $C1, %11000000, $D9, %11111100
frame3922:
	.byte %01000100, $D9, %11001100, $DC, %00000000, $E9, %11111111, $F4, %00110000
frame3923:
	.byte %01000001, $D9, %11111100
frame3924:
	.byte %01000100, $C0, %00110000, $C9, %11111100, $E1, %11111100, $E4, %00000000
frame3925:
	.byte %01000101, $C4, %00000011, $D1, %11001111, $D9, %11111111, $E4, %00000011, $F4, %00000000
frame3926:
	.byte %01000101, $C3, %00110000, $CB, %11110011, $D1, %11111111, $E1, %11111111, $E4, %00000000
frame3927:
	.byte %01000010, $C0, %00000000, $FC, %00000000
frame3928:
	.byte %01000111, $C4, %00000000, $D0, %00001100, $DB, %11110011, $E3, %00111111, $E6, %00000011, $F0, %11000000, $F8, %00001100
frame3929:
	.byte %01000001, $FC, %00000011
frame3930:
	.byte %01000101, $C8, %00001100, $DB, %00110011, $E6, %00000000, $EC, %00110000, $F4, %00110011
frame3931:
	.byte %01000100, $E8, %11000000, $EB, %11110011, $EC, %00110011, $F0, %11001100
frame3932:
	.byte %01000100, $C3, %00000000, $C8, %00000000, $E8, %00000000, $FB, %00001100
frame3933:
	.byte %01000100, $CB, %00110011, $D3, %11110011, $E0, %00001100, $E3, %00110011
frame3934:
	.byte %01000100, $E3, %11110011, $EB, %00110011, $EC, %00111100, $FB, %00001111
frame3935:
	.byte %01000100, $C1, %00000000, $D0, %11001100, $E3, %00110011, $EC, %11001100
frame3936:
	.byte %01000100, $C2, %11000000, $D0, %11000000, $D3, %00110011, $F4, %00111100
frame3937:
	.byte %01000011, $DB, %00111111, $E1, %11001111, $E8, %11000000
frame3938:
	.byte $88
frame3939:
	.byte %01000001, $F3, %11110011
frame3940:
	.byte %01000101, $C9, %11111111, $DB, %00110011, $E1, %11111111, $E6, %11000000, $E8, %11001100
frame3941:
	.byte %01000010, $CB, %00110000, $F4, %00111111
frame3942:
	.byte %01000001, $E6, %00000000
frame3943:
	.byte %01000100, $C1, %11000000, $EC, %11111111, $F3, %00110011, $F4, %11111111
frame3944:
	.byte %01000010, $D0, %11001100, $D8, %11000000
frame3945:
	.byte %01000100, $C2, %11110000, $C4, %11000000, $F0, %11111100, $F8, %00001111
frame3946:
	.byte %01000010, $C2, %00110000, $C4, %00000000
frame3947:
	.byte %01000110, $C1, %11110000, $C8, %11000000, $D0, %11001111, $D8, %11001100, $ED, %00000011, $FC, %00001111
frame3948:
	.byte %01000011, $E3, %00000011, $EB, %00110000, $ED, %00110011
frame3949:
	.byte %01000010, $EB, %00111100, $F0, %11111111
frame3950:
	.byte %01000100, $C8, %11001100, $E0, %11001100, $EB, %11111100, $F5, %00000011
frame3951:
	.byte %01000011, $CB, %00000000, $DB, %00110000, $F3, %00111111
frame3952:
	.byte %01000011, $D3, %00110000, $E8, %11111100, $F5, %00110011
frame3953:
	.byte %01000100, $D0, %11111111, $D3, %00000000, $ED, %11110011, $F3, %11111111
frame3954:
	.byte %01000011, $DB, %00000000, $E8, %11111111, $EB, %11111111
frame3955:
	.byte %01000011, $C2, %00110011, $D3, %00110000, $F5, %00111111
frame3956:
	.byte %01000010, $C0, %11000000, $FD, %00000011
frame3957:
	.byte %01000100, $C2, %00110000, $D8, %11111100, $E0, %11001111, $F5, %11111111
frame3958:
	.byte %01000100, $D3, %00000000, $D8, %11111111, $E3, %00000000, $F6, %00000011
frame3959:
	.byte %01000001, $EF, %00001100
frame3960:
	.byte %01000011, $C2, %00000000, $D3, %11000000, $F6, %00110011
frame3961:
	.byte %01000101, $C0, %00000000, $CA, %11110011, $E3, %00110000, $EF, %00000000, $FD, %00001111
frame3962:
	.byte %01000101, $D3, %00000000, $D4, %00000011, $E0, %00001111, $E3, %00000000, $F6, %11110011
frame3963:
	.byte %01000010, $E0, %00111111, $FE, %00000011
frame3964:
	.byte %01000010, $C1, %11000000, $FE, %00001111
frame3965:
	.byte %01000011, $DC, %00000011, $EB, %11111100, $FE, %00000011
frame3966:
	.byte %01000011, $D4, %00000000, $DC, %00000000, $E0, %00001111
frame3967:
	.byte %01000011, $C1, %11110000, $CA, %11111111, $D8, %11111100
frame3968:
	.byte %01000001, $DC, %00001100
frame3969:
	.byte %01000001, $E8, %11001100
frame3970:
	.byte %01000101, $C2, %00110000, $DC, %00000000, $EB, %11110000, $ED, %11110000, $FE, %00001111
frame3971:
	.byte %01000010, $EB, %11110011, $EC, %11110000
frame3972:
	.byte %01000101, $D8, %11001100, $DB, %00110000, $DD, %00000011, $ED, %00110000, $F0, %11111100
frame3973:
	.byte %01000110, $CB, %00110000, $D3, %00110000, $DD, %00000000, $E0, %00001100, $F6, %00110000, $F8, %00001100
frame3974:
	.byte %01001000, $D0, %11001111, $D3, %00110011, $D4, %11000000, $E3, %00110011, $EB, %00110011, $EC, %00000000, $ED, %00000000, $F0, %11001100
frame3975:
	.byte %01000111, $C2, %11110000, $C8, %11000000, $DB, %00110011, $DD, %00001100, $E0, %00001111, $EB, %11110011, $F9, %00001100
frame3976:
	.byte %01000010, $C2, %11110011, $F5, %11110011
frame3977:
	.byte %01000110, $D8, %11000000, $DD, %00000000, $E0, %00001100, $F4, %11110000, $F5, %11110000, $F6, %00000000
frame3978:
	.byte %01000110, $C8, %00000000, $CB, %00110011, $D4, %00000000, $DE, %00000011, $E8, %11000000, $FE, %00000011
frame3979:
	.byte %01000010, $F5, %00110000, $F9, %00001111
frame3980:
	.byte %01000101, $D0, %11001100, $D8, %00000000, $DE, %00000000, $F4, %00000000, $F5, %00000000
frame3981:
	.byte %01000010, $DE, %00001100, $FE, %00000000
frame3982:
	.byte %01000100, $C1, %11000000, $DE, %00000000, $E0, %00000000, $E8, %00000000
frame3983:
	.byte %01000011, $C2, %11110000, $E3, %00111111, $F8, %00000000
frame3984:
	.byte %01000001, $C2, %00110000
frame3985:
	.byte %01000010, $D0, %11000000, $F0, %00000000
frame3986:
	.byte %01000101, $C1, %00000000, $DB, %11110011, $F4, %11110000, $F5, %00110000, $FE, %00000011
frame3987:
	.byte %01000010, $DF, %00110000, $F5, %11110000
frame3988:
	.byte %01001000, $CB, %00110000, $DD, %00000011, $DF, %00000000, $EB, %11111111, $F4, %11111111, $F5, %11110011, $F6, %00110000, $FE, %00001111
frame3989:
	.byte %01000101, $C9, %11111100, $CB, %00110011, $E3, %11111111, $EC, %00110000, $F5, %11111111
frame3990:
	.byte %01000100, $DF, %11000000, $E3, %11001111, $EC, %11110000, $ED, %00110000
frame3991:
	.byte %01000011, $DD, %00000000, $DF, %00000000, $E3, %11111111
frame3992:
	.byte %01000001, $E4, %00110000
frame3993:
	.byte %01000001, $E9, %11111100
frame3994:
	.byte %01000001, $DB, %11111111
frame3995:
	.byte %01000011, $D3, %11111111, $E1, %11001111, $E9, %11001100
frame3996:
	.byte %01000010, $E1, %00001111, $E4, %00000000
frame3997:
	.byte %01000011, $CB, %11110011, $D9, %11111100, $F9, %00001100
frame3998:
	.byte %01000010, $C2, %11110000, $F9, %00001111
frame3999:
	.byte %01000011, $D9, %11001100, $E1, %11001111, $E3, %00111111
frame4000:
	.byte %01000100, $C9, %11001100, $D0, %00000000, $D1, %11111100, $E3, %11111111
frame4001:
	.byte %01000011, $C3, %00110000, $CB, %11111111, $F1, %11001100
frame4002:
	.byte %01000001, $D1, %11111111
frame4003:
	.byte %01000001, $C1, %11000000
frame4004:
	.byte %01000011, $C2, %11111100, $DC, %00110000, $ED, %00000000
frame4005:
	.byte %01000010, $DC, %00000000, $EC, %00110000
frame4006:
	.byte %01000100, $DC, %00110000, $E4, %00110000, $EC, %00110011, $F5, %11110011
frame4007:
	.byte %01000100, $C1, %00000000, $E4, %00000000, $F4, %11110011, $F5, %11110000
frame4008:
	.byte %01000100, $C3, %11110000, $E1, %11001100, $E4, %00000011, $F6, %00000000
frame4009:
	.byte %01000100, $D4, %00110000, $DC, %00110011, $F5, %00110000, $FE, %00000011
frame4010:
	.byte %01000101, $CC, %00110000, $D4, %00110011, $E1, %00001100, $F4, %00110011, $F5, %00000000
frame4011:
	.byte %01000100, $C2, %11110000, $D1, %11111100, $F4, %11110011, $F5, %00110000
frame4012:
	.byte %01000010, $F5, %11110000, $FE, %00001111
frame4013:
	.byte %01000111, $C3, %00110000, $C9, %11000000, $E1, %11111100, $E9, %11000000, $F4, %11111111, $F5, %11110011, $F6, %00110000
frame4014:
	.byte %01000100, $C2, %11000000, $E1, %11001100, $E4, %00110011, $F5, %11111111
frame4015:
	.byte %01000100, $C2, %00000000, $D1, %11001100, $EC, %11110011, $ED, %00110000
frame4016:
	.byte %01000011, $C3, %00110011, $ED, %11110000, $F6, %00110011
frame4017:
	.byte %01000011, $D1, %11111100, $E4, %11110011, $F6, %11110011
frame4018:
	.byte %01000100, $C3, %00110000, $CC, %00000000, $E3, %00111111, $E9, %11001100
frame4019:
	.byte %01000011, $C3, %00110011, $D4, %00110000, $E4, %00110011
frame4020:
	.byte %01000010, $C9, %11001100, $E4, %00000011
frame4021:
	.byte %01000100, $C2, %11000000, $DC, %00110000, $EC, %11110000, $F1, %11111100
frame4022:
	.byte %01000011, $C2, %11110000, $D4, %00000000, $F1, %11111111
frame4023:
	.byte $88
frame4024:
	.byte %01000100, $C9, %11111100, $D1, %11111111, $E3, %00110011, $E9, %11111100
frame4025:
	.byte %01000101, $C1, %11000000, $C3, %00110000, $CB, %11110011, $DC, %00000000, $E4, %00000000
frame4026:
	.byte %01000010, $C9, %11111111, $EC, %11111100
frame4027:
	.byte %01000110, $CB, %00110011, $D9, %11111111, $DD, %00000011, $E1, %11001111, $E3, %00110000, $EC, %11110000
frame4028:
	.byte %01000100, $C3, %00000000, $D3, %00111111, $E3, %00111100, $E9, %11111111
frame4029:
	.byte %01000011, $DB, %11110011, $E1, %11111111, $E3, %00110000
frame4030:
	.byte %01000011, $C2, %11111100, $D0, %11000000, $FB, %00001100
frame4031:
	.byte %01000010, $EB, %11110011, $ED, %00110000
frame4032:
	.byte %01001000, $DB, %00110011, $DD, %00000000, $E3, %00110011, $EC, %00000000, $ED, %00000000, $F6, %00110000, $F8, %00001100, $FB, %00001111
frame4033:
	.byte %01000010, $D3, %00110011, $D7, %00001100
frame4034:
	.byte %01000011, $E1, %11001111, $F0, %11000000, $F5, %11110000
frame4035:
	.byte %01000110, $D6, %00000011, $D7, %00000000, $D8, %00001100, $E0, %11000000, $F4, %11110000, $F6, %00000000
frame4036:
	.byte %01000100, $C2, %11110000, $D0, %00000000, $E0, %11001100, $F5, %00110000
frame4037:
	.byte %01000110, $C1, %00000000, $CB, %00110000, $D6, %00000000, $E3, %00000000, $EB, %00110011, $F5, %11110000
frame4038:
	.byte %01000101, $C2, %11000000, $E3, %00000011, $E8, %00000011, $F0, %11001100, $F6, %00110000
frame4039:
	.byte %01000011, $D0, %00001100, $F4, %11111111, $F5, %11111111
frame4040:
	.byte %01000110, $C2, %00000000, $E1, %11111111, $EB, %11110011, $EC, %11110000, $ED, %00110000, $F6, %11110011
frame4041:
	.byte %01000010, $E2, %00111111, $ED, %11110000
frame4042:
	.byte %01000101, $C9, %11111100, $D0, %11001100, $D8, %00000000, $E8, %00000000, $EC, %11111111
frame4043:
	.byte %01000011, $C9, %11111111, $CB, %00000000, $E8, %00000011
frame4044:
	.byte %01000011, $C2, %00110000, $C8, %11000000, $E8, %11000011
frame4045:
	.byte %01000011, $D8, %00001100, $DB, %00000011, $E3, %00000000
frame4046:
	.byte %01000010, $DD, %11000000, $E8, %11001111
frame4047:
	.byte $88
frame4048:
	.byte %01000010, $D8, %11001100, $E8, %11000011
frame4049:
	.byte %01000010, $E8, %11001111, $F6, %00110011
frame4050:
	.byte %01000100, $DD, %11001100, $E8, %11001100, $F0, %11111100, $F8, %00001111
frame4051:
	.byte %01000011, $C8, %11001100, $DB, %00000000, $E2, %11111111
frame4052:
	.byte %01000010, $DD, %11000000, $F0, %11111111
frame4053:
	.byte %01000011, $C1, %11000000, $EB, %11110000, $EC, %11110011
frame4054:
	.byte %01000010, $E2, %11110011, $EC, %11110000
frame4055:
	.byte %01000100, $C1, %11110000, $D3, %00000011, $ED, %00110000, $F6, %00110000
frame4056:
	.byte %01000100, $C8, %11111100, $D0, %11001111, $DD, %00000000, $E8, %11111111
frame4057:
	.byte %01000011, $D8, %11001111, $ED, %00000000, $FE, %00000011
frame4058:
	.byte %01000101, $CA, %11110011, $DA, %00111111, $EB, %00110000, $EC, %00000000, $F5, %11110011
frame4059:
	.byte %01000010, $E2, %00110011, $F6, %00000000
frame4060:
	.byte %01000111, $C8, %11111111, $D0, %11111111, $E0, %11111100, $E2, %00111111, $F3, %11110011, $F4, %11110000, $F5, %11110000
frame4061:
	.byte %01000011, $D8, %11111111, $E0, %11111111, $F5, %00110000
frame4062:
	.byte %01000110, $CA, %00110011, $E2, %00110011, $F3, %00110011, $F4, %00000000, $F5, %00000000, $FE, %00000000
frame4063:
	.byte %01000011, $F3, %11110011, $F4, %11110000, $FE, %00000011
frame4064:
	.byte %01000010, $EB, %00000000, $F5, %00110000
frame4065:
	.byte %01000111, $C1, %00000000, $C2, %00000000, $C8, %11111100, $D3, %00000000, $F3, %11111111, $F4, %11111111, $F5, %11110000
frame4066:
	.byte %01000011, $E2, %00000011, $EC, %00110000, $F5, %11110011
frame4067:
	.byte %01000100, $EB, %11000000, $EC, %11110000, $F5, %11111111, $F6, %00110000
frame4068:
	.byte %01000010, $EB, %11110000, $ED, %00110000
frame4069:
	.byte $88
frame4070:
	.byte %01000010, $C2, %00110000, $E2, %00110011
frame4071:
	.byte %01000010, $D8, %11111100, $E8, %11111100
frame4072:
	.byte %01000100, $D3, %00110011, $D8, %11001100, $E2, %00111111, $E8, %11001100
frame4073:
	.byte %01000011, $CA, %11110011, $E0, %00111111, $E2, %00110011
frame4074:
	.byte %01000100, $D0, %11001111, $D3, %00000011, $DA, %11111111, $E2, %11110011
frame4075:
	.byte %01000100, $C1, %11000000, $C8, %11001100, $E0, %11111111, $F0, %11111100
frame4076:
	.byte %01000101, $CA, %11111111, $D0, %11001100, $D3, %00110011, $E0, %11111100, $F8, %00001100
frame4077:
	.byte %01000011, $C2, %00110011, $F0, %11001100, $F9, %00001100
frame4078:
	.byte %01000001, $EB, %11110011
frame4079:
	.byte %01000010, $C2, %00110000, $E0, %11001100
frame4080:
	.byte %01000100, $E0, %00001100, $E2, %11111111, $E3, %00110000, $E8, %11001111
frame4081:
	.byte %01000010, $E0, %11001100, $E8, %11000011
frame4082:
	.byte %01000101, $C8, %11000000, $D3, %00111111, $D8, %00001100, $ED, %00000000, $F9, %00001111
frame4083:
	.byte %01000010, $E8, %00000000, $EB, %00110011
frame4084:
	.byte %01000011, $E0, %11000000, $E8, %00001100, $EC, %00000000
frame4085:
	.byte %01000101, $D8, %00000000, $E0, %00000000, $EB, %11110011, $F0, %11000000, $F5, %11110011
frame4086:
	.byte %01000100, $C1, %00000000, $F4, %11110000, $F5, %11110000, $F6, %00000000
frame4087:
	.byte %01000010, $E8, %00000000, $F8, %00000000
frame4088:
	.byte %01000101, $DB, %00000011, $EB, %00110011, $F0, %00000000, $F4, %00000000, $F5, %00000000
frame4089:
	.byte %01000100, $C2, %00000000, $DB, %00110011, $F4, %11110000, $F5, %11110000
frame4090:
	.byte %01000101, $C2, %11000000, $C4, %00000011, $C8, %00000000, $E3, %00000000, $FE, %00001111
frame4091:
	.byte %01000111, $C9, %11111100, $CB, %00110000, $D0, %00001100, $F4, %11111111, $F5, %11110011, $F6, %00110000, $F9, %00000011
frame4092:
	.byte %01000011, $C4, %00000000, $EC, %11110000, $F5, %11111111
frame4093:
	.byte %01000101, $D0, %00000000, $EB, %11110011, $ED, %00110000, $F6, %00110011, $F9, %00001111
frame4094:
	.byte %01000011, $D3, %00110011, $E3, %00000011, $ED, %11110000
frame4095:
	.byte %01000011, $D3, %00111111, $EC, %11111100, $F6, %11110011
frame4096:
	.byte %01000010, $D3, %11111111, $EC, %11111111
frame4097:
	.byte %01000001, $EC, %11111100
frame4098:
	.byte $88
frame4099:
	.byte $88
frame4100:
	.byte %01000010, $E3, %00110011, $EB, %11111111
frame4101:
	.byte %01000011, $CB, %00110011, $E9, %11001111, $EC, %11111111
frame4102:
	.byte %01000010, $DB, %00111111, $ED, %11110011
frame4103:
	.byte %01000010, $DB, %00110011, $E1, %11111100
frame4104:
	.byte %01000001, $D9, %11111100
frame4105:
	.byte %01000010, $D5, %00110000, $F1, %11111100
frame4106:
	.byte %01000101, $C2, %11110000, $E3, %11110011, $EC, %11111100, $ED, %11110000, $F1, %11001100
frame4107:
	.byte %01000101, $D4, %00000011, $D8, %00000011, $D9, %11001100, $EC, %11110000, $FF, %00000011
frame4108:
	.byte %01000101, $C2, %11111100, $CB, %11110011, $D8, %00000000, $DB, %11110011, $E1, %11001100
frame4109:
	.byte %01000100, $C3, %00110000, $CC, %00110000, $DB, %00111111, $E3, %11110000
frame4110:
	.byte %01000010, $D4, %00000000, $ED, %00110000
frame4111:
	.byte %01000100, $DB, %11111111, $E9, %11111111, $EC, %00110000, $ED, %00000000
frame4112:
	.byte %01000100, $C2, %11110000, $D5, %00000000, $E9, %11111100, $F6, %11110000
frame4113:
	.byte %01000100, $E3, %11110011, $EC, %00110011, $F4, %11110011, $F5, %11110000
frame4114:
	.byte %01000010, $D1, %11001111, $D8, %11000000
frame4115:
	.byte %01000001, $D8, %00000000
frame4116:
	.byte %01000101, $C2, %11000000, $C9, %11001100, $E3, %11111111, $F4, %11111111, $F5, %11111111
frame4117:
	.byte %01000100, $C9, %11000000, $CC, %00000000, $D4, %00110000, $F6, %11110011
frame4118:
	.byte %01001000, $C2, %00000000, $D1, %11001100, $D4, %00110011, $E3, %00111111, $E9, %11001100, $EC, %11110011, $ED, %11110000, $F6, %11111111
frame4119:
	.byte %01000010, $EE, %00110000, $FF, %00000000
frame4120:
	.byte %01000100, $C3, %00000000, $D9, %11111100, $EC, %11111111, $ED, %11110011
frame4121:
	.byte %01000011, $D1, %11111111, $D9, %11001100, $ED, %11111111
frame4122:
	.byte $88
frame4123:
	.byte %01000011, $CB, %00110011, $D4, %00000011, $F1, %11111100
frame4124:
	.byte $88
frame4125:
	.byte %01000100, $C2, %00001100, $C9, %11111100, $DC, %00001100, $F1, %11111111
frame4126:
	.byte %01000010, $C2, %11001100, $DB, %11110011
frame4127:
	.byte %01000100, $C2, %11000000, $D4, %00000000, $DB, %00110011, $E9, %11111100
frame4128:
	.byte %01000011, $D9, %11111100, $E3, %00110011, $E9, %11111111
frame4129:
	.byte %01000010, $C2, %11110000, $D9, %11111111
frame4130:
	.byte %01000010, $C9, %11111111, $D8, %00001100
frame4131:
	.byte %01000011, $D8, %00000000, $E3, %00110000, $ED, %11110011
frame4132:
	.byte %01000011, $C1, %11000000, $CB, %11110011, $D3, %00110011
frame4133:
	.byte %01000100, $CB, %00110000, $D0, %00001100, $E1, %11111111, $EC, %11111100
frame4134:
	.byte %01000011, $C8, %11000000, $EC, %11110000, $ED, %11110000
frame4135:
	.byte %01000011, $EE, %00000000, $F0, %11000000, $F6, %11110011
frame4136:
	.byte %01000001, $F8, %00001100
frame4137:
	.byte %01000011, $C1, %00000000, $EC, %00000000, $ED, %00000000
frame4138:
	.byte %01000001, $EB, %11110011
frame4139:
	.byte %01000101, $D3, %00111111, $F0, %11001100, $F4, %11111100, $F5, %11110011, $F6, %11110000
frame4140:
	.byte %01000110, $E3, %00000000, $E7, %00110000, $E8, %11000000, $F4, %11110000, $F5, %11110000, $F6, %00110000
frame4141:
	.byte %01000100, $C2, %00000000, $D0, %11001100, $E7, %00000000, $E8, %11001100
frame4142:
	.byte %01000110, $C8, %00000000, $CB, %00000000, $E8, %00001100, $F4, %11111111, $F5, %11111111, $F6, %11110000
frame4143:
	.byte %01000101, $C9, %11111100, $E0, %11000000, $EB, %00110011, $EC, %11000000, $F6, %11110011
frame4144:
	.byte %01000101, $DB, %00000011, $E2, %00111111, $EB, %11110011, $EC, %11110000, $ED, %11110000
frame4145:
	.byte $88
frame4146:
	.byte %01000100, $D3, %00110011, $EB, %11111111, $EC, %11111111, $ED, %11110011
frame4147:
	.byte %01000010, $E3, %00000011, $E8, %11001100
frame4148:
	.byte %01000100, $C8, %11000000, $D8, %11000000, $E3, %00000000, $F6, %00110011
frame4149:
	.byte %01000011, $C9, %11111111, $DC, %00000000, $FE, %00000011
frame4150:
	.byte %01000010, $D8, %11001100, $EB, %11110011
frame4151:
	.byte $88
frame4152:
	.byte %01000100, $C2, %00110000, $DB, %00000000, $EB, %11111111, $FE, %00001111
frame4153:
	.byte %01000011, $E0, %11001100, $ED, %11110000, $F8, %00001111
frame4154:
	.byte %01000010, $CA, %11110011, $F0, %11111100
frame4155:
	.byte %01000101, $C8, %11001100, $D0, %11001111, $E2, %00110011, $EB, %11111100, $F0, %11111111
frame4156:
	.byte %01000011, $C8, %11111100, $D0, %11111111, $D3, %00000011
frame4157:
	.byte %01000011, $C1, %11000000, $D8, %11111100, $E8, %11111100
frame4158:
	.byte %01001000, $C1, %11110000, $CA, %00110011, $DA, %00111111, $E8, %11111111, $EB, %11110000, $EC, %11110011, $ED, %00110000, $F6, %00110000
frame4159:
	.byte %01000011, $C2, %00000000, $D8, %11111111, $EC, %11110000
frame4160:
	.byte %01000011, $C8, %11111111, $E0, %11111100, $E2, %00000011
frame4161:
	.byte %01000101, $D3, %00000000, $DA, %00110011, $E0, %11111111, $ED, %00000000, $FE, %00000011
frame4162:
	.byte %01000110, $C0, %11000000, $C1, %11111100, $D4, %11000000, $EB, %00000000, $EC, %00000000, $F5, %11110011
frame4163:
	.byte %01000001, $F6, %00000000
frame4164:
	.byte %01000100, $C1, %11110000, $F3, %11110000, $F4, %11110011, $F5, %11110000
frame4165:
	.byte %01000110, $CA, %00110000, $E1, %00111111, $E2, %00000000, $EA, %11110011, $F4, %11110000, $F5, %00000000
frame4166:
	.byte %01000100, $D2, %00111111, $F3, %00110000, $F4, %00000000, $FE, %00000000
frame4167:
	.byte %01000011, $DA, %00000011, $EA, %00110011, $F3, %00000000
frame4168:
	.byte %01000101, $C1, %00110000, $CA, %00000000, $D4, %00000000, $E2, %00000011, $F4, %11110000
frame4169:
	.byte %01000101, $E1, %11111111, $E2, %00000000, $F3, %11110000, $F5, %11110000, $FE, %00000011
frame4170:
	.byte %01000101, $C0, %00000000, $C1, %00110011, $EA, %00110000, $F3, %11111111, $F4, %11111111
frame4171:
	.byte %01000010, $D2, %00110011, $F5, %11110011
frame4172:
	.byte %01000110, $C1, %00110000, $C9, %11110011, $EB, %11000000, $EC, %11110000, $F5, %11111111, $F6, %00110000
frame4173:
	.byte $88
frame4174:
	.byte %01000011, $D2, %11110011, $D4, %00110000, $E9, %11110011
frame4175:
	.byte %01000110, $D2, %00110011, $EB, %00000000, $EC, %00110000, $F2, %11110011, $F5, %11110011, $F6, %00000000
frame4176:
	.byte %01000011, $C9, %11111111, $D2, %00111111, $EC, %00000000
frame4177:
	.byte %01000001, $C0, %11110000
frame4178:
	.byte %01000001, $E9, %11111111
frame4179:
	.byte %01000001, $D4, %00000000
frame4180:
	.byte %01000010, $DC, %00000011, $F5, %11110000
frame4181:
	.byte %01000010, $C0, %11111100, $E9, %11110011
frame4182:
	.byte %01000101, $D2, %00110011, $DC, %00000000, $F3, %11111100, $F4, %11110011, $F5, %00110000
frame4183:
	.byte %01000011, $F3, %11110000, $F4, %11110000, $FE, %00000000
frame4184:
	.byte %01000001, $F5, %00000000
frame4185:
	.byte %01000011, $F3, %00000000, $F4, %00000000, $FD, %00000011
frame4186:
	.byte %01000010, $C9, %11110011, $FD, %00000000
frame4187:
	.byte %01000100, $C0, %11110000, $F2, %00110011, $FB, %00000000, $FC, %00000000
frame4188:
	.byte %01000001, $C1, %00000000
frame4189:
	.byte %01000011, $C0, %11110011, $C9, %00110011, $EA, %00000000
frame4190:
	.byte %01000011, $D2, %00000011, $DA, %00000000, $E9, %11111111
frame4191:
	.byte %01000010, $E9, %00111111, $FA, %00000011
frame4192:
	.byte %01000011, $C0, %00110011, $C9, %00110000, $E9, %00001111
frame4193:
	.byte %01000001, $C0, %00110000
frame4194:
	.byte %01000010, $E9, %00111111, $F2, %00110000
frame4195:
	.byte %01000010, $C9, %00000000, $F1, %11110011
frame4196:
	.byte %01000101, $C0, %00000000, $D1, %11110011, $D2, %00110011, $E1, %11110011, $F1, %11110000
frame4197:
	.byte %01000100, $C8, %11110011, $D2, %00000000, $E1, %11111111, $E9, %00110011
frame4198:
	.byte %01000011, $E9, %11110011, $F1, %11110011, $F2, %00000000
frame4199:
	.byte %01000101, $D1, %11110000, $E1, %00111111, $E9, %11111111, $F1, %00110011, $FA, %00000000
frame4200:
	.byte %01000010, $E9, %00111111, $F1, %00000011
frame4201:
	.byte %01000010, $E1, %00110011, $E9, %00110011
frame4202:
	.byte %01000010, $C8, %00110011, $F0, %00111111
frame4203:
	.byte %01000010, $D9, %00111111, $F0, %11111111
frame4204:
	.byte %01000011, $C8, %00110000, $E9, %11110011, $F0, %00111111
frame4205:
	.byte %01000010, $E9, %00110011, $F9, %00000011
frame4206:
	.byte %01000101, $D3, %11000000, $D9, %00110011, $F0, %11111111, $F1, %00000000, $F9, %00000000
frame4207:
	.byte %01000010, $E9, %00000011, $F8, %00000011
frame4208:
	.byte %01000011, $D1, %11111100, $E1, %00000011, $F1, %00000011
frame4209:
	.byte %01000011, $D3, %00000000, $E9, %00110011, $F1, %00000000
frame4210:
	.byte %01000001, $E9, %00110000
frame4211:
	.byte %01000010, $D1, %00111100, $F8, %00000000
frame4212:
	.byte %01000100, $D1, %00111111, $E9, %00000000, $F0, %00111111, $F8, %00000011
frame4213:
	.byte %01000010, $F1, %00000011, $F8, %00001111
frame4214:
	.byte %01000011, $C8, %00000000, $F0, %11111111, $F8, %00000011
frame4215:
	.byte %01000010, $D1, %00110011, $F1, %00000000
frame4216:
	.byte %01000010, $E1, %00110000, $F1, %00110000
frame4217:
	.byte %01000101, $DB, %00001100, $E1, %00000011, $F0, %00111111, $F1, %00000000, $F8, %00001111
frame4218:
	.byte %01000100, $D3, %11000000, $E8, %11110011, $F0, %11111111, $F8, %00000011
frame4219:
	.byte %01000010, $D0, %11110011, $E8, %00111111
frame4220:
	.byte %01000011, $D0, %11110000, $F0, %11110011, $F8, %00001111
frame4221:
	.byte %01000100, $D1, %00110000, $E1, %00110011, $E8, %11111111, $F0, %00110011
frame4222:
	.byte %01000010, $D0, %00000000, $E1, %00000011
frame4223:
	.byte %01000011, $D1, %00000000, $D9, %00000011, $F8, %00000011
frame4224:
	.byte %01000101, $D8, %11111100, $D9, %00000000, $DB, %11001100, $E1, %00000000, $E8, %00111111
frame4225:
	.byte %01000010, $D8, %11110000, $F8, %00000000
frame4226:
	.byte %01000100, $D3, %00000000, $E0, %00110011, $E8, %00110011, $F0, %00000011
frame4227:
	.byte %01000010, $D8, %00110000, $F0, %00110000
frame4228:
	.byte %01000100, $D8, %00000000, $E0, %00000000, $E8, %00000000, $F0, %00000000
frame4229:
	.byte %01000001, $DB, %11000000
frame4230:
	.byte $88
frame4231:
	.byte $88
frame4232:
	.byte $88
frame4233:
	.byte $88

.segment "VECTORS"
    .word VBLANK
    .word RESET
    .word 0

.segment "CHARS"
    .incbin "mario.chr"