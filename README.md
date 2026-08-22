# Asynchronous FIFO

## Overview

Designed and implemented an **Asynchronous FIFO (First-In-First-Out)** in Verilog HDL for reliable data transfer between two independent clock domains.

Unlike a synchronous FIFO, an asynchronous FIFO uses **separate write and read clocks**. This makes it suitable for transferring data between systems operating at different clock frequencies.

The design uses **Gray-code pointers** and **two-flop synchronizers** to safely transfer pointer information between the write and read clock domains.

---

## Key Features

* Independent write and read clock domains
* Parameterized FIFO data width and depth
* Binary read/write pointers
* Binary-to-Gray code conversion
* Two-flop clock-domain synchronizers
* Full and empty detection
* FIFO memory
* Independent read and write operations
* Simultaneous read/write operation
* Reset functionality
* Self-checking testbench
* Functional verification using **Xilinx Vivado XSim**
* Verified using different write and read clock frequencies

---

## Why Asynchronous FIFO?

An asynchronous FIFO is used when data needs to be transferred between two systems operating with **independent clocks**.

For example:

```text
             WRITE CLOCK DOMAIN
                    |
                    |
              Write Data
                    |
                    v
             +-------------+
             |             |
             | FIFO MEMORY |
             |             |
             +-------------+
                    |
                    |
                    v
              Read Data
                    |
                    |
             READ CLOCK DOMAIN
```

The write side operates using `wr_clk`, while the read side operates using `rd_clk`.

The two clock domains do not need to have the same frequency or phase.

---

## Architecture

The FIFO consists of the following major blocks:

```text
                 WRITE DOMAIN
              -------------------
                    wr_clk
                       |
                       v
              +----------------+
              | Write Pointer  |
              | Binary         |
              +----------------+
                       |
                       v
              +----------------+
              | Binary to Gray |
              +----------------+
                       |
                       v
              +----------------+
              | 2-FF           |
              | Synchronizer   |
              +----------------+
                       |
                       |
                       v
              READ POINTER
              INFORMATION


              +----------------------+
              |                      |
              |    FIFO MEMORY       |
              |                      |
              +----------------------+

                       |
                       |
                       v

              +----------------+
              | Read Pointer   |
              | Binary         |
              +----------------+
                       |
                       v
              +----------------+
              | Binary to Gray |
              +----------------+
                       |
                       v
              +----------------+
              | 2-FF           |
              | Synchronizer   |
              +----------------+
                       |
                       |
                       v
              WRITE POINTER
              INFORMATION

                 READ DOMAIN
              ----------------
                    rd_clk
```

---

## Clock Domains

The design contains two independent clock domains.

### Write Clock Domain

The write side is controlled by:

```text
wr_clk
```

Data is written when:

```text
wr_en = 1
```

and:

```text
full = 0
```

### Read Clock Domain

The read side is controlled by:

```text
rd_clk
```

Data is read when:

```text
rd_en = 1
```

and:

```text
empty = 0
```

---

## FIFO Parameters

The design is parameterized using:

```verilog
parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 4;
```

Therefore:

```text
DATA_WIDTH = 8 bits
FIFO_DEPTH = 2^ADDR_WIDTH
           = 2^4
           = 16 locations
```

Hence the implemented FIFO stores:

```text
16 × 8-bit words
```

The parameters can be changed to create FIFOs of different sizes.

For example:

```verilog
DATA_WIDTH = 16
ADDR_WIDTH = 5
```

would create:

```text
32 locations × 16 bits
```

---

## FIFO Ports

| Port      | Direction | Description             |
| --------- | --------- | ----------------------- |
| `wr_clk`  | Input     | Write clock             |
| `rd_clk`  | Input     | Read clock              |
| `rst`     | Input     | Reset                   |
| `wr_en`   | Input     | Write enable            |
| `rd_en`   | Input     | Read enable             |
| `wr_data` | Input     | Data written into FIFO  |
| `rd_data` | Output    | Data read from FIFO     |
| `full`    | Output    | Indicates FIFO is full  |
| `empty`   | Output    | Indicates FIFO is empty |

---

## Binary Pointers

Separate binary pointers are maintained for the two clock domains.

### Write Pointer

```text
wr_ptr_bin
```

It points to the location where the next write will occur.

### Read Pointer

```text
rd_ptr_bin
```

It points to the location from which the next read will occur.

An additional MSB is used with the pointers to detect FIFO wrap-around and distinguish between full and empty conditions.

