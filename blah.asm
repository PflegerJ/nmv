 stx $2000
    stx $2001
    stx $4010

  ;  lda #%10010000
 ;   sta $2000    
 ;   lda #%00011110
  ;  sta $2001

    jsr vblankwait

    txa 
clearmem:
    STA $0000,X
    STA $0100,X
    STA $0300,X
    STA $0400,X
    STA $0500,X
    STA $0600,X
    STA $0700,X
    LDA #$fe
    STA $0200,X
    LDA #$00
    INX 
    BNE clearmem 

    jsr vblankwait 

    lda $02     ; high byte for sprite mem
    sta $4014
    nop 

    lda #$20
    sta tempHi
    lda #$00
    sta tempLo
    sta PPU_BufferOffset

clearnametables:
   

Main:
    lda flag1
    beq hi
    lda <(TestData01)
    sta pointerLo
    lda >(TestData01)
    sta pointerHi
    jsr WriteToPPUBuffer
    lda #$00
    sta flag1 
hi:
    lda #$01
    sta temp1
    jmp Main

    VBLANK:
    lda #$01
    sta flag1
    jsr WriteBufferToPPU
    lda #$00
    sta PPU_BufferOffset
    rti 


