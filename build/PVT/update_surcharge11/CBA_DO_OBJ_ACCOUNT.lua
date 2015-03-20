function do_obj_account()
  local acc4 = "CHQ"
  local acc5 = "SAV"
  local acc6 = "CR"
  local scrlines_nocr = "WIDELBL,,115,2,C;".. "BUTTONS_1,THIS,".. acc4 .. ",B,4;".. "BUTTONS_2,THIS,".. acc5 .. ",B,21;"
  local scrlines = scrlines_nocr .. "BUTTONS_3,THIS,".. acc6 .. ",B,38;"
  local scrkeys  = KEY.CNCL
  local screvents = EVT.TIMEOUT+EVT.SCT_OUT
  txn.account = ""
  local ok,desc = get_cardinfo()
 
  if not ok then
	return do_obj_txn_nok(desc)
  elseif txn.ctls and txn.CTEMVRS == "W30" then
	return do_obj_transdial()
  elseif txn.ctls or txn.cardname == "AMEX" or txn.cardname == "DINERS" or txn.cardname =="JCB" or txn.pan and #txn.pan > 10 then
		txn.account = "CREDIT" 
		scrlines = "WIDELBL,,119,2,C;".."WIDELBL,,26,3,C;"
		terminal.DisplayObject(scrlines,0,EVT.TIMEOUT,ScrnTimeoutHF)
		return do_obj_pin()
  else
	  if txn.cardname and string.sub(txn.cardname,1,5) == "DEBIT" then scrlines = scrlines_nocr end
	  local screvent = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)
	  if screvent == "TIME" then
		return do_obj_trantimeout()
	  elseif screvent == "BUTTONS_1" then
		txn.account = "CHEQUE"
		scrlines = "WIDELBL,,117,2,C;".."WIDELBL,,26,4,C;"
		terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
		return do_obj_pin()
	  elseif screvent == "BUTTONS_2" then
		txn.account = "SAVINGS"
		scrlines = "WIDELBL,,118,2,C;".."WIDELBL,,26,4,C;"
		terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
		return do_obj_pin()
	  elseif screvent == "BUTTONS_3" then
		txn.account = "CREDIT"
		scrlines = "WIDELBL,,119,2,C;".."WIDELBL,,26,4,C;"
		terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
		return do_obj_pin()
	  elseif screvent == "CHIP_CARD_OUT" then
		return do_obj_emv_error(101)
	elseif screvent == "KEY_CLR" then
		return do_obj_account()
	  else
		return do_obj_txn_finish()
	  end
	end
end
