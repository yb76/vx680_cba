function do_obj_cba_swipe_insert()
	txn.emv = {}
	local ok = 0
	
	if txn.ctls == "CTLS_E" then
		txn.chipcard = true
		txn.cvmlimit = ecrd.CVMLIMIT
	elseif txn.chipcard then 
		ok = emv_init()
	end
	if ok ~= 0 then 
		return do_obj_emv_error(ok)
	else 
		if ecrd.FUNCTION then 
			local func = txn.func
			check_logon_ok() 
			txn.func = func
		end
		return do_obj_prchamount()
	end
end
