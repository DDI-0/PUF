Introduction

This project focuses on designing a Ring Oscillator-based Physical Unclonable Function (RO-PUF) using VHDL and integrating it into the memory map of a Cyclone V SoC.\
The RO-PUF is accessible from the Cortex-A9 cores and requires manual placement to ensure oscillator frequencies depend on process variations.

Project Components

The design consists of the following key components:\
Ring Oscillators: Built using VHDL with n-1 inverters and a control NAND gate.\
Control Unit: For forwarding challenges to the RO-PUF and managing responses.\
Response Storage: Mechanism to store the unclonable function’s responses.\
SoC Integration: Making results accessible to the rest of the system.\

Below is an image of the integrated Platform Designer (Qsys) where the PUF component is added, the Avalon Memory-Mapped interface is configured, and it is connected to the Cortex-A9 HPS Lightweight AXI Bus. The system is then synthesized in Quartus, generating the necessary HDL files and compiling the project to produce the bitstream (.rbf). This file is transferred to a MicroSD card, along with an Arch Linux system, and configured to load via U-Boot on the DE1-SoC board. Once booted, the FPGA loads the PUF core, enabling interaction through a Linux driver or user-space program for verification and testing.
![image](https://github.com/user-attachments/assets/b3c254a9-1f28-4cca-8de1-7930c670eeaa)
