FastCore – Early Branch Resolution in Verilog

This project implements an early branch resolution mechanism in Verilog using a fast pre-execution core. Simple, dependency-ready instructions are speculatively executed ahead of the main pipeline, allowing branch outcomes to be resolved earlier and reducing branch misprediction penalty in pipelined processors.

🚀 Overview

Branch mispredictions are a major performance bottleneck in deeply pipelined processors.
This project demonstrates a fast auxiliary execution core that runs in parallel with the main pipeline and evaluates branch conditions early. The design focuses on architectural clarity and correctness, not full CPU completeness.

🧠 Core Idea

A Fast Core executes alongside the main pipeline

Only simple, dependency-free instructions are executed

Branch conditions are evaluated before the main pipeline reaches the branch

Early resolution enables faster recovery and fewer wasted cycles

🏗️ Implemented Modules
fast_core.v

Fast pre-execution core that:

Executes integer ALU operations (ADD, SUB, AND, OR, SLT)

Supports ADDI

Resolves branches (BEQ, BNE) early

Uses:

Sojourn Register File (SRF) for temporary speculative results

Exit Register File (ERF) for architectural state

Outputs branch_resolved and branch_taken

branch_predictor.v

Simple 2-bit saturating counter branch predictor

256-entry Pattern History Table (PHT)

8-bit Global History Register (GHR)

tb_fast_core_system.v

Self-checking testbench

Generates arithmetic and branch instruction sequences

Displays early branch resolution events, predictor behavior, and cycle-level activity

🧪 Simulation

Tools

ModelSim (Intel FPGA Edition) or Icarus Verilog

GTKWave / ModelSim Wave window

Run (ModelSim)

vsim tb_fast_core_system
run -all


$display output appears in the Transcript window.

📊 What This Demonstrates

Early branch resolution before the main execute stage

Correct speculative execution without violating correctness

Reduced effective branch penalty (observed in simulation)

Clear separation between fast execution path and main pipeline

🎯 Scope & Limitations

This is not a full CPU. By design, it excludes:

Loads and stores

Floating-point execution

Complex scheduling and renaming

Memory hierarchy

The goal is to demonstrate the architectural concept, not replicate a commercial processor.

📚 Reference

David M. Koppelman,
Early Branch Resolution using a Fast Pre-Execution Core on a Dynamically Scheduled Processor,
Louisiana State University, 2005.
