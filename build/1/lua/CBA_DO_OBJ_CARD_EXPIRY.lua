function do_obj_card_expiry(retry)
  local scrlines = "WIDELBL,,111,2,C;" .. "LNUMBER,,0,5,18,4,4;"
  local scrkeys  = KEY.OK+KEY.CLR+KEY.CNCL
  local screvents = EVT.TIMEOUT
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)

  if screvent == "KEY_CLR" then
    return do_obj_cardentry()
  elseif screvent == "KEY_OK" then
	local currmonth = terminal.Time( "YYMM")
	local expirydate = string.sub(scrinput,3,4) .. string.sub(scrinput,1,2)
	if expirydate ~= "" and tonumber(currmonth) > tonumber(expirydate) then
		return do_obj_invmonth(retry)
    else txn.expiry = scrinput
         return do_obj_ccv()
    end
  else 
	local scrlines1 = "WIDELBL,,120,3,C;"
	local scrkeys1  = KEY.OK+KEY.CLR+KEY.CNCL
	local screvents1 = EVT.TIMEOUT
	local screvent,scrinput = terminal.DisplayObject(scrlines1,scrkeys1,screvents1,1000)

	return do_obj_txn_finish()
  end
end
