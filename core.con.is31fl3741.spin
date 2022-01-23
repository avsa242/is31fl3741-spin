{
    --------------------------------------------
    Filename: core.con.is31fl3741.spin
    Author: Jesse Burt
    Description: IS31FL3741-specific constants
    Copyright (c) 2022
    Started Jan 09, 2022
    Updated Jan 23, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

' I2C Configuration
    I2C_MAX_FREQ    = 1_000_000                 ' device max I2C bus freq
    SLAVE_ADDR      = $30 << 1                  ' 7-bit format slave address
    T_POR           = 1000                      ' startup time (usecs)

    DEVID_RESP      = $60                       ' device ID expected response

' Register definitions
    CONFIG          = $00
    CONFIG_MASK     = $FF
        SWS         = 4
        LGC         = 3
        OSDE        = 1
        SSD         = 0
        SWS_BITS    = %1111
        OSDE_BITS   = %11
        SWS_MASK    = (SWS_BITS << SWS) ^ CONFIG_MASK
        LGC_MASK    = (1 << LGC) ^ CONFIG_MASK
        OSDE_MASK   = (OSDE_BITS << OSDE) ^ CONFIG_MASK
        SSD_MASK    = 1 ^ CONFIG_MASK
        PWRON       = (1 << SSD)
        LGCLVL_HI   = (1 << LGC)

    GCC             = $01

    RESET           = $3F
        DO_RESET    = $AE

    ID              = $FC
    COMMAND         = $FD
    LOCK_STATE      = $FE
        UNLOCK      = $C5

PUB Null{}
' This is not a top-level object

