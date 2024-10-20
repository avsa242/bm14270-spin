{
----------------------------------------------------------------------------------------------------
    Filename:       BM14270-Demo.spin
    Description:    Demo of the BM14270 driver
    Author:         Jesse Burt
    Started:        Feb 15, 2020
    Updated:        Oct 19, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000

    SCALE       = 1_000_000


OBJ

    time:   "time"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    sensor: "sensor.current.bm14270" | SCL=28, SDA=29, I2C_FREQ=100_000, I2C_ADDR=0


PUB main() | val

    setup()
    sensor.preset_single()                      ' single-shot measurement mode
    sensor.int_mask(sensor.DRDY)                ' trigger interrupt on data ready

    repeat
        sensor.measure()                        ' trigger a measurement
        repeat                                  ' wait for it to complete
        until sensor.data_rdy()
        val := sensor.current()
        ser.pos_xy(0, 4)
        ser.printf2(@"%d.%06.6d", (val / SCALE), ||(val // SCALE))
        ser.clear_line()


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
        ser.strln(@"BM14270 driver started")
    else
        ser.strln(@"BM14270 driver failed to start - halting")
        repeat


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

