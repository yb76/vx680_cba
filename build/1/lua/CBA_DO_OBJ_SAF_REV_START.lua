function do_obj_saf_rev_start(nextstep,mode)
	saf_rev_check()
	local rev_exist = config.safsign and string.find(config.safsign,"+")
	local saf_exist = config.safsign and string.find(config.safsign,"*")
	local saf_sent,rev_sent = false,false
	local ok = true
	if (not mode or mode == "REVERSAL") and rev_exist then 
		rev_sent = do_obj_saf_rev_send("REVERSAL") 
		if(not rev_sent) then ok = false end
	end
	if (not mode or mode == "SAF") and saf_exist and ok then saf_sent = do_obj_saf_rev_send("SAF") end
	if rev_sent or saf_sent then saf_rev_check() end
	if nextstep then return nextstep()
	else return 0 end
end
