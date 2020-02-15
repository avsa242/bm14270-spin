{
    --------------------------------------------
    Filename: core.con.bm14270.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2020
    Started Feb 15, 2020
    Updated Feb 15, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

    I2C_MAX_FREQ      = 400_000
    SLAVE_ADDR        = $0E << 1

' Register definitions
    STA1                = $0F
    STA1_MASK           = $80
        FLD_RD_DRDY     = 0     'Datasheet lists this as bit 7, but bit 0 is the only one that seems to change

    DATA                = $10
    DATA_LSB            = $10
    DATA_MSB            = $11

    CNTL1               = $1B
    CNTL1_MASK          = $BA
        FLD_PC1         = 7
        FLD_RST_LV      = 5
        FLD_ODR         = 3
        FLD_FS1         = 1
        BITS_ODR        = %11
        MASK_PC1        = CNTL1_MASK ^ (1 << FLD_PC1)
        MASK_RST_LV     = CNTL1_MASK ^ (1 << FLD_RST_LV)
        MASK_ODR        = CNTL1_MASK ^ (BITS_ODR << FLD_ODR)
        MASK_FS1        = CNTL1_MASK ^ (1 << FLD_FS1)

    CNTL2               = $1C
    CNTL2_MASK          = $08
        FLD_ALERT_EN    = 3

    CNTL3               = $1D
    CNTL3_MASK          = $40
        FLD_FORCE       = 6

    CNTL4               = $5C
    CNTL4_LSB           = $5C
    CNTL4_MSB           = $5D
        FLD_RSTB_LV     = 8
PUB Null
' This is not a top-level object
