function toomany_saf(amt)
	if txn and txn.toomany_saf == true or txn and txn.toomany_saf == false then
		return txn.toomany_saf
	end
	txn.toomany_saf = false
	local safmin,safmax= terminal.GetArrayRange("SAF")
	local cnt = safmax - safmin + 1
	local sumof_saf = 0
	local limit = config.saf_limit or 0
	local limit_amt = config.saf_limit_amt or 0
	if cnt > limit then txn.toomany_saf = true ;return true end
	for i=safmin,safmax-1 do
      local saffile = "SAF" .. i
      if terminal.FileExist(saffile) then
        local fld2= terminal.GetJsonValue(saffile,"2")
		sumof_saf = samof_saf + tonumber(fld2)
		end
	end
	if sumof_saf + (amt or txn.totalamt) > limit_amt then txn.toomany_saf = true; return true end
	return txn.toomany_saf
end
