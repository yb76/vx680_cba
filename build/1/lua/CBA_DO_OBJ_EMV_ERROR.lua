function do_obj_emv_error(emvstat)
  local scrlines,linestr="",""
  local gemv_techfallback = terminal.EmvGlobal("GET","TECHFALLBACK")
  local screvents = EVT.TIMEOUT
  local scrkeys = KEY.OK+KEY.CNCL

  if terminal.EmvIsCardPresent() then
	linestr = "WIDELBL,THIS,REMOVE CARD,4,C;"
	screvents = EVT.SCT_OUT 
	scrkeys = 0
  end
  if gemv_techfallback and emvstat == 146 then
	  txn.emverr = emvstat
  elseif gemv_techfallback and not txn.emv_retry then txn.emv_retry = true
    linestr = "WIDELBL,THIS,PLEASE RETRY,4,C;"; txn.emv.fallback = false
  elseif gemv_techfallback then 
	  txn.emv.fallback = true;linestr = "WIDELBL,THIS,USE FALLBACK,4,C;" 
  end

  if emvstat == 157 then scrlines = "WIDELBL,THIS,NO ATR,2,C;" ..linestr
  elseif emvstat==101 then scrlines="WIDELBL,,277,2,C;"..linestr
  elseif emvstat==103 then scrlines="WIDELBL,,283,2,C;"..linestr
  elseif emvstat==106 then scrlines="WIDELBL,,282,2,C;"..linestr
  elseif emvstat==107 then scrlines="WIDELBL,,276,2,C;"..linestr
  elseif emvstat==108 then scrlines="WIDELBL,,281,2,C;"..linestr
  elseif emvstat==112 then scrlines="WIDELBL,,273,2,C;".."WIDELBL,,274,4,C;"..linestr
  elseif emvstat==113 then scrlines="WIDELBL,,276,2,C;".."WIDELBL,,274,4,C;"..linestr
  elseif emvstat==114 or emvstat==119 then scrlines="WIDELBL,,276,2,C;".."WIDELBL,,272,4,C;"..linestr
  elseif emvstat==116 then scrlines="WIDELBL,,120,2,C;"..linestr
  elseif emvstat==118 then scrlines="WIDELBL,,275,2,C;".."WIDELBL,,274,4,C;"..linestr
  elseif emvstat==125 then scrlines="WIDELBL,,285,2,C;"..linestr
  elseif emvstat==146 then 
  else scrlines="WIDELBL,,276,2,C;"..linestr
  end
  terminal.ErrorBeep()
  if emvstat~=146 then terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnErrTimeout) end
  if gemv_techfallback then return do_obj_swipecard()
  else return do_obj_txn_finish() end 
end
