# FPGA-RISC-V-Processor

A 32-bit RISC-V processor implemented in SystemVerilog on a Digilent Basys 3 FPGA. The project was developed to gain experience designing a processor architecture from individual hardware modules.

The processor uses a multicycle architecture with a finite state machine controlling instruction execution. A host computer communicates with the FPGA over UART to upload RISC-V machine-code instructions into instruction memory.

The implementation includes a program counter, instruction memory, instruction decoder, register file, arithmetic logic unit (ALU), data memory, immediate generator, branch and jump logic, write-back circuitry, and UART communication.

## Project Status

The processor has been synthesized, implemented, and programmed onto a Digilent Basys 3 development board.

UART instruction loading has been tested in simulation, including loading multiple 32-bit instructions into instruction memory and releasing the CPU from reset.

A C++ application was developed to read RISC-V machine-code instructions from a memory file and transmit them to the FPGA.

UART communication currently operates at 115200 baud.

Hardware execution verification is ongoing. Register values and instruction results have not yet been verified on the physical FPGA.

## Getting Started

The project requires a host computer and a Digilent Basys 3 FPGA.

C++ is used to:

- Read RISC-V instructions from `program.mem`
- Store instructions as 32-bit values
- Determine the total instruction count
- Transmit the LOAD command and instruction count
- Send instructions over UART
- Transmit the RUN command to begin CPU execution

The FPGA receives the instructions, stores them in instruction memory, and executes them using the multicycle processor architecture.

## Prerequisites

**Software:**
- AMD Vivado
- Visual Studio Code or another C++ development environment
- GCC/G++ or another Windows-compatible C++ compiler

**Hardware:**
- Digilent Basys 3
- Xilinx Artix-7 FPGA
- USB connection for programming and UART communication

## Installing

Download or clone the repository.

Open the FPGA design in AMD Vivado and generate the bitstream.

Program the Basys 3 using Vivado Hardware Manager.

Connect the FPGA to the host computer and identify its COM port.

Update the COM port in `main.cpp` if necessary.

Place the desired RISC-V machine-code instructions in `program.mem`, with one 32-bit hexadecimal instruction per line.

Compile the C++ uploader:

```bash
g++ main.cpp -o uploader.exe
```

Run the program:

```powershell
.\uploader.exe
```

The C++ application reads the instructions and transmits them to the FPGA over UART.

## How It Works

The processor implements a multicycle RISC-V architecture in which instruction execution is divided into multiple clock cycles.

The control finite state machine coordinates instruction fetching, decoding, execution, memory access, and register write-back.

Instructions are fetched from instruction memory using the program counter.

The instruction decoder extracts register addresses and instruction fields, while the immediate generator produces immediate operands.

The ALU performs arithmetic and logical operations. Branch and jump circuitry determines whether the program counter should advance sequentially or change to a target address.

Results are written back to the register file when required.

## Current Project Flow

The current implementation follows this sequence:

RISC-V Machine Code >>

C++ Program Loader >>

Instruction Count Calculation >>

UART Transmission >>

FPGA UART Receiver >>

UART Loader FSM >>

Instruction Memory >>

Instruction Fetch >>

Instruction Decode >>

ALU / Memory / Branch Execution >>

Register Write-Back

## FPGA Architecture

The primary processor architecture consists of:

**Datapath:**

Program Counter >>

Instruction Memory >>

Instruction Register >>

Instruction Decoder >>

Register File / Immediate Generator >>

ALU >>

Data Memory / Write-Back >>

Register File

**Control:**

CTRL_FSM >>

Instruction Fetch / Decode / Execute / Memory / Write-Back Control

**Program Loading:**

UART RX >>

UART_LOADER >>

Instruction Memory

The processor uses a 32-bit datapath and 32-bit RISC-V instructions.

Instruction memory currently supports 256 instructions.

## UART Communication

The host computer communicates with the FPGA using UART at:

**115200 baud, 8 data bits, no parity, 1 stop bit.**

The C++ uploader uses the Windows API to configure the serial port and transmit machine-code instructions.

The UART loader recognizes three commands:

- `L` (`0x4C`) — Begin instruction loading.
- `R` (`0x52`) — Begin CPU execution.
- `X` (`0x58`) — Stop/reset CPU execution.

After the LOAD command, the host transmits a 16-bit instruction count in little-endian order.

Each 32-bit instruction is then transmitted as four bytes, least significant byte first.

For example:

Instruction: `0x00500093`

UART transmission: `93 00 50 00`

The FPGA reconstructs the instruction and writes it into instruction memory.

Once the requested number of instructions has been loaded, the RUN command releases the CPU from reset.

## Instruction Memory

Instruction memory contains 256 locations, each storing one 32-bit instruction.

The program counter is byte-addressed, while instruction memory uses word indexing.

The UART loader provides a write-enable signal, instruction address, and 32-bit instruction data.

Unused memory locations can be initialized with the RISC-V NOP instruction:

`0x00000013`

This allows programs to be loaded dynamically without generating a new FPGA bitstream for each instruction sequence.

## Verification and Debugging

The processor and UART loader have been developed incrementally using SystemVerilog simulation.

A UART testbench was created to transmit the same command sequence used by the C++ application.

Simulation verified:

- UART reception of command and instruction bytes.
- Correct reconstruction of 32-bit instructions.
- Instruction memory write addresses and data.
- Instruction-count tracking.
- LOAD completion signaling.
- CPU reset release following the RUN command.

A three-instruction test program was used:

```assembly
addi x1, x0, 5
addi x2, x0, 10
add  x3, x1, x2
```

The expected final result is `x3 = 15`.

The UART loader and instruction memory writes have been verified in simulation. Full processor arithmetic verification on physical hardware remains in progress.

## Hardware Testing

The FPGA design has been successfully synthesized, implemented, and programmed onto the Basys 3.

The C++ uploader has been tested using the board's USB-UART connection.

The host application successfully opens the serial port, configures communication, reads machine-code instructions, and submits the complete instruction-loading sequence.

UART RX activity has been observed on the Basys 3 during transmission.

The current implementation does not yet return execution results to the host computer, so UART transmission alone does not establish successful instruction execution.

## Deployment

The design has been deployed to a Digilent Basys 3 development board containing a Xilinx Artix-7 FPGA.

AMD Vivado is used for RTL synthesis, implementation, timing analysis, bitstream generation, and FPGA programming.

The C++ uploader runs on Windows and uses the Windows API for serial communication.

## Project Goals

The primary goal of this project is to develop a functional RISC-V processor from individual RTL components and gain experience with processor architecture and hardware/software integration.

The project provides experience with:

- SystemVerilog RTL design
- RISC-V instruction encoding
- Multicycle processor architecture
- Datapath and control design
- Finite state machines
- Arithmetic logic units
- Register files and memory systems
- Branch and jump execution
- UART communication
- C++ hardware interfacing
- RTL simulation and verification
- FPGA synthesis and implementation
- Hardware debugging

## Future Improvements

Potential future improvements include:

- Four-digit seven-segment display for register values and instructions
- LED indicators for CPU and UART loader status
- UART TX responses for execution verification
- Expanded instruction-set verification
- CPU single-step execution and debugging

## Author

Stephen Bobbitt

Electrical Engineering  
University of Arkansas  
Expected Graduation: December 2028
