function itaxi_reprint_menu()
  local scrlines = ",THIS,REPRINT,-1,C;" .."BUTTONM_1,iTAXI_T,152,2,C;" .."BUTTONM_2,iTAXI_T,153,4,C;".."BUTTONM_3,iTAXI_T,154,6,C;" .."BUTTONM_4,iTAXI_T,155,8,C;" .. "BUTTONM_5,THIS,LAST DECLINED TXN,10,C;".. "BUTTONM_6,THIS,LAST EMV TXN,12,C;"
  local scrkeys  = KEY.CLR+KEY.CNCL
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  local taxi_min,taxi_next= terminal.GetArrayRange("TAXI")
  local shft_min,shft_next= terminal.GetArrayRange("PREV_SHFT")
  
  if  screvent == "BUTTONM_1" then
    if taxi_min == taxi_next then -- no array item
      return itaxi_reprint_no_inv()
    else return itaxi_reprint_do() end
  elseif  screvent == "BUTTONM_2" then
    return itaxi_reprint()
  elseif  screvent == "BUTTONM_3" then
    if shft_min == shft_next then return itaxi_retotal_no_batch()
    else return itaxi_retotal(shft_next-1) end
  elseif screvent == "BUTTONM_4" then
    return itaxi_retotal()
  elseif screvent == "BUTTONM_5" then
    return itaxi_reprint_do(0,"TAXI_Dclnd")
  elseif screvent == "BUTTONM_6" then
    return itaxi_reprint_do(nil,"LASTEMV_RCPT",true)
  elseif screvent == "KEY_CLR" then
    return itaxi_fmenu()
  else
    return itaxi_finish()
  end
end
