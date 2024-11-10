{
----------------------------------------------------------------------------------------------------
    Filename:       IS31FL3741-Demo.spin
    Description:    Demo of the IS31FL3741 driver
    Author:         Jesse Burt
    Started:        Jan 9, 2022
    Updated:        Nov 9, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    _clkmode = xtal1+pll16x
    _xinfreq = 5_000_000


OBJ

    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    led:    "display.led.is31fl3741.spin" | SCL=28, SDA=29, I2C_FREQ=400_000, I2C_ADDR=0
    time:   "time"


pub main() | i, c, x, y

    setup()
    led.brightness(64)
'    led.powered(true)

    repeat i from 0 to 350
        led.set_led_current_limit(i, 16)

    repeat
        repeat i from 0 to 7
            c := lookupz(i: $ff_00_00, $00_ff_00, $00_00_ff, $00_ff_ff, $ff_00_ff, $ff_ff_00, ...
                            $ff_ff_ff, $00_00_00)
            led.clear()
            repeat y from 0 to 8
                repeat x from 0 to 12
                    led.plot(x, y, c)
            led.show()
            time.msleep(250)


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()

    if ( led.start() )
        ser.strln(@"IS31FL3741 driver started")
    else
        ser.strln(@"IS31FL3741 driver failed to start - halting")
        repeat

    led.reset()
    led.powered(true)


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

