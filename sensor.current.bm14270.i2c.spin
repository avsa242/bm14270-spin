{
    --------------------------------------------
    Filename: sensor.current.bm14270.i2c.spin
    Author: Jesse Burt
    Description: Driver for the Rohm Semiconductor BM14270 current sensor
    Copyright (c) 2020
    Started Feb 15, 2020
    Updated Dec 29, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR            = core#SLAVE_ADDR
    SLAVE_RD            = core#SLAVE_ADDR|1

    DEF_SCL             = 28
    DEF_SDA             = 29
    DEF_HZ              = 400_000
    I2C_MAX_FREQ        = core#I2C_MAX_FREQ

' Operating modes
    CONT                = 0
    SINGLE              = 1

VAR


OBJ

    i2c     : "com.i2c"
    core    : "core.con.bm14270.spin"
    time    : "time"

PUB Null
'This is not a top-level object

PUB Start: okay                                                 'Default to "standard" Propeller I2C pins and 400kHz

    okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx(SCL_PIN, SDA_PIN, I2C_HZ)    'I2C Object Started?
                time.msleep(1)
                if i2c.present(SLAVE_WR)                       'Response from device?
                    return okay
    return FALSE                                                'If we got here, something went wrong

PUB Stop{}
' Put any other housekeeping code here required/recommended by your device before shutting down
    i2c.terminate{}

PUB CurrentData{}
' Read current measurement
'   Returns: ADC word from -8192 to 8191
    readreg(core#DATA, 2, @result)
    ~~result

PUB CurrentDataRate(Hz) | tmp
' Set measurement output data rate, in Hz
'   Valid values: 20, 100, 200, 1000
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readreg(core#CNTL1, 1, @tmp)
    case Hz
        20, 100, 200, 1000:
            Hz := lookdownz(Hz: 20, 100, 200, 1000) << core#ODR
        other:
            tmp := (tmp >> core#ODR) & core#ODR_BITS
            result := lookupz(tmp: 20, 100, 200, 1000)
            return

    tmp &= core#ODR_MASK
    tmp := (tmp | Hz) & core#CNTL1_MASK
    writereg(core#CNTL1, 1, @tmp)

PUB Measure{} | tmp
' Trigger a measurement
    tmp := 1 << core#FORCE
    writereg(core#CNTL3, 1, @tmp)

PUB OpMode(mode) | tmp
' Set operation mode
'   Valid values:
'       CONT (0): Continuous measurement mode
'       SINGLE (1): Single-shot measurement mode
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readreg(core#CNTL1, 1, @tmp)
    case mode
        CONT, SINGLE:
            mode := mode << core#FS1
        other:
            result := (tmp >> core#FS1) & 1
            return

    tmp &= core#FS1_MASK
    tmp := (tmp | mode) & core#CNTL1_MASK
    writereg(core#CNTL1, 1, @tmp)

PUB Powered(enabled) | tmp
' Enable device power
'   Valid values:
'       TRUE (-1 or 1): Power on
'       FALSE (0): Power off
'   Any other value polls the chip and returns the current setting
    tmp := $00
    readreg(core#CNTL1, 1, @tmp)
    case ||enabled
        0, 1:
            enabled := ||enabled << core#PC1
        other:
            return ((tmp >> core#PC1) & 1) == 1

    tmp &= core#PC1_MASK
    tmp := (tmp | enabled) & core#CNTL1_MASK
    writereg(core#CNTL1, 1, @tmp)
    time.msleep(2)

PUB Ready{}
' Flag indicating measured data is ready
'   Returns: TRUE (-1) if measurement ready, FALSE (0) otherwise
    readreg(core#STA1, 1, @result)
    result := ((result >> core#RD_DRDY) & %1) * TRUE

PUB Reset{} | tmp
' Reset the device
    tmp := $00
    readreg(core#CNTL1, 1, @tmp)
    tmp &= core#RST_LV_MASK
    writereg(core#CNTL1, 1, @tmp)

    tmp := $00
    tmp := 1 << core#RSTB_LV
    writereg(core#CNTL4_MSB, 1, @tmp)

PUB Teslas{}
' Reads the current output register and scales the output to nanoTeslas
    result := currentdata{} * 45

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Read nr_bytes from slave device into ptr_buff
    case reg_nr
        core#STA1, core#DATA, core#CNTL1, core#CNTL2, core#CNTL3:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wr_block(@cmd_pkt, 2)
            i2c.start{}
            i2c.write(SLAVE_RD)
            i2c.rd_block(ptr_buff, nr_bytes, TRUE)
            i2c.stop{}
        other:
            return

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt, tmp
' Write nr_bytes from ptr_buff to slave device
    case reg_nr
        core#CNTL1, core#CNTL2, core#CNTL3, core#CNTL4_MSB:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wr_block(@cmd_pkt, 2)
            repeat tmp from 0 to nr_bytes-1
                i2c.write(byte[ptr_buff][tmp])
            i2c.stop{}
        other:
            return


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
