{
    --------------------------------------------
    Filename: display.led.is31fl3741.i2c.spin
    Author:
    Description:
    Copyright (c) 2022
    Started Jan 09, 2022
    Updated Jan 09, 2022
    See end of file for terms of use.
    --------------------------------------------
}
'#define GFX_DIRECT
'#include "lib.gfx.bitmap.spin"

CON

    MAX_COLOR       = 16777215
    BYTESPERPX      = 3

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 100_000
    DEF_ADDR        = 0
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

VAR

    long _page
    long _addr_bits

OBJ

    i2c : "com.i2c"                             ' PASM I2C engine (up to ~800kHz)
    core: "core.con.is31fl3741"                 ' hw-specific low-level const's
    time: "time"                                ' basic timing functions

PUB Null{}
' This is not a top-level object

PUB Start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ, DEF_ADDR)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start using custom IO pins and I2C bus frequency
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ                 ' validate pins and bus freq
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)             ' wait for device startup
            _addr_bits := ADDR_BITS << 1
            if (deviceid{} == core#DEVID_RESP)  ' validate device
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog 
    return FALSE

PUB Stop{}

    i2c.deinit{}

PUB Defaults{}
' Set factory defaults
    reset{}

PUB Box(sx, sy, ex, ey, c, filled) | x, y

    if (sx => 0 and sx =< 12 and sy => 0 and sy =< 8)
        if (filled)
            repeat y from sy to ey
                repeat x from sx to ex
                    plot(x, y, c)
        else
            repeat x from sx to ex
                plot(x, sy, c)
                plot(x, ey, c)
            repeat y from sy+1 to ey-1
                plot(sx, y, c)
                plot(ex, y, c)

PUB Clear{}

    box(0, 0, 12, 8, 0, true)

PUB DeviceID: id
' Read device identification
    id := 0
    readreg(core#ID, 1, @id)

PUB Plot(x, y, c) | r, g, b, offs, rgboffs
' Draw pixel at coordinates (x, y) in color c (RGB888)
    y := lookupz(y: 8, 5, 4, 3, 2, 1, 0, 7, 6)  ' remap row

    if (x < 10)
        offs := (x + (y * 10)) * 3
    else
        offs := (x + (80 + y * 3)) * 3

    if (x & 1) or (x == 12)
        setled(0, offs+2, c.byte[2])
        setled(0, offs, c.byte[1])
        setled(0, offs+1, c.byte[0])
    else
        setled(0, offs, c.byte[2])
        setled(0, offs+1, c.byte[1])
        setled(0, offs+2, c.byte[0])

PUB LEDCurrLim(led_nr, ilim) | i
' Set current limit for individual led led_nr
'   Valid values:
'       led_nr: 0..350
'       ilim: 0..255
    if lookdown(led_nr: 0..350)
        ilim := 0 #> ilim <# 255
        if led_nr < 180
            selectpage(2)
        else
            led_nr -= 180
            selectpage(3)
        repeat i from 0 to 2
            writereg(led_nr+i, 1, @ilim)

PUB MasterCurrLim(i): curr_i
' Set master current limit of LED matrix
'   Valid values: 0..255
    selectpage(4)
    writereg(core#GCC, 1, @i)

PUB Powered(state): curr_state | tmp
' Enable device power
'   Valid values: TRUE (-1 or 1), FALSE (0)
    selectpage(4)
    tmp := core#PWRON
    writereg(core#CONFIG, 1, @tmp)

PUB Reset{}: status | tmp
' Perform soft-reset
'   Returns:
'        0: success
'       -1: device didn't acknowledge
    selectpage(4)
    tmp := core#DO_RESET
    status := writereg(core#RESET, 1, @tmp)
    i2c.stop

PUB readReg(reg_nr, nr_bytes, ptr_buff): status | cmd_pkt

    cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
    cmd_pkt.byte[1] := reg_nr

    i2c.start{}
    status := i2c.wrblock_lsbf(@cmd_pkt, 2)
    if (status == i2c#NAK)
        i2c.stop{}
        return -1
    i2c.stop{}
    i2c.start{}
    i2c.write(SLAVE_RD | _addr_bits)
    i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
    i2c.stop{}

PRI selectPage(pg)
' Set active internal memory page
'   Valid values: 0..4
    if lookdown(pg: 0..4)
        if (pg == _page)                        ' ignore if already on selected
            return                              '   page
        _page := pg
        unlock{}
        writereg(core#COMMAND, 1, @pg)

PRI setLED(pg, led, val)

    if lookdown(led: 0..350)
        if led < 180
            selectpage(pg)
        else
            led -= 180
            selectpage(pg+1)
        writereg(led, 1, @val)

PRI unlock{}
' Unlock access to commands/configuration
'   NOTE: This must be performed before each applicable access
    i2c.start
    i2c.write(SLAVE_WR)
    i2c.write(core#LOCK_STATE)
    i2c.write(core#UNLOCK)
    i2c.stop

PUB writeReg(reg_nr, nr_bytes, ptr_buff): status | cmd_pkt

    cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
    cmd_pkt.byte[1] := reg_nr

    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.wrblock_lsbf(ptr_buff, nr_bytes)
    i2c.stop{}

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
