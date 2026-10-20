@echo off
setlocal
echo ============================================================
echo Compiling 32-Bit Multi-Cycle RISC-V Core (RV32I_Zmmul)...
echo ============================================================

iverilog -o sim.vvp rtl/*.v tb/tb_basic_cpu_validation.v
if %errorlevel% neq 0 (
    echo [ERROR] Compilation failed!
    exit /b %errorlevel%
)

echo.
echo Running VVP Simulation...
echo ============================================================
vvp sim.vvp
if %errorlevel% neq 0 (
    echo [ERROR] Simulation failed!
    exit /b %errorlevel%
)

echo.
echo Simulation passed successfully. Waveform saved to full_validation.vcd.
