function do_obj_cba_mcr_chip()
  check_logon_ok()
  local ok = true
  local nextstep = do_obj_cba_swipe_insert
  txn.func = "PRCH"
  if not check_logon_ok() then ok = false ; nextstep = do_obj_txn_finish end
  if not txn_allowed(txn.func) then ok = false ; nextstep = do_obj_txn_finish end
  if ok and common.track2 then txn.track2 = common.track2 ; common = {}
    txn.swipefirst = 1
    local _,_,_,trk2 = string.find(txn.track2, "(%d*)=(%d*)")
	local chipflag = (trk2 and string.sub(trk2,5,5) or "")
    if chipflag == "2" or chipflag == "6" then
		
      terminal.ErrorBeep()
      local scrlines = "LARGE,THIS,INSERT CARD,2,C;"
      local scrkeys  = KEY.CNCL
      local screvents = EVT.TIMEOUT+EVT.SCT_IN
      local screvent,_ = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)
      if screvent ~= "CHIP_CARD_IN" then nextstep = do_obj_txn_finish 
      else txn.chipcard = true end
    end
  elseif ok then txn.chipcard = true end
  return nextstep()
end
