function do_obj_offline_check()
	local FAILED_TO_CONNECT = 3
	local ret = terminal.EmvUseHostData(FAILED_TO_CONNECT,"")
	if ret == 0 then 
		txn.rc = "Y3"
		generate_saf()
		return do_obj_txn_ok()
	else
		txn.rc = "Z3"
		return do_obj_txn_nok(txn.rc)
	end
end
