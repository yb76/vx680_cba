function do_obj_txn_finish(nosaf)
  terminal.FileRemove("TXN_REQ")
  terminal.FileRemove("REV_TODO")
  if txn.finishreturn then return txn.finishreturn
  else
    terminal.EmvResetGlobal()
    if txn.chipcard and terminal.EmvIsCardPresent() and not (ecrd and ecrd.RETURN) then
      terminal.EmvPowerOff()
	  	terminal.ErrorBeep()
      local scrlines = "WIDELBL,,286,2,C;"
      terminal.DisplayObject(scrlines,0,EVT.SCT_OUT,ScrnTimeoutZO)
	end
	local nextstep = ( ecrd.RETURN or do_obj_idle )
	saf_rev_check()
	if nosaf or txn.rc == "Y3" then 
		return nextstep()
	elseif txn.rc == "Y1" then
		return do_obj_saf_rev_start(nextstep)
    elseif txn.rc=="00" or txn.rc == "08" or txn.rc =="Z4" then
		return do_obj_saf_rev_start(nextstep,"SAF")
	else 
		return nextstep()
	end
  end
end