---

## Binary-to-Gray Conversion

Directly transferring a multi-bit binary counter between asynchronous clock domains can cause problems because multiple bits may change simultaneously.

For example:

```text
Binary:

0111 → 1000
```

Four bits change simultaneously.

If the destination clock samples during the transition, it could potentially observe an invalid intermediate value.

To avoid this, the binary pointer is converted to Gray code.

The conversion is:

```text
Gray = Binary XOR (Binary >> 1)
```

In Verilog:

```verilog
gray_ptr = binary_ptr ^ (binary_ptr >> 1);
```

The important property of Gray code is that **only one bit changes between consecutive values**.

---

## Gray Code Example

For a binary counter:

```text
Binary    Gray

0000      0000
0001      0001
0010      0011
0011      0010
0100      0110
0101      0111
0110      0101
0111      0100
```

Only one Gray-code bit changes between adjacent values.

This makes Gray-coded pointers much safer to synchronize across asynchronous clock domains.

---

## Clock-Domain Synchronization

The Gray-coded pointer from one clock domain is passed through a **two-flop synchronizer** before being used in the other clock domain.

### Read pointer → Write domain

```text
rd_ptr_gray
      |
      v
+-------------+
| Synchronizer|
| Flip-Flop 1 |
+-------------+
      |
      v
+-------------+
| Synchronizer|
| Flip-Flop 2 |
+-------------+
      |
      v
rd_ptr_gray_sync2
```

### Write pointer → Read domain

```text
wr_ptr_gray
      |
      v
+-------------+
| Synchronizer|
| Flip-Flop 1 |
+-------------+
      |
      v
+-------------+
| Synchronizer|
| Flip-Flop 2 |
+-------------+
      |
      v
wr_ptr_gray_sync2
```

The two-flop synchronizers reduce the probability of metastability propagating into the receiving clock domain.

---

# Full Detection

The FIFO is considered **full** when the next write pointer would catch up to the read pointer after a complete FIFO wrap-around.

The Gray-coded write pointer is compared against the synchronized read pointer.

For an asynchronous FIFO, the appropriate upper pointer bits are inverted during the full comparison.

Conceptually:

```text
Next Write Pointer
        |
        v
     Compare
        |
        v
Synchronized Read Pointer
        |
        v
      FULL
```

When:

```text
full = 1
```

additional writes are prevented.

Therefore:

```verilog
if (wr_en && !full)
    write_data;
```

---

# Empty Detection

The FIFO is empty when the read pointer catches up with the synchronized write pointer.

The condition is:

```text
Next Read Gray Pointer
          ==
Synchronized Write Gray Pointer
```

When:

```text
empty = 1
```

no read operation is performed.

Therefore:

```verilog
if (rd_en && !empty)
    read_data;
```

---

# FIFO Operation

## Write Operation

A write occurs when:

```text
wr_en = 1
```

and:

```text
full = 0
```

The sequence is:

```text
Write Enable
     |
     v
Check FULL
     |
     v
Write Data to Memory
     |
     v
Increment Binary Write Pointer
     |
     v
Convert Binary Pointer to Gray
     |
     v
Synchronize to Read Domain
```

---

## Read Operation

A read occurs when:

```text
rd_en = 1
```

and:

```text
empty = 0
```

The sequence is:

```text
Read Enable
     |
     v
Check EMPTY
     |
     v
Read Data from Memory
     |
     v
Increment Binary Read Pointer
     |
     v
Convert Binary Pointer to Gray
     |
     v
Synchronize to Write Domain
```

---

# Reset Operation

When reset is asserted:

```text
rst = 1
```

the FIFO is initialized.

The pointers are reset:

```text
wr_ptr_bin  = 0
rd_ptr_bin  = 0

wr_ptr_gray = 0
rd_ptr_gray = 0
```

The FIFO status becomes:

```text
full  = 0
empty = 1
```

Therefore, immediately after reset, the FIFO is empty and ready for writing.

---

# Testbench

A dedicated testbench was developed to verify the FIFO functionality.

The testbench generates two independent clocks.

### Write Clock

```text
Period = 10 ns
```

### Read Clock

```text
Period = 14 ns
```

Thus:

```text
wr_clk ≠ rd_clk
```

This verifies the asynchronous nature of the FIFO.

---

# Verification Tests

The testbench performs multiple functional tests.

## Test 1 — Write Operation

Data values are written into the FIFO sequentially.

Example:

