{
----------------------------------------------------------------------------------------------------
    Filename:       display.led.is31fl3741.i2c.spin
    Description:    Driver for the IS31FL3741 RGB LED matrix driver IC
    Author:         Jesse Burt
    Started:        Jan 9, 2022
    Updated:        Nov 9, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

#define MEMMV_NATIVE bytemove
#include "graphics.common.spinh"

CON

    { default I/O settings; these can be overridden in the parent object }
    { display dimensions }
    WIDTH       = 13
    HEIGHT      = 9
    XMAX        = WIDTH-1
    YMAX        = HEIGHT-1
    CENTERX     = WIDTH/2
    CENTERY     = HEIGHT/2

    { I2C }
    SCL         = 28
    SDA         = 29
    I2C_FREQ    = 100_000
    I2C_ADDR    = 0                             ' 0..3


    BPP         = 24                            ' bits per pixel/color depth of the display
    BYTESPERPX  = 1 #> (BPP/8)                  ' limit to minimum of 1
    BPPDIV      = BYTESPERPX #> (8 / BPP)       ' limit to range BYTESPERPX .. (8/BPP)
    BUFF_SZ     = (WIDTH * HEIGHT) / BPPDIV
    MAX_COLOR   = (1 << BPP)-1


    SLAVE_WR    = core.SLAVE_ADDR
    SLAVE_RD    = core.SLAVE_ADDR|1
    I2C_MAX_FREQ= core.I2C_MAX_FREQ


VAR

    long _page
    long _addr_bits
    long _framebuffer[BUFF_SZ]


OBJ

    i2c:    "com.i2c"                           ' I2C engine
    core:   "core.con.is31fl3741"               ' hw-specific constants
    time:   "time"                              ' basic timing functions


PUB null()
' This is not a top-level object


PUB start(): status
' Start using default I/O settings
    return startx(SCL, SDA, I2C_FREQ, I2C_ADDR, WIDTH, HEIGHT, @_framebuffer)


PUB startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS, DISP_WID, DISP_HT, ptr_fb): status
' Start the driver with custom I/O settings
'   SCL_PIN:    I2C clock, 0..31
'   SDA_PIN:    I2C data, 0..31
'   I2C_HZ:     I2C clock speed (max official specification is 1_000_000 but is unenforced)
'   ADDR_BITS:  I2C alternate address bit, 0..3
'   DISP_WID:   display width
'   DISP_HT:    display height
'   Returns:
'       cog ID+1 of I2C engine on success (= calling cog ID+1, if the bytecode I2C engine is used)
'       0 on failure
    if ( lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) )
        if ( status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ) )
            time.usleep(core.T_POR)             ' wait for device startup
            _addr_bits := ADDR_BITS << 1
            set_dims(DISP_WID, DISP_HT)
            set_address(ptr_fb)
            if ( dev_id() == core.DEVID_RESP | _addr_bits )
                ' verify communication with the chip
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog 
    return FALSE


PUB stop()
' Stop the driver
    i2c.deinit()


PUB defaults()
' Set factory defaults
    reset()


PUB brightness(lvl)
' Set brightness of display
'   Valid values: 0..255
    select_page(4)
    writereg(core.GCC, lvl)


PUB clear()
' Clear the display to the background color
#ifdef GFX_DIRECT
    box(0, 0, _disp_xmax, _disp_ymax, _bgcolor, true)
#else
    bytefill(_ptr_drawbuffer, _bgcolor, _buff_sz)
#endif


PUB dev_id(): id
' Read device identification
    id := 0
    readreg(core.ID, 1, @id)


PUB set_led_current_limit(led_nr, ilim): a | i
' Set current limit for individual led led_nr
'   Valid values:
'       led_nr: 0..350
'       ilim: 0..255
    if ( lookdown(led_nr: 0..350) )
        if ( led_nr < 180 )
            select_page(2)
        else
            led_nr -= 180
            select_page(3)
        repeat i from 0 to 2
            a := writereg(led_nr+i, ilim)


