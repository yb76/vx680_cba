@echo off
rem ##################################
rem dctls.bat
rem 
rem This batch file downloads and installs
rem the EOS VxCTLS package.
rem
rem copyright 2009, Verifone Inc.
rem ##################################

ddl -p1 CTLSL1_A2.zip CTLSL2_A2.zip *unzip=CTLSL1_A2.zip,CTLSL2_A2.zip   *CTLS_POLL_EVT=1

pause