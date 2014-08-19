function do_obj_txn_second_copy()
  local scrlines = "WIDELBL,,36,4,C;" .."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
  local screvent,_ = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,ScrnTimeout)

  if screvent == "BUTTONS_1" or screvent == "TIME" or screvent == "KEY_OK" then
    scrlines = "WIDELBL,,37,2,C;" .."WIDELBL,,26,4,C;"
    terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)

    local resultstr= (txn.rc ~= "Y1" and txn.rc ~= "Y3" and (( txn.moto and "MOTO " or "" ) .. "APPROVED\\R") or "OFFLINE APPROVED\\R") .. txn.rc.."\\n"
    local who = "CUSTOMER\ COPY\\n"
	local prtvalue = (ecrd.HEADER or "") .. (ecrd.HEADER_OK or "") .. get_ipay_print( who, true, resultstr) 
	.. (ecrd.CTRAILER or "") 
	
    terminal.Print(prtvalue,true)
	checkPrint(prtvalue)
    terminal.SetJsonValue("DUPLICATE","RECEIPT",prtvalue)
  end
  update_total()
  return do_obj_txn_finish()
end
