{
    --------------------------------------------
    Filename: core.con.bm14270.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2020
    Started Feb 15, 2020
    Updated Dec 29, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    I2C_MAX_FREQ      = 400_000
    SLAVE_ADDR        = $0E << 1

' Register definitions
    STA1                = $0F
    STA1_MASK           = $80
        RD_DRDY         = 0     'Datasheet lists this as bit 7, but bit 0 is the only one that seems to change

    DATA                = $10
    DATA_LSB            = $10
    DATA_MSB            = $11

    CNTL1               = $1B
    CNTL1_MASK          = $BA
        PC1             = 7
        RST_LV          = 5
        ODR             = 3
        FS1             = 1
        ODR_BITS        = %11
        PC1_MASK        = (1 << PC1) ^ CNTL1_MASK
        RST_LV_MASK     = (1 << RST_LV) ^ CNTL1_MASK
        ODR_MASK        = (ODR_BITS << ODR) ^ CNTL1_MASK
        FS1_MASK        = 1 ^ CNTL1_MASK

    CNTL2               = $1C
    CNTL2_MASK          = $08
        ALERT_EN        = 3

    CNTL3               = $1D
    CNTL3_MASK          = $40
        FORCE           = 6

    CNTL4               = $5C
    CNTL4_LSB           = $5C
    CNTL4_MSB           = $5D
        RSTB_LV         = 8

PUB Null
' This is not a top-level object
