# SDRAM-Controller
In this project, Verilog Design and testbenches for SDRAM Controller for SDR Memory of 1Mx 4 Banks x 16 bits was made. Extensive study of various signals and designing of the state diagram for the SDRAM Controller was carried out in this project.



# Basic Features of SDRAM Controller - 

- 1048576 words x 4 banks x 16 bits organization, 
- Burst read,single write operation, 
- CAS latency: 2 and 3, 
- Burst Length: 1, 2, 4, 8, 
- Sequential and Inter leave burst, 
- Byte data controlled by DQMs (UDQM & LDQM), 
- Power-down Mode, 
- Auto-precharge and controlled precharge,
- 4K refresh cycles/64 mS


# Block Diagram for SDRAM-Controller

The hardware deisgn of the controller was designed by having the motivation from the following block diagram from the datasheet. 

![Block](https://user-images.githubusercontent.com/66430218/115138284-c0f05f00-a048-11eb-9c5d-ff85e56f9079.JPG)

# State Diagram for SDRAM-Controller

Most extensive part of this project was to design the State Diagram and try to keep it nearer to the original functionality of the SDRAM Controller from the Datasheet.
![FSM (6)](https://user-images.githubusercontent.com/66430218/115138287-c352b900-a048-11eb-859c-fa3a35ec7c69.jpg)



# Software Flowchart for the Verilog Code of SDRAM-Controller

After deciding all the State Diagrams, the most challenging part of this project was to come up with Verilog Code and various approaches were encountered of which the below Algorithm plan was finally selected. The actual Verilog Code looks more unusual than the below FlowChart.

![CA_SDRAM_Ctrl_Flowchart-1](https://user-images.githubusercontent.com/66430218/115138285-c2218c00-a048-11eb-8917-61ff7ee334dd.jpg)

