// Reads a program from the serial-over-USB interface and jumps to it. This
// code is based on serial.c, and it uses the USB registers directly.

#define STAGE2_ADDRESS 0x70006000

.text

.global _start
_start:
    disable_interrupts:
        mrs    r0, cpsr
        mov    r1, #0xc0
        orr    r0, r0, r1
        msr    cpsr_cxsf, r0
    relocate_stack:
        adr    sp, _start-4
    switch_to_thumb:
        adr    r0, thumb_start+1
        bx     r0

.code 16

thumb_start:

usb_init:
        ldr    r7, =0xa0900000   // USB_CTRL_ADDR
        mov    r0, #0x21         // USB_CTRL_CON_NULLPKT_FIX | USB_CTRL_CON_DPPULLUP
        ldr    r1, =0xa0900240   // USB_CTRL_CON
        str    r0, [r1]
        adr    r1, usb_init_data

    usb_init_loop:
        ldrb   r2, [r1]
        add    r1, #1
        lsr    r2, r2, #1
        bcs    usb_init_read
        beq    usb_init_done

    usb_init_write:
        ldrb   r0, [r1]
        add    r1, #1
        strb   r0, [r7,r2]
        b usb_init_loop

    usb_init_read:
        ldrb   r0, [r7,r2]
        b usb_init_loop

.align 2
// This table is used to initialize the USB interface, based on the code from
// serial.c. Format: ((address_relative_to_usb_base << 1) | (is_read ? 1 : 0)).
// Aside from USB_CTRL_EP_INMAXP, all of these seem to be unnecessary, as the
// ROM already uses the same settings.
usb_init_data:
        .byte 0x07               // read USB_CTRL_INTROUT
        .byte 0x05               // read USB_CTRL_INTRIN
        .byte 0x0d               // read USB_CTRL_INTRUSB
        .byte 0x12, 0x00, 0x13   // USB_CTRL_INTROUTE = 0; read USB_CTRL_INTROUTE
        .byte 0x0e, 0x00, 0x0f   // USB_CTRL_INTRINE = 0; read USB_CTRL_INTRINE
        .byte 0x12, 0x02         // USB_CTRL_INTROUTE = _EP1_OUT_ENABLE
        .byte 0x0e, 0x03         // USB_CTRL_INTRINE = _EP0_ENABLE | _EP1_IN_ENABLE
        .byte 0x1c, 0x01         // USB_CTRL_INDEX = 1
        .byte 0x20, 0x01         // USB_CTRL_EP_INMAXP = 1
        .byte 0x22, 0x08         // USB_CTRL_EP_INCSR1 = _FLUSHFIFO
        .byte 0x22, 0x08         // USB_CTRL_EP_INCSR1 = _FLUSHFIFO
        .byte 0x24, 0x00         // USB_CTRL_EP_INCSR2 = 0
        .byte 0x0d               // read USB_CTRL_INTRUSB
        .byte 0x00
.align 2

// registers:
//  r3 - number of bytes left in current USB packet
//  r4 - 0
//  r5 - address of USB data register
//  r6 - address to write data to
//  r7 - address of first USB register (already set)

usb_init_done:
main:
        mov    r3, #0
        mov    r4, #0
        ldr    r5, =0xa0900024   // USB_CTRL_EP1_FIFO_DB0
        ldr    r6, =STAGE2_ADDRESS

        mov    r0, #0x3e         // '>'
        bl     write_byte

        mov    r1, #4
        bl     read_bytes

        ldr    r1, [r6]
        bl     read_bytes
        mov    r0, #0x2e         // '.'
        bl     write_byte
        bx     r6


read_bytes:
        push   {r0, r1, r2, r6, lr}

    read_byte_loop:
        tst    r3, r3
        bne    read_byte

        // wait for a read interrupt
    read_interrupt_wait:
        ldrb   r0, [r7,#0x04]    // USB_CTRL_INTROUT
        tst    r0, r0
        bne    read_interrupt_received
        ldrb   r0, [r7,#0x06]    // USB_CTRL_INTRUSB
        b read_interrupt_wait
    read_interrupt_received:

        // wait for a packet
    read_packet_wait:
        ldrb   r0, [r7,#0x14]    // USB_CTRL_EP_OUTCSR1
        lsr    r0, r0, #1        // _RXPKTRDY
        bcc    read_packet_wait

        // set r3 to number of bytes available
        ldrb   r3, [r7,#0x16]    // USB_CTRL_EP_COUNT1
        ldrb   r2, [r7,#0x17]    // USB_CTRL_EP_COUNT2
        lsl    r2, #30
        lsr    r2, #22
        orr    r3, r2

    read_byte:
        ldrb   r0, [r5]
        strb   r0, [r6]
        add    r6, #1
        sub    r3, #1
        bne    not_done_with_packet
        strb   r4, [r7,#0x14]    // USB_CTRL_EP_OUTCSR1
    not_done_with_packet:
        sub    r1, #1
        bne    read_byte_loop

        pop    {r0, r1, r2, r6, pc}


write_byte:
        push   {r0, lr}

        strb   r0, [r5]
        mov    r0, #0x20
        strb   r0, [r7,#0x12]     // USB_CTRL_EP_INCSR2 = _MODE
        mov    r0, #0x01
        strb   r0, [r7,#0x11]     // USB_CTRL_EP_INCSR1 = _INPKTRDY

    write_byte_wait:
        ldrb   r0, [r7,#0x02]     // USB_CTRL_INTRIN
        tst    r0, r0
        beq    write_byte_wait

        strb   r4, [r7,#0x12]     // USB_CTRL_EP_INCSR2 = 0

        pop    {r0, pc}
