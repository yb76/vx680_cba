function do_obj_print_saf()
  local scrlines = "WIDELBL,THIS,PRINT ,2,C;" .. "WIDELBL,THIS,REVERSAL/SAF,3,C;".."BUTTONS_YES,THIS,YES,B,10;"  .."BUTTONS_NO,THIS,NO,B,33;" 
  local screvent = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "BUTTONS_YES" or screvent == "KEY_OK" then
	local screvent=""
	local revmin,revmax= terminal.GetArrayRange("REVERSAL")
	local safmin,safmax= terminal.GetArrayRange("SAF")
	if revmax == revmin and safmax == safmin then 
		local scrlines = "WIDELBL,THIS,REVERSAL/SAF,5,C;" .. "WIDELBL,THIS,EMPTY,7,C;"
		terminal.DisplayObject(scrlines,KEY.CNCL,EVT.TIMEOUT,ScrnTimeout)
	else
		local prtvalue= "\\C\\HSAF/REVERSAL LIST\\n" ..
			"\\4\\w------------------------------------------\\n" ..
			"\\fMERCHANT ID:\\R" .. string.sub(config.mid,-8) .. "\\n" ..
			"\\fTERMINAL ID:\\R" .. config.tid .. "\\n\\n" ..
			"\\fTYPE\\RROC/INV\\n"

		local fname = "REVERSAL"
		if terminal.FileExist(fname..revmin) then
			local roc = terminal.GetJsonValue(fname..revmin,"ROC")
			prtvalue = prtvalue .."\\3REVERSAL".."\\R"..roc.."\\n"
		end

		fname = "SAF"
		for i=safmin,safmax-1 do
			if terminal.FileExist(fname..i) then
				local roc = terminal.GetJsonValue(fname..i,"ROC")
				prtvalue = prtvalue .."\\fSAF".."\\R"..roc.."\\n"
			end
		end
		terminal.Print(prtvalue,true)
	end
  end
  return do_obj_txn_finish(true)
end
