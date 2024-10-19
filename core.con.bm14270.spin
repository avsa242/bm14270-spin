{
----------------------------------------------------------------------------------------------------
    Filename:       core.con.bm14270.spin
    Description:    BM14270-specific constants
    Author:         Jesse Burt
    Started:        Feb 15, 2020
    Updated:        Oct 19, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    I2C_MAX_FREQ    = 400_000
    SLAVE_ADDR      = $0E << 1

' Register definitions
    STA1            = $0F
    STA1_MASK       = $80
        RD_DRDY     = 0     ' Datasheet lists this as bit 7, but bit 0 is the only one that
                            '   seems to change

    DATA            = $10
    DATA_LSB        = $10
    DATA_MSB        = $11

    CNTL1           = $1B
    CNTL1_MASK      = $BA
        PC1         = 7
        RST_LV      = 5
        ODR         = 3
        FS1         = 1
        ODR_BITS    = %11
        PC1_MASK    = (1 << PC1) ^ CNTL1_MASK
        RST_LV_MASK = (1 << RST_LV) ^ CNTL1_MASK
        ODR_MASK    = (ODR_BITS << ODR) ^ CNTL1_MASK
        FS1_MASK    = (1 << FS1) ^ CNTL1_MASK

    CNTL2           = $1C
    CNTL2_MASK      = $08
        ALERT_EN    = 3
        DRDY        = (1 << ALERT_EN)

    CNTL3           = $1D
    CNTL3_MASK      = $40
        FORCE       = 6

    CNTL4           = $5C
    CNTL4_LSB       = $5C
    CNTL4_MSB       = $5D
        RSTB_LV     = 8


PUB null()
' This is not a top-level object


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

