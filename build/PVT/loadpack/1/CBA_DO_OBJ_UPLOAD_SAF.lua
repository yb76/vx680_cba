function do_obj_upload_saf()
  local scrlines = "WIDELBL,THIS,UPLOAD ,2,C;" .. "WIDELBL,THIS,REVERSAL/SAF,3,C;".."BUTTONS_YES,THIS,YES,B,10;"  .."BUTTONS_NO,THIS,NO,B,33;" 
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "BUTTONS_YES" or screvent == "KEY_OK" then check_logon_ok()
	do_obj_saf_rev_start()
  end
  return do_obj_txn_finish(true)
end
