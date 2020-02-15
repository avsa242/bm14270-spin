# bm14270-spin 
--------------

This is a P8X32A/Propeller driver object for the Rohm Semiconductor BM14270 magnetic current sensor.

## Salient Features

* I2C connection at up to 400kHz
* Read current measurement
* Single-shot or continuous measurement operating modes
* Set measurement data rate

## Requirements

* 1 extra core/cog for the PASM I2C driver

## Compiler Compatibility

* OpenSpin (tested with 1.00.81)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* Doesn't support alerts/interrupts
* No scaled measurement (i.e., amperes) yet

## TODO

- [ ] Implement scaled measurements
- [ ] Implement support for alerts/interrupts