```text
1
2
3
4
5
6
7
8
9
10
```

The write operation occurs only when:

```text
full = 0
```

---

## Test 2 — Read Operation

Previously stored data is read from the FIFO.

The expected behavior is:

```text
1
2
3
4
5
6
7
8
9
10
```

The data is therefore verified to follow **FIFO ordering**.

---

## Test 3 — Simultaneous Read/Write

Read and write operations are performed concurrently using different clocks.

```text
WRITE DOMAIN             READ DOMAIN

wr_clk                   rd_clk
   |                        |
   v                        v
 Write                    Read
   |                        |
   +-------- FIFO ----------+
```

This verifies that both operations can occur independently.

---

## Test 4 — FIFO Full Condition

The FIFO is filled until the `full` signal becomes active.

Expected behavior:

```text
full = 1
```

Once the FIFO becomes full, additional write operations are blocked.

---

## Test 5 — FIFO Empty Condition

The FIFO contents are subsequently read until no data remains.

Expected behavior:

```text
empty = 1
```

Once the FIFO becomes empty, additional read operations are blocked.

---

# Simulation

The design was functionally verified using:

**Xilinx Vivado XSim**

The important waveform signals are:

```text
wr_clk
rd_clk
rst
wr_en
rd_en
wr_data
rd_data
full
empty
```

For internal verification, the following signals can also be observed:

```text
wr_ptr_bin
rd_ptr_bin
wr_ptr_gray
rd_ptr_gray
wr_ptr_gray_sync2
rd_ptr_gray_sync2
```

---

# Expected Waveform Behavior

Initially:

```text
empty = 1
full  = 0
```

After writing data:

```text
empty → 0
```

As the FIFO fills:

```text
write pointer → advances
```

When the FIFO reaches its maximum capacity:

```text
full = 1
```

Further writes are blocked.

When data is read:

```text
read pointer → advances
```

and eventually:

```text
empty = 1
```

again.

---
# Waveform
<img width="1569" height="572" alt="image" src="https://github.com/user-attachments/assets/eb4ffffc-de76-4331-be9a-6392580a0536" />
<img width="1569" height="515" alt="image" src="https://github.com/user-attachments/assets/cce00091-3efb-4885-934c-7fd6163111e0" />
<img width="1576" height="684" alt="image" src="https://github.com/user-attachments/assets/8c02ca7c-0113-4edf-8dc7-32a32f0e7ddb" />
<img width="1568" height="462" alt="image" src="https://github.com/user-attachments/assets/9a3216ef-67b7-4ad1-8c17-a10a06fce0d6" />





# File Structure

The complete project can be maintained as:

```text
Asynchronous-FIFO/
│
├── async_fifo_complete.v
└── README.md
```

The Verilog file contains:

```text
async_fifo
    |
    +-- FIFO Memory
    +-- Write Pointer
    +-- Read Pointer
    +-- Binary-to-Gray Conversion
    +-- Write Pointer Synchronizer
    +-- Read Pointer Synchronizer
    +-- Full Detection
    +-- Empty Detection
    |
    +-- Testbench
```

---

# Technologies Used

* **Verilog HDL**
* **Xilinx Vivado**
* **XSim**
* Digital Logic Design
* Clock Domain Crossing
* Gray Code
* FIFO Architecture

---

# Applications

Asynchronous FIFOs are commonly used for transferring data between systems operating at different clock frequencies.

Applications include:

* Clock-domain crossing
* Digital communication systems
* FPGA-based systems
* Processor interfaces
* Data buffering
* Network interfaces
* High-speed data acquisition
* SoC and embedded systems

---

# Learning Outcomes

Through this project, the following concepts were implemented and verified:

* Asynchronous FIFO architecture
* Clock-domain crossing
* Binary counters
* Gray-code counters
* Pointer synchronization
* Metastability reduction
* FIFO full detection
* FIFO empty detection
* Independent clock domains
* Memory read/write operations
* Verilog RTL design
* Functional simulation and waveform analysis

---

# Conclusion

A fully functional **Asynchronous FIFO** was designed using Verilog HDL.

The design supports independent write and read clock domains and uses **Gray-coded pointers with two-flop synchronizers** for safe clock-domain crossing.

The FIFO was verified through multiple simulation scenarios including:

* Normal write
* Normal read
* Simultaneous read/write
* FIFO full condition
* FIFO empty condition
* Different write/read clock frequencies

The final simulation demonstrated correct FIFO behavior with **zero functional errors during verification**.
