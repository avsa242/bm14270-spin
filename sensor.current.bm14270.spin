{
----------------------------------------------------------------------------------------------------
    Filename:       sensor.current.bm14270.spin
    Description:    Driver for the Rohm Semiconductor BM14270 current sensor
    Author:         Jesse Burt
    Started:        Feb 15, 2020
    Updated:        Oct 19, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    {  default I/O settings; these can be overridden in the parent object }
    SCL         = 28
    SDA         = 29
    I2C_FREQ    = 100_000
    I2C_ADDR    = 0


    SLAVE_WR    = core.SLAVE_ADDR
    SLAVE_RD    = core.SLAVE_ADDR|1
    I2C_MAX_FREQ= core.I2C_MAX_FREQ

    ' Operating modes
    CONT        = 0
    SINGLE      = 1

    ' interrupts
    DRDY        = core.DRDY


VAR

    byte _addr_bits


OBJ

    i2c:    "com.i2c"                           ' I2C engine
    core:   "core.con.bm14270.spin"             ' HW-specific constants
    time:   "time"                              ' timekeeping methods


PUB null()
' This is not a top-level object


PUB start(): status
' Start using default I/O settings
    return startx(SCL, SDA, I2C_FREQ, I2C_ADDR)


PUB startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start the driver with custom I/O settings
'   SCL_PIN:    I2C clock, 0..31
'   SDA_PIN:    I2C data, 0..31
'   I2C_HZ:     I2C clock speed (max official specification is 400_000 but is unenforced)
'   ADDR_BITS:  I2C alternate address bit, 0..1
'   Returns:
'       cog ID+1 of I2C engine on success (= calling cog ID+1, if the bytecode I2C engine is used)
'       0 on failure
    if ( lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) )
        if ( status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ) )
            time.msleep(1)
            _addr_bits := (ADDR_BITS << 1)
            if ( i2c.present(SLAVE_WR | _addr_bits) )
                return status
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE


PUB stop()
' Stop the driver
    i2c.deinit()
    _addr_bits := 0


PUB defaults()
' Factory default settings


PUB preset_continuous()
' Preset:
'   * sensor active/powered on
'   * continuous measurements
'   * 20Hz output data rate
    reset()
    powered(TRUE)
    opmode(CONT)
    data_rate(20)


PUB preset_single()
' Preset:
'   * sensor active/powered on
'   * single-shot measurements (trigger using measure() )
'   * 20Hz output data rate
    reset()
    powered(TRUE)
    opmode(SINGLE)
    data_rate(20)


#include "sensor.power.common.spinh"            ' use code common to all power sensing drivers


PUB adc2amps(adc_word): a
' Convert ADC word to current in (micro)amperes
    return (adc_word * 0_008000)


PUB adc2volts(adc_word)
' dummy method


PUB adc2watts(adc_word)
' dummy method


PUB current_data(): d
' Read current measurement
'   Returns: ADC word from -8192 to 8191
    d := 0
    readreg(core.DATA, 2, @d)
    ~~d


PUB data_rate(rate=-2): c
' Set measurement output data rate, in Hz
'   Valid values: 20, 100, 200, 1000
'   Any other value polls the chip and returns the current setting
    c := 0
    readreg(core.CNTL1, 1, @c)
    case rate
        20, 100, 200, 1000:
            rate := lookdownz(rate: 20, 100, 200, 1000) << core.ODR
            rate := ((c & core.ODR_MASK) | rate)
            writereg(core.CNTL1, 1, @c)
        other:
            c := (c >> core.ODR) & core.ODR_BITS
            return lookupz(c: 20, 100, 200, 1000)


PUB data_rdy(): f
' Flag indicating measured data is ready
'   Returns: TRUE (-1) if measurement ready, FALSE (0) otherwise
    f := 0
    readreg(core.STA1, 1, @f)
    return ( ( (f >> core.RD_DRDY) & 1) == 1)


PUB int_mask(mask=-2): c
' Set interrupt mask
'   Valid values:
'       Bits:
'       3: data ready
    if ( mask == core.DRDY )
        writereg(core.CNTL2, 1, @mask)
    else
        c := 0
        readreg(core.CNTL2, 1, @c)


PUB measure() | tmp
' Trigger a measurement
    tmp := 1 << core.FORCE
    writereg(core.CNTL3, 1, @tmp)


PUB opmode(mode=-2): c
' Set operation mode
'   Valid values:
'       CONT (0): Continuous measurement mode
'       SINGLE (1): Single-shot measurement mode
'   Any other value polls the chip and returns the current setting
    c := 0
    readreg(core.CNTL1, 1, @c)
    case mode
        CONT, SINGLE:
            mode := mode << core.FS1
            mode := ((c & core.FS1_MASK) | mode)
            writereg(core.CNTL1, 1, @mode)
        other:
            return (c >> core.FS1) & 1


PUB power_data(): p
' dummy method


PUB powered(state=-2): c
' Enable device power
'   Valid values:
'       TRUE (-1 or 1): Power on
'       FALSE (0): Power off
'   Any other value polls the chip and returns the current setting
    c := 0
    readreg(core.CNTL1, 1, @c)
    case ||(state)
        0, 1:
            state := ||(state) << core.PC1
            state := ((c & core.PC1_MASK) | state)
            writereg(core.CNTL1, 1, @state)
            time.msleep(2)
        other:
            return ( ( (c >> core.PC1) & 1) == 1)


PUB reset() | tmp
' Reset the device
    tmp := 0
    readreg(core.CNTL1, 1, @tmp)
    tmp &= core.RST_LV_MASK
    writereg(core.CNTL1, 1, @tmp)

    tmp := (1 << core.RSTB_LV)
    writereg(core.CNTL4_MSB, 1, @tmp)


PUB teslas(): t
' Reads the current output register and scales the output to nanoTeslas
    return ( current_data() * 45 )


PUB voltage_data(): v
' dummy method


PRI readreg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from slave device into ptr_buff
    case reg_nr
        core.STA1, core.DATA, core.CNTL1, core.CNTL2, core.CNTL3:
            cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
            cmd_pkt.byte[1] := reg_nr
            i2c.start()
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.stop()
            i2c.start()
            i2c.write(SLAVE_RD | _addr_bits)
            i2c.rdblock_lsbf(ptr_buff, nr_bytes, TRUE)
            i2c.stop()
        other:
            return


PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Write nr_bytes from ptr_buff to slave device
    case reg_nr
        core.CNTL1, core.CNTL2, core.CNTL3, core.CNTL4_MSB:
            cmd_pkt.byte[0] := (SLAVE_WR | _addr_bits)
            cmd_pkt.byte[1] := reg_nr
            i2c.start()
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            repeat tmp from 0 to nr_bytes-1
                i2c.write(byte[ptr_buff][tmp])
            i2c.stop()
        other:
            return


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

