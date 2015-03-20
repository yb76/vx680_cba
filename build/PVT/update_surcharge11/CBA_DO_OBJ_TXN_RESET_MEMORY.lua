function do_obj_txn_reset_memory()
  local scrlines = "WIDELBL,THIS,RESET MEMORY?,2,C;".."WIDELBL,,73,3,C;"
  local screvent,_=terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" then 
	local fmax,fmin = 0,0
	local scrlines = "WIDELBL,,27,2,C;" .."WIDELBL,,26,4,C;"
	terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
	terminal.SetJsonValue("CONFIG","BATCHNO", "000000")
	config.logonstatus = "191"
	terminal.SetJsonValue("CONFIG","LOGON_STATUS",config.logonstatus)
	config.stan = "000001"
	terminal.SetJsonValue("CONFIG","STAN",config.stan)
	config.roc = "000000"
	terminal.SetJsonValue("CONFIG","ROC",config.roc)
	config.tid = ""
	terminal.SetJsonValue("CONFIG","TID","")
	config.mid = ""
	terminal.SetJsonValue("CONFIG","MID","")
	terminal.SetJsonValue("iPAY_CFG","TID","")
	terminal.SetJsonValue("iPAY_CFG","MID","")
	terminal.SetJsonValue("DUPLICATE","RECEIPT","")
	fmin,fmax = terminal.GetArrayRange("TAXI")
	for i=fmin,fmax-1 do terminal.FileRemove("TAXI"..i) end
	terminal.SetArrayRange("TAXI","0","0")
	fmin,fmax = terminal.GetArrayRange("SAF")
	for i=fmin,fmax-1 do terminal.FileRemove("SAF"..i) end
	terminal.SetArrayRange("SAF","0","0")
	fmin,fmax = terminal.GetArrayRange("REVERSAL")
	for i=fmin,fmax-1 do terminal.FileRemove("REVERSAL"..i) end
	terminal.SetArrayRange("REVERSAL","0","0")
	terminal.FileRemove("SHFTSTTL")
	scrlines = "LARGE,THIS,RESET MEMORY,2,C,;".."LARGE,THIS,SUCCESS,3,C,;"
	terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,ScrnErrTimeout)--AR Timeout
	config.logok = false
  end
  return do_obj_txn_finish()
end
