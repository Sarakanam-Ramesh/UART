UART Protocol Implementation in Verilog
Table of Contents

Overview

UART Protocol Basics

Project Features

Project Structure

Module Description

Simulation and Verification

How to Run

Future Improvements

Author

Overview

This project implements the UART (Universal Asynchronous Receiver Transmitter) protocol using Verilog HDL. UART is one of the most widely used serial communication interfaces in embedded systems and digital hardware.

UART allows communication between two devices using asynchronous serial communication, meaning that no shared clock signal is required. Instead, communication is synchronized using a predefined baud rate.

This project demonstrates a complete UART communication system including:

UART Transmitter

UART Receiver

Baud Rate Generator

Testbench for verification

The design converts parallel data into serial data for transmission and converts received serial data back into parallel data.

UART Protocol Basics

UART communication works by transmitting data in frames.
Each frame consists of multiple parts.

Typical UART configuration: 8N1

8 Data bits

No parity

1 Stop bit

UART Frame Format
| Idle | Start | D0 | D1 | D2 | D3 | D4 | D5 | D6 | D7 | Stop |
|  1   |   0   |                Data Bits               |  1  |
Frame Description
Field	Description
Start Bit	Indicates the beginning of data transmission
Data Bits	Actual transmitted data (LSB first)
Parity Bit	Optional error detection
Stop Bit	Indicates the end of transmission

During idle state, the UART line remains logic HIGH.

Project Features

Fully implemented UART Transmitter

Fully implemented UART Receiver

Baud Rate Generator for timing control

Finite State Machine (FSM) based design

Modular and reusable Verilog implementation

Testbench for verification and simulation

Project Structure
UART
│
├── uart_tx.v
├── uart_rx.v
├── baud_generator.v
├── uart_top.v
├── uart_tb.v
│
└── README.md
Module Description
1. UART Transmitter (uart_tx.v)

The transmitter converts parallel data into serial data.

Operation

Wait for transmit enable signal

Send start bit

Send data bits sequentially

Send stop bit

Return to idle state

Transmitter FSM States

IDLE

START

DATA

STOP

2. UART Receiver (uart_rx.v)

The receiver converts serial input data into parallel output data.

Operation

Detect start bit

Wait for correct sampling time

Sample incoming bits

Store data in shift register

Check stop bit

Output received data

Receiver FSM States

IDLE

START

DATA

STOP

DONE

3. Baud Rate Generator (baud_generator.v)

The baud rate generator divides the system clock to produce the required baud clock used for UART communication.

Example:

System Clock = 50 MHz
Baud Rate = 9600

Clock Divider = System Clock / Baud Rate

The baud generator ensures that each bit is transmitted with the correct timing.

Simulation and Verification

The UART design is verified using a Verilog testbench.

Verification Steps

Provide input data to the transmitter

Transmit serial data through TX line

Receive serial data through RX module

Compare received data with transmitted data

Example
Transmitted Data : 8'b10101010
Received Data    : 8'b10101010

Simulation Result : PASS

Waveforms can be observed using simulation tools such as:

ModelSim

QuestaSim

GTKWave

How to Run
1 Clone the repository
git clone https://github.com/Sarakanam-Ramesh/UART.git
cd UART
2 Compile the design

Example using ModelSim:

vlog uart_tx.v
vlog uart_rx.v
vlog baud_generator.v
vlog uart_tb.v
3 Run simulation
vsim uart_tb
4 Observe waveform

Use the waveform viewer to analyze the TX and RX signals.

Future Improvements

Possible extensions for this project include:

FIFO-based UART buffering

Configurable data width

Parity support

Error detection flags

Integration with APB / AXI bus interfaces

Author

Ramesh Sarakanam

RTL Design | Digital Electronics | FPGA | VLSI

⭐ If you find this project useful, consider giving it a star.
