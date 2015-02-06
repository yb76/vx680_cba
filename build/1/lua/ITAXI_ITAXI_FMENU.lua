function itaxi_fmenu()
  local scrlines = "BUTTONL_1,THIS,CASH RECEIPT,P40,C;" .. "BUTTONL_2,iTAXI_T,73,P110,C;".. "BUTTONL_3,iTAXI_T,75,P180,C;".."BUTTONL_4,THIS,SEND TRANS,P250,C;"
  local scrkeys = KEY.CNCL+KEY.FUNC
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  taxi = {}
  
  if screvent == "BUTTONL_1" then
    taxi.cash = true
    return itaxi_pickup()
  elseif screvent == "BUTTONL_2" then
    return itaxi_reprint_menu()
  elseif screvent == "BUTTONL_3" then
    return itaxi_totals()
  elseif screvent == "BUTTONL_4" then
    itaxi_update()
    do_obj_gprs_register()
	return itaxi_finish()
  elseif screvent == "KEY_FUNC" then
    local pwd = terminal.GetJsonValue("IRIS_CFG","SETUP_PWD")
	if pwd == "" then pwd = "893701" end
    if check_pwd(pwd) then  return itaxi_smenu()
	else return itaxi_finish() end
  else
    return itaxi_finish()
  end
end
