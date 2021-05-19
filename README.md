# EEE2Rover

## Important
  - Code mostly from https://github.com/edstott/EEE2Rover
  - Image processing in DE10_LITE_D8M_VIP_16/ip/EEE_IMGPROC/ includes all image detection code
  - Nios2 software in DE10_LITE_D8M_VIP_16/software/D8M_Camera_Test/

## Files needed to use camera
- .sof file in DE10_LITE_D8M_VIP_16/output_files to be used in Programmer in Quartus
- .elf file in DE10_LITE_D8M_VIP_16/software/D8M_Camera_Test/ to program the Nios2 with "nios2-download D8M_Camera_Test.elf -c 1 -g"



## Contents of this repository
  Directory | Contents
  --------- | --------
  doc/      | Documents
  DE10_LITE_D8M_VIP_16/ | FPGA starter project including Nios II firmware

## Getting started

  [Building the FPGA starter project](doc/FPGA-installation.md)
  
  [Starter project documentation](doc/FPGA-system.md)
  
