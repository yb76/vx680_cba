function do_obj_invmonth(retry)
  terminal.ErrorBeep()
  local scrlines = "WIDELBL,,299,3,C;" .. "WIDELBL,,201,5,C;"
  local scrkeys  = KEY.OK+KEY.CLR+KEY.CNCL
  local screvent,_ = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnErrTimeout)

  retry = retry and retry + 1 or 1
  if retry >= 3 then
    return do_obj_txn_finish()
  else
    return do_obj_card_expiry(retry)
  end
end
