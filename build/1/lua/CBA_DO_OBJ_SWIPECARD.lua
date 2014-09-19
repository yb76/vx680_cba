function do_obj_swipecard()
  local scrlines = "WIDELBL,THIS,SWIPE/INSERT,1,C;".."WIDELBL,THIS,CARD,2,C;"
  local scrkeys  = KEY.CNCL
  local screvents = EVT.TIMEOUT+EVT.MCR+EVT.SCT_IN
  local cardreject = false
  if txn.emv_retry then scrlines = "WIDELBL,THIS,INSERT CARD,2,C;"; screvents = EVT.TIMEOUT+EVT.SCT_IN end

  if txn.chipcard and txn.emv.fallback then
    scrlines = "WIDELBL,THIS,SWIPE CARD,2,C;"
    scrkeys  = KEY.CNCL
    screvents = EVT.TIMEOUT+EVT.MCR
  elseif txn.swipefirst == 1 and not txn.ctls and not txn.cardname then
    local swipeflag,cardname = swipecheck( txn.track2)
	if swipeflag < 0 then cardreject = true
	elseif swipeflag == 0 then
      scrlines = "WIDELBL,THIS,INSERT CARD,2,C;"
      screvents = EVT.TIMEOUT+EVT.SCT_IN
      txn.swipefirst = nil
      txn.track2 = nil	
	elseif swipeflag > 0 then
		txn.cardname = cardname
	end
  end
  
  if txn.CTEMVRS and txn.CTEMVRS == "10" then return do_obj_transdial() --offline declined
  elseif txn.CTEMVRS and txn.CTEMVRS == "W30" then return do_obj_transdial() --offline declined
  elseif cardreject then return do_obj_txn_finish()
  elseif txn.swipefirst == 1 then return do_obj_account()
  elseif txn.chipcard and not txn.emv.fallback and not txn.emv_retry then 
	return do_obj_account()
  else
    txn.track2 = nil
    local screvent,_ = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)
    if screvent == "MCR" then
      txn.track2 = terminal.GetTrack(2)
      if txn.track2 == nil or #txn.track2 < 11 then return do_obj_swipecard()
      elseif not txn.emv.fallback then txn.swipefirst = 1;return do_obj_swipecard() -- double check the chipflag
      elseif txn.totalamt then return do_obj_account() 
	  else txn.swipefirst = 1; return do_obj_prchamount() end
    elseif screvent == "TIME" then
      return do_obj_trantimeout()
    elseif screvent == "CANCEL" then
      return do_obj_txn_finish()
    elseif screvent == "CHIP_CARD_IN" then
      txn.chipcard = true
      local ok = emv_init()
	  if ok ~= 0 then return do_obj_emv_error(ok)
      else txn.emv_retry = true
		if txn.totalamt then return do_obj_account() else return do_obj_prchamount() end
	  end
    end
  end
end
