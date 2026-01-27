# FastCore – Early Branch Resolution in Verilog

A Verilog implementation of an **early branch resolution mechanism** using a fast pre-execution core.  
Simple, dependency-ready instructions are speculatively executed ahead of the main pipeline to resolve branch outcomes earlier and reduce branch misprediction penalty.

## What this shows
- Early branch resolution before the main execute stage  
- Speculative execution of simple integer instructions  
- Reduced effective branch penalty in simulation  
- Clear separation between fast execution path and main pipeline

## Key components
- **fast_core.v**  
  Fast pre-execution core supporting ADD, SUB, AND, OR, SLT, ADDI, BEQ, BNE using SRF/ERF.
- **branch_predictor.v**  
  Simple 2-bit saturating counter predictor with global history.
- **tb_fast_core_system.v**  
  Self-checking testbench with waveform and console output.

## Scope
This is **not a full CPU**. Loads/stores, floating point, and memory hierarchy are intentionally excluded.  
The goal is to demonstrate the **architectural concept**, not a production processor.

## Reference
David M. Koppelman,  
*Early Branch Resolution using a Fast Pre-Execution Core on a Dynamically Scheduled Processor*, 2005
