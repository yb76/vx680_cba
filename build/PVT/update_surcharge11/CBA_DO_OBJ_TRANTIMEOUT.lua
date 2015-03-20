function do_obj_trantimeout()
  local scrlines = "WIDELBL,,120,2,C;" .. "WIDELBL,,122,4,C;"
  local scrkeys  = KEY.CNCL
  terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT+EVT.SCT_OUT,ScrnErrTimeout)
  return do_obj_txn_finish()
end
