**RO-PUF: Ring Oscillator-Based Physical Unclonable Function**

RO-PUF is a ring oscillator-based Physical Unclonable Function (PUF) implemented in VHDL. It is designed to be integrated into a Cyclone V SoC and made accessible from the Cortex-A9 cores. The project involves manual placement to ensure that oscillator frequencies primarily depend on process variations.

Features

Design Components

Ring Oscillators: Generate unique frequency variations due to process differences.

Control Unit: Forwards challenges (selects ring oscillators) to the unclonable function.

Response Storage: Stores the responses from the PUF for later retrieval.

SoC Accessibility: Makes the PUF results available to the rest of the system.

Functionality

Provides all challenges to the PUF.

Selects a counter from each oscillator group.

Compares results and shifts data into a shift register.

Connecting the PUF to Cortex-A9

1. Preparing the Memory-Mapped Interface

The PUF is connected to the Cortex-A9 cores via a memory-mapped interface, enabling efficient access to its responses.

2. Packaging the IP Core

The RO-PUF is packaged as an IP core for easy integration into the FPGA design.

3. Instances and Interconnects

Proper instantiation and interconnection ensure seamless communication between the PUF and other components in the SoC.

4. Toplevel Entity Creation

The top-level entity encapsulates all necessary components and defines the overall structure of the PUF system.

5. Readying the Bitstream

The final step involves generating the FPGA bitstream, ensuring that all components are correctly placed and configured.

Implementation

Language: Implemented in VHDL.

Platform: Designed for Cyclone V SoC.

Integration: Accessible via the Cortex-A9 processor through a memory-mapped interface.

Manual Placement: Used to enhance the uniqueness of frequency variations.

Results:\
![image](https://github.com/user-attachments/assets/b3c254a9-1f28-4cca-8de1-7930c670eeaa)
