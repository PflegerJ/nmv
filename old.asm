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
