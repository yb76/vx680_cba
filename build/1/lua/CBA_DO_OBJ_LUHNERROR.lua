function do_obj_luhnerror(retry)
  local scrlines = "WIDELBL,,120,3,C;" .. "WIDELBL,,123,5,C;"
  local scrkeys  = KEY.CNCL+KEY.OK+KEY.CLR
  terminal.ErrorBeep()
  local screvent,_ = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnErrTimeout)

  retry = retry and retry + 1 or 1
  if retry >= 3 then
    return do_obj_txn_finish() 
  else
	return do_obj_cardentry(retry)
  end
end
