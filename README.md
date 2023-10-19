# AXIS 1553 DECODER
### MIL-STD-1553 TO AXIS data, and user outputs.
---

   author: Jay Convertino   
   
   date: 2021.05.24  
   
   details: Convert MIL-STD-1553 data into a AXI stream of data of 16 data bits and 8 tuser information bits.  
   
   license: MIT   
   
---

### Version
#### Current
  - V1.0.0 - initial release

#### Previous
  - none

### Dependencies
#### Build

  - AFRL:utility:helper:1.0.0
  
#### Simulation

  - AFRL:simulation:axis_stimulator
  
### IP USAGE
#### INSTRUCTIONS

TDATA will contain the 16 bit data payload. TUSER is a 8 bit status register   
that tells what type of data it is (command or data) and if the parity was   
good (1 good, 0 bad).   

* TUSER = {TYY,NA,D,I,P} (7 downto 0)
  * TYY = TYPE OF DATA
    * 000 N/A (SHOULD NEVER HAPPEN)
    * 001 REG (NOT IMPLIMENTED)
    * 010 DATA
    * 100 CMD/STATUS
  * NA = RESERVED FOR FUTURE USE.
  * D = DELAY BEFORE DATA
    * 1 = Delay of 4us or more before data
    * 0 = No delay between data
  * I = INVERT DATA
  * P = PARITY
    * 1 = GOOD
    * 0 = BAD

#### PARAMETERS

* CLOCK_SPEED : DEFAULT = 20000000 : clock speed of aclk to the core in hz. (needs to be 10x of the sample rate)
* SAMPLE_RATE : DEFAULT = 2000000 : sample rate of generated signal in hz (minimum 2 MHz, must be an even number, must also divide into the clock evenly).
* BIT_SLICE_OFFSET : DEFAULT = 0 : after data caputre, offset bit to use from capture (only works with higher sample rates, positive only).
* INVERT_DATA : DEFAULT = 0 : Invert data, default 0 no inversion. 1 or above is inverted data.
* SAMPLE_SELECT : DEFAULT = 0 : When sampling at a the clockrate, during the skip, which sample should be take. (clock_speed/sample_rate = number of samples to select from by default).

### COMPONENTS
#### SRC

* axis_1553_decoder.v
  
#### TB

* tb_1553_dec.v
  
### fusesoc

* fusesoc_info.core created.
* Simulation uses icarus to run data through the core and write it to a file.
  * timed only, no verification.

#### TARGETS

* RUN WITH: (fusesoc run --target=sim VENDER:CORE:NAME:VERSION)
  - default (for IP integration builds)
  - sim
