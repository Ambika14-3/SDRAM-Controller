# SDRAM-Controller
Verilog Design and testbenches for SDRAM Controller for SDR Memory was written 

# Basic Features - 

A. 1048576 words x 4 banks x 16 bits organization, 
B. Burst read,single write operation, 
C. CAS latency: 2 and 3, 
D. Burst Length: 1, 2, 4, 8, 
E. Sequential and Inter leave burst, 
F. Byte data controlled by DQMs (UDQM & LDQM), 
G. Power-down Mode, 
H. Auto-precharge and controlled precharge,
I. 4K refresh cycles/64 mS


# Block Diagram for SDRAM-Controller

![Block](https://user-images.githubusercontent.com/66430218/115138284-c0f05f00-a048-11eb-9c5d-ff85e56f9079.JPG)

# State Diagram for SDRAM-Controller
![FSM (6)](https://user-images.githubusercontent.com/66430218/115138287-c352b900-a048-11eb-859c-fa3a35ec7c69.jpg)

# Software Flowchart for the Verilog Code of SDRAM-Controller
![CA_SDRAM_Ctrl_Flowchart-1](https://user-images.githubusercontent.com/66430218/115138285-c2218c00-a048-11eb-8917-61ff7ee334dd.jpg)

