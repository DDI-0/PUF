Introduction

This project focuses on designing a Ring Oscillator-based Physical Unclonable Function (RO-PUF) using VHDL and integrating it into the memory map of a Cyclone V SoC.\
The RO-PUF is accessible from the Cortex-A9 cores and requires manual placement to ensure oscillator frequencies depend on process variations.

Project Components

The design consists of the following key components:
Ring Oscillators: Built using VHDL with n-1 inverters and a control NAND gate.
Control Unit: For forwarding challenges to the RO-PUF and managing responses.
Response Storage: Mechanism to store the unclonable function’s responses.
SoC Integration: Making results accessible to the rest of the system.

