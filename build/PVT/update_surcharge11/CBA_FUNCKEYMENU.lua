function funckeymenu()
  require ("CBACONFIG")
  local scrlines = ",,40,2,C;" .. "LHIDDEN,,0,5,17,8;"					   
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,ScrnTimeout)

  if screvent == "KEY_CLR" or screvent == "CANCEL" or screvent=="TIME" then
    return do_obj_txn_finish()
  elseif screvent == "KEY_OK" then
    if scrinput == "7410" then
      return do_obj_termconfig()
    elseif scrinput == "3824" then
      return do_obj_termconfig_maintain()
    elseif scrinput == "5295" then
	  if config.tid == "" or config.mid == "" then
			local scrlines = "WIDELBL,,51,2,C;" .. "WIDELBL,,53,4,C;"
			terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
			return do_obj_txn_finish()
      else 
		return do_obj_logon_init() 
	  end
    elseif scrinput == "5296" then
	  config.logonstatus = "191"
      return do_obj_logon_init()
    elseif scrinput == "00100100" then
       return do_obj_swdownload()
	elseif scrinput == "5620" then
	  return do_obj_clear_saf()
	elseif scrinput == "5628" then
	  return do_obj_upload_saf()
    elseif scrinput == "5629" then
	  return do_obj_print_saf()
    elseif scrinput == "00200200" then
	  return do_obj_txn_reset_memory()
	elseif scrinput == "3701" then
	  terminal.CTLSEmvGetCfg()
	  return do_obj_txn_finish()
	elseif scrinput == "987654" then
	  return do_obj_txn_finish()
    else return do_obj_txn_finish()
    end
  end
end