PUB plot(x, y, c) | offs, ptr
' Draw pixel at coordinates (x, y) in color c (RGB888)
    if ( (x < 0) or (x > _disp_xmax) or (y < 0) or (y > _disp_ymax) )
        return                                  ' ignore invalid coords

    'xxx the below remapping applies only to the Adafruit board - handle other boards somehow
    y := lookupz(y: 8, 5, 4, 3, 2, 1, 0, 7, 6)  ' remap row

    if ( x < 10 )                               ' find offset in framebuffer
        offs := (x + (y * 10) ) * 3
    else
        offs := (x + (80 + y * 3) ) * 3

    ptr := _ptr_drawbuffer + offs

    if ( (x & 1) or (x == 12) )                 ' remap subpixel/color byte order for these columns
{#ifdef GFX_DIRECT
    ' direct to display
        set_led(0, offs+0, c.byte[1])
        set_led(0, offs+1, c.byte[2])
        set_led(0, offs+2, c.byte[0])
    else
        set_led(0, offs+0, c.byte[0])
        set_led(0, offs+1, c.byte[1])
        set_led(0, offs+2, c.byte[2])
#else}
    ' buffered
        byte[ptr+0] := c.byte[1]
        byte[ptr+1] := c.byte[2]
        byte[ptr+2] := c.byte[0]
    else
        byte[ptr+0] := c.byte[0]
        byte[ptr+1] := c.byte[1]
        byte[ptr+2] := c.byte[2]
'#endif

#ifndef GFX_DIRECT


PUB point(x, y): c | offs
' Get color of pixel at x, y
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax

    y := lookupz(y: 8, 5, 4, 3, 2, 1, 0, 7, 6)  ' remap row

    if (x < 10)
        offs := (x + (y * 10)) * 3
    else
        offs := (x + (80 + y * 3)) * 3

    if (x & 1) or (x == 12)
'        set_led(0, offs+2, c.byte[2])
'        set_led(0, offs, c.byte[1])
'        set_led(0, offs+1, c.byte[0])
'       c.byte[2] := byte[offs+2]
'       c.byte[1] := byte[offs]
'       c.byte[0] := byte[offs+1]
    else

    return byte[_ptr_drawbuffer][offs]
#endif


PUB powered(state): c
' Enable device power
'   Valid values: TRUE (-1 or 1), FALSE (0)
    select_page(4)
    writereg(core.CONFIG, core.PWRON)


PUB reset(): s
' Perform soft-reset
'   Returns:
'        0: success
'       -1: device didn't acknowledge
    select_page(4)
    return writereg(core.RESET, core.DO_RESET)


PUB show() | byte buff[180+1]                   ' display plus one byte for the start address
' Send the display buffer to the display
#ifndef GFX_DIRECT
    select_page(0)                              ' draw to page 0
    buff[0] := $00                              ' set matrix starting address to draw to
    bytemove(@buff+1, _ptr_drawbuffer, 180)     ' copy (approximately) half of the fb locally
    i2c.start()
    i2c.write(SLAVE_WR | _addr_bits)
    i2c.wrblock_lsbf(@buff, 180+1)              ' write the fb to the matrix
    i2c.stop()

    select_page(1)                              ' draw to page 1
    buff[0] := $00
    bytemove(@buff+1, _ptr_drawbuffer+180, 180) ' copy the second half of the fb
    i2c.start()
    i2c.write(SLAVE_WR | _addr_bits)
    i2c.wrblock_lsbf(@buff, 171+1)              '   and write it
    i2c.stop()
#endif


#ifndef GFX_DIRECT
PRI memfill(xs, ys, val, count) | offset, i
' Fill region of display buffer memory
'   xs, ys: Start of region
'   val: Color
'   count: Number of consecutive memory locations to write
'    if (xs < 10)
'        offset := (xs + (ys * 10)) * 3
'    else
'        offset := (xs + (80 + ys * 3)) * 3
'    bytefill(_ptr_drawbuffer + offset, val, count)
    repeat i from xs to xs+count-1
        plot(i, ys, val)
#endif


PRI readreg(reg_nr, nr_bytes, ptr_buff): s | cmd_pkt
' Read reg_nr from device into ptr_buff
    cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
    cmd_pkt.byte[1] := reg_nr

    i2c.start()
    s := i2c.wrblock_lsbf(@cmd_pkt, 2)
    if ( s == i2c.NAK )
        i2c.stop()
        return -1
    i2c.stop()
    i2c.start()
    i2c.write(SLAVE_RD | _addr_bits)
    i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c.NAK)
    i2c.stop()


PRI select_page(pg)
' Set active internal memory page
'   Valid values: 0..4
    if ( (pg => 0) and (pg =< 4) )
        if ( pg == _page )                      ' ignore if already on selected
            return                              '   page
        _page := pg
        unlock()
        writereg(core.COMMAND, pg)


PRI set_led(pg, led, val)
' Set LED color
'   pg:     page number
'   led:    led number
'   val:    value/color to set LED (u8)
    if ( lookdown(led: 0..350) )
        if ( led < 180 )
            select_page(pg)
        else
            led -= 180
            select_page(pg+1)
        writereg(led, val)


PRI unlock()
' Unlock access to commands/configuration
'   NOTE: This must be performed before each applicable access
    i2c.start
    i2c.write(SLAVE_WR | _addr_bits)
    i2c.write(core.LOCK_STATE)
    i2c.write(core.UNLOCK)
    i2c.stop


PRI writereg(reg_nr, v, l=1): a | cmd_pkt
' Write value to register
'   reg_nr: register
'   v:      value
'   l:      length/number of bytes to write (optional; default: 1)
    cmd_pkt.byte[0] := SLAVE_WR | _addr_bits
    cmd_pkt.byte[1] := reg_nr

    i2c.start()
    a := i2c.wrblock_lsbf(@cmd_pkt, 2)
    a |= i2c.wrblock_lsbf(@v, l)
    i2c.stop()


DAT
{
Copyright 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

