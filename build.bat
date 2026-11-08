@echo off
rem Assembles src\mario.asm into src\mario.com. Run this inside DOSBox.
cd \src
nasm -O2 mario.asm -o mario.com
if errorlevel 1 goto failed
echo Build OK. Type: cd \src  then  mario
goto end
:failed
echo BUILD FAILED - read the error above
:end
cd \
