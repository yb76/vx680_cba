function do_obj_cardentry(retry)
  local scrlines = "WIDELBL,,110,2,C;" .. "LNUMBER,,0,5,10,19,13;"
  local scrkeys  = KEY.OK+KEY.CLR+KEY.CNCL
  local screvents = EVT.TIMEOUT
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)

  if screvent == "KEY_CLR" then
    return do_obj_swipecard()
  elseif screvent == "KEY_OK" then
    txn.pan = scrinput
    txn.account = "CREDIT"
    if terminal.Luhn(txn.pan) == false then return do_obj_luhnerror(retry)
    else return do_obj_card_expiry() end
  elseif screvent == "CANCEL" or screvent == "TIME" then
	local scrlines1 = "WIDELBL,,120,3,C;"
	local scrkeys1  = KEY.OK+KEY.CLR+KEY.CNCL
	local screvents1 = EVT.TIMEOUT
	local screvent,scrinput = terminal.DisplayObject(scrlines1,scrkeys1,screvents1,1000)

    return do_obj_txn_finish()
  end
end
