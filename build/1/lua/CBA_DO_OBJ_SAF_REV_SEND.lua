function do_obj_saf_rev_send(fname)
  local safmin,safmax= terminal.GetArrayRange(fname)
  if safmin == safmax then return true
  else
  terminal.DebugDisp("boyang....rev send...1")
    local txnbak = txn
    local msg_flds = {}
    local scrlines_saf = "WIDELBL,THIS,SENDING SAF,2,C,;" .."WIDELBL,,26,3,C,;"
	local scrlines_rev = "WIDELBL,THIS,SENDING REVERSAL,2,C,;" .."WIDELBL,,26,3,C,;"
    local retmsg = "NOERROR"
	local ok = false
    for i=safmin,safmax-1 do
	terminal.DebugDisp("boyang....rev send...2")
      local saffile = fname .. i
      if terminal.FileExist(saffile) then
		ok = false
        local errmsg,fld0,fld2,fld3,fld4,fld11,fld12,fld13,fld14,fld15,fld22,fld23,fld24,fld25,fld32,fld35,fld37,fld38,fld41,fld39,fld42,fld44,fld47,fld54,fld55,fld48,fld64,fld90,roc
		local sent = false
        fld0,fld2,fld3,fld4,fld11,fld12,fld13,fld14,fld22,fld23,fld24,fld25,fld32,fld35,fld37,fld38,fld39,fld41,fld42,fld47,fld54,fld55,fld90,roc,sent =
          terminal.GetJsonValue(saffile,"0","2", "3", "4", "11","12","13", "14", "22", "23", "24", "25", "32", "35", "37","38","39","41", "42", "47", "54", "55","90","ROC","SENT")
		local msg_flds = {}
        if fname == "REVERSAL" then 
		terminal.DebugDisp("boyang....rev send...3")
			if sent ~= "YES" then 
				fld90 = string.format("%04s",fld0)..string.format("%06s",fld11)..string.rep("0",32)
				fld11 = config.stan 
				terminal.SetJsonValue(saffile,"11",fld11)
				terminal.SetJsonValue(saffile,"90",fld90)
			end
			--fld0 = (sent == "YES" ) and "421" or "420" --boyang
			fld0 = "420"
			terminal.DisplayObject(scrlines_rev,0,0,ScrnTimeoutZO)
        	msg_flds = {"0:"..fld0,"2:"..fld2,"3:"..fld3,"4:"..fld4,"11:"..fld11,"14:"..fld14,"22:"..fld22,"23:"..fld23,"35:"..fld35,"41:"..fld41,"42:"..fld42,"47:"..fld47,"54:"..fld54,"55:"..fld55, "90:"..fld90, "128:KEY="..config.key_kmacs}
		else
			fld48 = terminal.HexToString("SAF")
			fld0 = "220"
			terminal.DisplayObject(scrlines_saf,0,0,ScrnTimeoutZO)
        	msg_flds = {"0:"..fld0,"2:"..fld2,"3:"..fld3,"4:"..fld4,"11:"..config.stan,"12:"..fld12,"13:"..fld13,"14:"..fld14,"22:"..fld22,"23:"..fld23,"25:"..fld25,"35:"..fld35,"38:"..fld38,"39:"..fld39,"41:"..fld41,"42:"..fld42,"47:"..fld47,"48:"..fld48,"54:"..fld54,"55:"..fld55, "64:KEY="..config.key_kmacs}
		end

		local cv1 = ""
		terminal.DebugDisp("boyang...fld2:["..fld2.."]")
		terminal.DebugDisp("boyang...fld35:["..fld35.."]")
		_,cv1 = get_trans_cv2(#fld2 >10 and fld2 or #fld35 > 10 and fld35 or "0123456789ABCDEF")
		terminal.DesStore(cv1,"8", config.key_tmp)
		terminal.Owf(config.key_tmp,config.key_kmacs,config.key_kt_x ,0)

		terminal.DebugDisp("boyang....rev send...4")
        local as2805msg = terminal.As2805Make(msg_flds)
		--if sent == "YES" then as2805msg = string.sub(as2805msg,1,3).."1"..string.sub(as2805msg,5) end --boyang
		debugPrint(as2805msg)
		retmsg = tcpconnect() 
        if retmsg == "NOERROR" and as2805msg ~= "" then retmsg = tcpsend(as2805msg) end
		terminal.SetJsonValue(saffile,"SENT","YES")
        if retmsg ~= "NOERROR" then break end
        as2805msg = ""
        retmsg,as2805msg = tcprecv()
        if retmsg ~= "NOERROR" then break end
		if not as2805msg or as2805msg == "" then break end
        local msg_t = { "GET,12","GET,13", "GET,15","IGN,24","GETS,39","GETS,44","GETS,47","GETS,48","GETS,64" }
        if as2805msg ~= "" then
		  errmsg,fld12,fld13,fld15,fld39,fld44,fld47,fld48,fld55,fld64 = terminal.As2805Break( as2805msg, msg_t )
		  if fld39 == "98" then  terminal.DebugDisp("boyang....rev send...5"); config.logok = false ; check_logon_ok() end	
          if fld39 ~= "00" and fld39 ~= "21" then break end
          terminal.FileRemove(fname..i)
          terminal.SetArrayRange(fname,tostring(i+1),"")
		  ok = true
		end
      end
    end
	if ok then saf_rev_check() end
	txn = txnbak
	return ok
  end
end
