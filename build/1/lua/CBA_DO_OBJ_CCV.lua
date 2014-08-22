function do_obj_ccv()
  local scrlines = "WIDELBL,,112,2,C;" .. "LNUMBER,,0,5,17,5,1;"
  local scrkeys  = KEY.OK+KEY.CLR+KEY.CNCL
  local screvents = EVT.TIMEOUT
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)

  if screvent == "KEY_CLR" then
    return do_obj_card_expiry()
  elseif screvent == "KEY_OK" then
    if #scrinput > 0 then txn.ccv = "CCV" .. scrinput .. "\\" end
    return do_obj_account()
  else
	local scrlines1 = "WIDELBL,,120,3,C;"
	local scrkeys1  = KEY.OK+KEY.CLR+KEY.CNCL
	local screvents1 = EVT.TIMEOUT
	local screvent,scrinput = terminal.DisplayObject(scrlines1,scrkeys1,screvents1,1000)

    return do_obj_txn_finish()
  end
end
