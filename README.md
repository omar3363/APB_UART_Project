# APB_UART_Project
---

## 🚀 Design Overview

The project is divided into **three main modules**:

1. **Transmitter (TX)**  
   - Implements UART frame generation: start bit, 8 data bits (LSB first), stop bit.  
   - Uses a **baud counter**, a **PISO (Parallel-In Serial-Out) shift register**, and an FSM with states: `IDLE`, `DATA`, `DONE`, `ERR`.

2. **Receiver (RX)**  
   - Detects the falling edge of the start bit.  
   - Samples the data at the middle of each bit time.  
   - Uses a **baud counter**, a **SIPO (Serial-In Parallel-Out) shift register**, and an FSM with states: `IDLE`, `START`, `DATA`, `DONE`, `ERR`.

3. **APB Wrapper**  
   - Provides an interface for reading/writing through APB protocol.  
   - Contains registers:
     - `CTRL_REG` → enable/reset TX & RX.  
     - `TX_DATA` → holds the byte to transmit.  
     - `RX_DATA` → holds the received byte.  
     - `STATS_REG` → status flags (busy, done, error).  
   - Decodes address and controls read/write operations via APB signals.

---

## 📝 Design Decisions

- The project was fully implemented using **FSM-based design** for clarity and modularity.  
- **Separate TX and RX modules** were designed, then wrapped with the APB interface to allow memory-mapped access.  
- The APB wrapper simplifies the integration with processors and testbenches.  
- The design supports a **fixed baud rate (9600)**, but the framework allows extending to variable baud rates.  

---

## 📊 State Diagrams

All FSM diagrams for **Transmitter**, **Receiver**, and **APB Wrapper** are available in the `docs/` folder.

---

## ✅ Verification Flow

The verification followed these main steps:

1. **Write into TX_DATA** with letter `"A"` using the APB interface.  
2. **Enable TX and RX** by writing to `CTRL_REG`.  
3. **Read back CTRL_REG** to confirm the enables are set.  
4. **Disable TX and RX** by writing `0` to `CTRL_REG`.  
5. **Read back CTRL_REG** again to confirm the disables.  
6. **Check STATS_REG** → ensure `tx_busy=1` and `rx_busy=1` while UART is active.  
7. **Wait for 10 bit-times** (1 start + 8 data + 1 stop).  
8. **Read RX_DATA** → confirm that the received character is `"A"`.  
9. **Read STATS_REG** → confirm that `tx_done=1` and `rx_done=1`.

During APB transactions:
- **Write** operations are performed using `PWDATA`.  
- **Read** operations return values on `PRDATA`.  

---

## 🧪 Simulation

- Testbenches were developed in **Verilog**.  
- The simulation confirms:
  - Correct APB transactions.  
  - TX transmitting `"A"` successfully.  
  - RX receiving `"A"` successfully.  
  - Proper update of status flags.  

---

## 🔧 FPGA Implementation

- Implemented and tested on **Xilinx Vivado**.  
- Constraint files (`.xdc`) are in the `fpga/` folder.  
- Vivado synthesis and implementation results are included in the `fpga/` folder.

---

## 📎 Additional Material

- **Handwriting Notebook**: Contains manual notes, debugging logs, and design analysis (available in the `handwriting_notebook/` folder).  
- **GitHub Repo**: All RTL codes, testbenches, FPGA runs, documents, and results are available in this repository.  
- Includes **errors encountered** during development and their **solutions**.

---

## 🏁 Conclusion

This project successfully demonstrates a **UART communication system with APB interface** using FSM-based modular design.  
- The transmitter and receiver operate correctly and communicate over a simulated loopback.  
- The APB wrapper provides a clean interface for system integration.  
- The project is fully verified through simulation and FPGA runs.  

Future improvements:  
- Adding **variable baud rate control** through a dedicated register.  
- Extending the design for **parity bit support**.  
- Supporting **interrupt-driven communication** for higher efficiency.
