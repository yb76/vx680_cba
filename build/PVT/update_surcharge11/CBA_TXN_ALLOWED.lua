function txn_allowed(txnfunc)
  if config.txn_check_inited == nil then
	local prch,moto = terminal.GetJsonValue("CONFIG","PRCH","MOTO")
    if prch == "NO" then config.txn_prch_disabled = true end
	if moto == "NO" then config.txn_moto_disabled = true end
	config.txn_check_inited = true
  end
  
  if txnfunc == "PRCH" then return not config.txn_prch_disabled 
  elseif  txnfunc == "MOTO" then return not config.txn_moto_disabled 
  else 
    local txncfg = terminal.GetJsonValue("CONFIG",txnfunc)
	if txncfg == "NO" then return false else return true end
  end
end
