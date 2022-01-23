{
    --------------------------------------------
    Filename: IS31FL3741-SPIN-Demo.spin
    Author: Jesse Burt
    Description: Demo of the IS31FL3741 driver
    Copyright (c) 2022
    Started Jan 09, 2022
    Updated Jan 23, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-defined constants
    SER_BAUD    = 115_200
    LED1        = cfg#LED1

    I2C_SCL     = 28
    I2C_SDA     = 29
    I2C_HZ      = 1_000_000                     ' max is 1_000_000
    ADDR_BITS   = 0                             ' %00..%11
' --

    WIDTH       = 13
    HEIGHT      = 9
    XMAX        = WIDTH-1
    YMAX        = HEIGHT-1

OBJ

    cfg : "core.con.boardcfg.flip"
    ser : "com.serial.terminal.ansi"
    time: "time"
    led : "display.led.is31fl3741.i2c"
    math: "math.int"

PUB Main{} | l

    setup{}

    led.mastercurrlim(64)
    led.powered(true)

    repeat l from 0 to 350
        led.ledcurrlim(l, 255)

    led.clear{}
    led.box(0, 0, XMAX, YMAX, $3f_3f_00, 0)
    led.box(1, 1, XMAX-1, YMAX-1, $2f_2f_00, 0)
    led.box(2, 2, XMAX-2, YMAX-2, $1f_1f_00, 0)
    led.box(3, 3, XMAX-3, YMAX-3, $0f_0f_00, 0)
    repeat

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

    if led.startx(I2C_SCL, I2C_SDA, I2C_HZ, ADDR_BITS)
        ser.strln(string("IS31FL3741 driver started"))
    else
        ser.strln(string("IS31FL3741 driver failed to start - halting"))
        repeat

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
