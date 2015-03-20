function do_obj_logon_resp()
  local errmsg, rcvmsg = tcprecv()
  if errmsg ~= "NOERROR" then
    txn.tcperror = true
    return do_obj_logon_nok(errmsg)
  elseif not rcvmsg or rcvmsg == "" then
    txn.tcperror = true
	return do_obj_logon_nok("NO_RESPONSE")
  else
    local msg_t = {"GET,11","GET,12","GET,13","GETS,33","GETS,39","GETS,44","GETS,47","GET,48","GET,70" }
    local errmsg,fld11,fld12,fld13,fld33,fld39,fld44,fld47,fld48,fld70 = terminal.As2805Break( rcvmsg, msg_t )
    if fld39 and #fld39>0 then txn.rc = fld39 end


    if errmsg ~= "NOERROR" then return do_obj_logon_nok(errmsg)
    elseif fld39 ~= "00" then return do_obj_logon_nok(fld39)
    elseif tonumber(fld70) == 191 then
	  if #fld48 == 448 +16 then
        config.PKspMod = string.sub(fld48, 1,  224 )
        config.PKspExp = string.sub(fld48, 225,448 )
		config.randomnumber = string.sub(fld48, -16)
		terminal.SetJsonValue( "CONFIG","PKspMod", config.PKspMod) 
		terminal.SetJsonValue( "CONFIG","PKspExp", config.PKspExp)
		terminal.SetJsonValue( "CONFIG","RANDOMNUM", config.randomnumber)
		local key_PKsp = "5"
		local ok = terminal.RsaStore( "70".."70"..config.PKspMod..config.PKspExp , key_PKsp )
	  end
      config.logonstatus = "192"
	  terminal.SetJsonValue("CONFIG","LOGON_STATUS",config.logonstatus)
      return do_obj_logon_req()
    elseif tonumber(fld70) == 192 then
	  local ekca = string.sub(fld48,1,32)
	  local eppasn = string.sub(fld48,33,64)
	  local aiic_len = string.sub(fld48,65,66)
	  local aiic = string.sub(fld48,67,67 + tonumber(aiic_len)-1)
	  config.aiic = aiic

	  local ok = terminal.Derive3Des( ekca, "", config.key_kca,config.key_ki)
	  terminal.Derive3Des( eppasn, "", config.key_tmp,config.key_ki)
	  local stmp = string.format("%032s",aiic)
      ok = ok and terminal.Owf("",config.key_kia,config.key_kca,0,stmp)
      stmp = terminal.HexToString( config.tid ).. terminal.HexToString( config.tid )
      ok = ok and terminal.Owf("",config.key_kt,config.key_kia,0,stmp)

      config.logonstatus = "001"
	  terminal.SetJsonValue("CONFIG","LOGON_STATUS",config.logonstatus)
      return do_obj_logon_req()

    elseif tonumber(fld70) == 1  then
	  
	  local data_nomac = string.sub(rcvmsg,1,#rcvmsg-16)
	  local data_mac = string.sub(rcvmsg,-16)

	  local fld48_kvc,fld48_passcode,fld48_year, fld48_advertising,fld48_stan,fld48_time,fld48_date = 
	    string.sub(fld48,1,6),
	    string.sub(fld48,7,18),
	    string.sub(fld48,19,22),
	    string.sub(fld48,23,62),
	    string.sub(fld48,63,68),
	    string.sub(fld48,69,74),
	    string.sub(fld48,75,78)
		local ktkvc= terminal.Kvc("",config.key_kt)
	  config.stan = fld48_stan 
	terminal.SetJsonValue("CONFIG","STAN",config.stan)

      config.logok = true; return do_obj_logon_ok()
    elseif tonumber(fld70) == 194  then
		local ktkvc= terminal.Kvc("",config.key_kt)
		return do_obj_txn_finish()
    else
      if config.logonstatus ~= "191" then config.logonstatus = "192" end
      return do_obj_logon_req()
    end
  end
end
