{
    --------------------------------------------
    Filename: sensor.current.bm14270.spin
    Author: Jesse Burt
    Description: Driver for the Rohm Semiconductor BM14270 current sensor
    Copyright (c) 2022
    Started Feb 15, 2020
    Updated Sep 24, 2022
    See end of file for terms of use.
    --------------------------------------------
}
#include "sensor.power.common.spinh"
CON

    SLAVE_WR    = core#SLAVE_ADDR
    SLAVE_RD    = core#SLAVE_ADDR|1

    DEF_SCL     = 28
    DEF_SDA     = 29
    DEF_HZ      = 100_000
    DEF_ADDR    = 0
    I2C_MAX_FREQ= core#I2C_MAX_FREQ

    { Operating modes }
    CONT        = 0
    SINGLE      = 1

    { interrupts }
    DRDY        = core#DRDY
VAR

    byte _addr_bits

OBJ

    i2c     : "com.i2c"
    core    : "core.con.bm14270.spin"
    time    : "time"

PUB null{}
' This is not a top-level object

PUB start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ, DEF_ADDR)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start using custom settings
    ' validate I/O pins, bus speed and I2C address option bits
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.msleep(1)
            _addr_bits := (ADDR_BITS << 1)
            if i2c.present(SLAVE_WR | _addr_bits)
                return status
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop{}
' Stop the driver
    i2c.deinit{}
    _addr_bits := 0

PUB defaults{}
' Factory default settings

PUB preset_active{}
' Like Defaults(), but sensor powered on
'    powered(TRUE)
    reset{}
    powered(TRUE)
    opmode(CONT)
    data_rate(20)

PUB adc2amps(adc_word): a
' Convert ADC word to current in (micro)amperes
    return (adc_word * 0_008000)

PUB adc2volts(adc_word)
' dummy method

PUB adc2watts(adc_word)
' dummy method

PUB current_data{}: adc_word
' Read current measurement
'   Returns: ADC word from -8192 to 8191
    adc_word := 0
    readreg(core#DATA, 2, @adc_word)
    ~~adc_word

PUB data_rate(rate): curr_rate
' Set measurement output data rate, in Hz
'   Valid values: 20, 100, 200, 1000
'   Any other value polls the chip and returns the current setting
    curr_rate := 0
    readreg(core#CNTL1, 1, @curr_rate)
    case rate
        20, 100, 200, 1000:
            rate := lookdownz(rate: 20, 100, 200, 1000) << core#ODR
        other:
            curr_rate := (curr_rate >> core#ODR) & core#ODR_BITS
            return lookupz(curr_rate: 20, 100, 200, 1000)

    rate := ((curr_rate & core#ODR_MASK) | rate)
    writereg(core#CNTL1, 1, @curr_rate)

PUB data_rdy{}: flag
' Flag indicating measured data is ready
'   Returns: TRUE (-1) if measurement ready, FALSE (0) otherwise
    flag := 0
    readreg(core#STA1, 1, @flag)
    return (((flag >> core#RD_DRDY) & 1) == 1)

PUB int_mask(mask): curr_mask
' Set interrupt mask
'   Valid values:
'       Bits:
'       3: data ready
    if (mask == core#DRDY)
        writereg(core#CNTL2, 1, @mask)
    else
        curr_mask := 0
        readreg(core#CNTL2, 1, @curr_mask)

PUB measure{} | tmp
' Trigger a measurement
    tmp := 1 << core#FORCE
    writereg(core#CNTL3, 1, @tmp)

PUB opmode(mode): curr_mode
' Set operation mode
'   Valid values:
'       CONT (0): Continuous measurement mode
'       SINGLE (1): Single-shot measurement mode
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#CNTL1, 1, @curr_mode)
    case mode
        CONT, SINGLE:
            mode := mode << core#FS1
        other:
            return (curr_mode >> core#FS1) & 1

    mode := ((curr_mode & core#FS1_MASK) | mode)
    writereg(core#CNTL1, 1, @mode)

PUB power_data{}: p
' dummy method

PUB powered(state): curr_state
' Enable device power
'   Valid values:
'       TRUE (-1 or 1): Power on
'       FALSE (0): Power off
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#CNTL1, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#PC1
        other:
            return ((curr_state >> core#PC1) & 1) == 1

    state := ((curr_state & core#PC1_MASK) | state)
    writereg(core#CNTL1, 1, @state)
    time.msleep(2)

PUB reset{} | tmp
' Reset the device
    tmp := 0
    readreg(core#CNTL1, 1, @tmp)
    tmp &= core#RST_LV_MASK
    writereg(core#CNTL1, 1, @tmp)

    tmp := (1 << core#RSTB_LV)
    writereg(core#CNTL4_MSB, 1, @tmp)

PUB teslas{}: t
' Reads the current output register and scales the output to nanoTeslas
    return current_data{} * 45

PUB voltage_data{}: v
' dummy method

PRI readreg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Read nr_bytes from slave device into ptr_buff
    case reg_nr
        core#STA1, core#DATA, core#CNTL1, core#CNTL2, core#CNTL3:
            cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.stop{}
            i2c.start{}
            i2c.write(SLAVE_RD | _addr_bits)
            i2c.rdblock_lsbf(ptr_buff, nr_bytes, TRUE)
            i2c.stop{}
        other:
            return

PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Write nr_bytes from ptr_buff to slave device
    case reg_nr
        core#CNTL1, core#CNTL2, core#CNTL3, core#CNTL4_MSB:
            cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            repeat tmp from 0 to nr_bytes-1
                i2c.write(byte[ptr_buff][tmp])
            i2c.stop{}
        other:
            return


DAT
{
Copyright 2022 Jesse Burt

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

