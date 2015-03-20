function check_efb()
	if not config.efb then return false end
	if  toomany_saf() then return false end
	if txn.emv and txn.emv.expdate and #txn.emv.expdate == 6 then
		local currdate = terminal.Time( "YYMMDD") 
		if tonumber(currdate) > tonumber(txn.emv.expdate) then
			return false
		end
	end
	if txn.chipcard and not txn.earlyemv and not txn.emv.fallback and not txn.ctls then --chip
		return false
	elseif txn.track2 then
		return true
	elseif txn.ctls == "CTLS_E" or txn.ctls == "CTLS_S" then
		local expdate = get_value_from_tlvs("5F24")
		local currdate = terminal.Time( "YYMMDD") 
		if #expdate == 6 and tonumber(currdate) > tonumber(expdate) then
			return false
		end
		local EMV9f06 = get_value_from_tlvs("9F06")
		if EMV9f06 == "" then EMV9f06 = get_value_from_tlvs("8400") end
		local tlimit,climit,flimit = terminal.CTLSEmvGetLimit(EMV9f06)
		if flimit > 0 and txn.totalamt >flimit then return false end
		return true
	elseif txn.emv.fallback then
		return true
	elseif txn.earlyemv then
		return true
	end
end
