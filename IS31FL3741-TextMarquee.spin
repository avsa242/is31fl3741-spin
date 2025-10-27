{
----------------------------------------------------------------------------------------------------
    Filename:       IS31FL3741-TextMarquee.spin
    Description:    Demo of the IS31FL3741 driver
    Author:         Jesse Burt
    Started:        Oct 27, 2025
    Updated:        Oct 27, 2025
    Copyright (c) 2025 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

con

    _clkmode = xtal1+pll16x
    _xinfreq = 5_000_000


' enable pixel-level positioning for text in the graphics driver
#define FNT_POS_NOGRID
#pragma exportdef(FNT_POS_NOGRID)

obj

    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    led:    "display.led.is31fl3741" | SCL=28, SDA=29, I2C_FREQ=1_000_000, I2C_ADDR=1, ...
                                        WIDTH=13, HEIGHT=9
    fnt:    "font.5x8"
    time:   "time"


dat

    ' text to scroll in the marquee display
    tstr    byte "This is a test", 0


pub main() | x, xmin

    setup()

    led.pos_xy(0, 0)
    led.bgcolor($00_00_00)
    led.fgcolor($ff_ff_ff)
    x := 13

    ' precalculate the minimum (off-screen) X-position for text:
    '   length of the string * the font's pixel width, plus one screen width
    xmin := -( (strsize(@tstr) * fnt.width) + led.WIDTH )

    repeat
        led.clear()
        led.pos_xy(x, 0)                        ' position the cursor at the rightmost column
        led.puts(@tstr)                         ' draw the string
        led.show()
        x--                                     ' set next cursor position to the left
        if ( x < xmin )                         ' start over if the entire string has scrolled
            x := 13                             '   off-screen
        time.msleep(20)


pub setup() | i

    ser.start()
    time.msleep(30)
    ser.clear()

    if ( led.start() )
        led.set_font(fnt.ptr(), fnt.setup() )
        led.set_putchar(@led.putchar_adafruit_qt)
        ser.strln(@"IS31FL3741 driver started")
    else
        ser.strln(@"IS31FL3741 driver failed to start - halting")
        repeat

    led.reset()
    led.powered(true)
    led.brightness(16)

    repeat i from 0 to 350
        led.set_led_current_limit(i, 16)


dat
{
Copyright 2025 Jesse Burt

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

