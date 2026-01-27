# FastCore-Early-Branch-Resolution-in-Verilog-
This project implements an early branch resolution mechanism in Verilog using a fast pre-execution core. Simple, dependency-ready instructions are speculatively executed ahead of the main pipeline, allowing branch outcomes to be resolved earlier and reducing branch misprediction penalty in pipelined processors.
🚀 Overview

Branch mispredictions are a major performance bottleneck in deeply pipelined processors.
This project demonstrates a fast auxiliary execution core that speculatively executes simple instructions ahead of the main pipeline to resolve branches earlier, thereby reducing branch penalty.

The design focuses on concept clarity and architectural correctness, not full CPU completeness.

🧠 Core Idea

A Fast Core runs in parallel with the main pipeline

Only simple, dependency-free instructions are executed

Branch conditions are evaluated before the main pipeline reaches the branch

Early resolution allows faster recovery on misprediction and fewer wasted cycles

🏗️ Implemented Modules
fast_core.v

Fast pre-execution core

Executes:

Integer ALU ops (ADD, SUB, AND, OR, SLT)

ADDI

Branches (BEQ, BNE)

Uses:

Sojourn Register File (SRF) for temporary speculative results

Exit Register File (ERF) for architectural state

Resolves branches early and outputs branch_resolved / branch_taken

branch_predictor.v

Simple 2-bit saturating counter predictor

256-entry Pattern History Table (PHT)

8-bit Global History Register (GHR)

tb_fast_core_system.v

Self-checking testbench

Generates arithmetic and branch sequences

Displays:

Early branch resolution events

Predictor accuracy

Cycle-level behavior

🧪 Simulation
Tools

ModelSim (Intel FPGA Edition) or Icarus Verilog

GTKWave / ModelSim Wave window

Run (ModelSim)
vsim tb_fast_core_system
run -all


Console output ($display) appears in the Transcript window.

📊 What This Demonstrates

Early branch resolution before pipeline execute stage

Correct speculative execution without violating correctness

Reduced effective branch penalty in simulation

Clear separation between fast execution path and main pipeline logic

🎯 Scope & Limitations

This is not a full CPU. By design, it excludes:

Loads/stores

Floating point

Complex scheduling and renaming

Memory hierarchy

The goal is to clearly demonstrate the architectural concept, not replicate a commercial processor.

📚 Reference

David M. Koppelman,
Early Branch Resolution using a Fast Pre-Execution Core on a Dynamically Scheduled Processor,
Louisiana State University, 2005.
