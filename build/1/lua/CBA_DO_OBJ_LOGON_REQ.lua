function do_obj_logon_req()
  if config.logonstatus == ""  or config.logonstatus == "191" then
	config.logonstatus = "191"
	terminal.SetJsonValue("CONFIG","LOGON_STATUS",config.logonstatus)
  end

   local fld48 = ""
   local msg_flds = {}
   if config.logonstatus == "191" then
	  local SKmanPKtcuMOD, SKmanPKtcuEXP = terminal.GetJsonValue("CONFIG","SKmanPKtcuMOD","SKmanPKtcuEXP")
      fld48 = SKmanPKtcuMOD .. SKmanPKtcuEXP .. config.ppid
	  msg_flds = {"0:9820","11:"..config.stan, "41:"..config.tid, "42:"..config.mid, "48:"..fld48, "63:".."33","70:".. config.logonstatus}
   elseif config.logonstatus == "192" then
      local ok,kivalue = terminal.DesRandom("16",config.key_ki)
	  local randomnumber = ""
	  if config.randomnumber then randomnumber = config.randomnumber else terminal.GetJsonValue ("CONFIG","RANDOMNUM", randomnumber ) end
  	  local timestr = terminal.Time( "YYDDMMhhmmss" ) 
	  local block = kivalue .. config.ppid .. timestr .. randomnumber

	  --sSKTCU (ePKSP (KI, PPID, DTS, RN))
	  local key_PKsp, key_SKtcu = terminal.GetJsonValue("IRIS_CFG","PKSP","SKTCU")
      local block1 = terminal.RsaEncrypt( block, key_PKsp, 112 )
	  if not config.SKtcu then
	  	local sktcu = terminal.GetJsonValue("CONFIG","SKtcu" )
	  	if sktcu ~= "" then terminal.RsaStore( sktcu,key_SKtcu ) end
		config.SKtcu = sktcu
	  end
      fld48 = terminal.RsaEncrypt( block1, key_SKtcu, 120 ) .. config.ppid -- SKtcu stored in slot 4
	  msg_flds = {"0:9820","11:"..config.stan, "41:"..config.tid, "42:"..config.mid, "48:"..fld48, "63:".."33","70:".. config.logonstatus}
   elseif config.logonstatus == "001" then
	  
	  local ok = terminal.Xor3Des( config.key_kt_x, config.key_kt, "","24C024C024C024C0")
	  terminal.DesStore("0123456789ABCDEF","8", config.key_tmp)
	  ok = terminal.Owf(config.key_tmp,config.key_kmacs,config.key_kt_x,0)

      fld48 = config.ppid .. string.sub(terminal.Enc (config.ppid,"","16",config.key_kia),1,8)
	  local fld47 = terminal.HexToString("TCC07\\");
	  msg_flds = {"0:0800","11:"..config.stan, "33:"..config.aiic,"41:"..config.tid, "42:"..config.mid, "47:".. fld47, "48:"..fld48, "70:".. config.logonstatus,"128:KEY="..config.key_kmacs}
   elseif config.logonstatus == "194" then
	  fld48 = string.sub( terminal.Enc (config.ppid,"","16",config.key_kia),1,8)
	  msg_flds = {"0:9820","11:"..config.stan, "41:"..config.tid, "42:"..config.mid, "48:"..fld48, "70:".. config.logonstatus}
   end

    local as2805msg = terminal.As2805Make( msg_flds)
    local retmsg = ""
    if as2805msg ~= "" then retmsg = tcpsend(as2805msg) end
    if retmsg ~= "NOERROR" then txn.tcperror = true; return do_obj_logon_nok(retmsg)
    else return do_obj_logon_resp() end
end
