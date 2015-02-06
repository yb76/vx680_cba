@echo OFF
echo Do NOT download the Vx011-EOS to OS9 terminals.
echo because it may lock up the terminal.
echo Press Ctrl+C to abort this procedure. Press any other key to continue.
echo.
pause
ddl -p1 *unzip=Vx011-EOS.zip Vx011-EOS.zip
