function do_obj_advice_start(auto)
	local scrlines,scrkeys,screvents,timeout = "","","",0
	if not auto then
	 scrlines = "WIDELBL,THIS,SOFTWARE,2,C;" .. "WIDELBL,THIS,CHECK,3,C;".."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
	 scrkeys  = KEY.CLR+KEY.CNCL
	 screvents = EVT.TIMEOUT
	 timeout = ScrnTimeout
	else
	 scrlines = "WIDELBL,THIS,SOFTWARE,2,C;" .. "WIDELBL,THIS,CHECK,3,C;".."WIDELBL,THIS,PLEASE WAIT,4,C;"
	 scrkeys  = 0
	 screvents = EVT.TIMEOUT
	 timeout = ScrnTimeoutHF
	end
	local screvent,_ = terminal.DisplayObject(scrlines,scrkeys,screvents,timeout)
	if auto or screvent == "BUTTONS_1" then
	  local scrlines = "WIDELBL,,21,4,C;"
	  terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
	  local tcpreturn = tcpconnect()
	  if tcpreturn == "NOERROR" then 
		 if not auto then
		 	check_logon_ok() 
		 	return do_obj_txn_finish()
		 else return do_obj_advice_req()
		 end
	  else scrlines = "WIDELBL,THIS,NO RESPONSE,4,C;"
		screvent,_ = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)
		return do_obj_txn_finish()
	  end
	else  
		return do_obj_txn_finish()
	end
end
