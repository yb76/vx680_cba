function itaxi_reprint_no_inv()
  local scrlines = ",THIS,REPRINT,-1,C;" .."WIDELBL,THIS,INVOICE DOES,3,C;" .."WIDELBL,THIS,NOT EXIST,4,C;"
  terminal.ErrorBeep()
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL,EVT.TIMEOUT,ScrnErrTimeout)
  if screvent == "TIME" or screvent == "KEY_CLR" then
     return itaxi_reprint_menu()
  else
    return itaxi_finish()
  end
end
