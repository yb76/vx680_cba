function do_obj_advice_start(auto)
	local scrlines = "WIDELBL,THIS,SOFTWARE,2,C;" .. "WIDELBL,THIS,CHECK,3,C;".."WIDELBL,THIS,PLEASE WAIT,4,C;"
	terminal.DisplayObject(scrlines,0,EVT.TIMEOUT,ScrnTimeoutHF)
	tcpconnect()
	return do_obj_advice_req()
end
