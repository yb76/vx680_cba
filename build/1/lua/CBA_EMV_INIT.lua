function emv_init()
  local ok = 0
  if txn.chipcard then
	ok = terminal.EmvTransInit()
	local amt,acctype = ecrd.AMT,0
    if ok == 0 then ok = terminal.EmvSelectApplication(amt,acctype) end
    if ok ~= 0 and ok ~= 103 --[[CARD_REMOVED]] and ok ~= 104 --[[CARD_BLOCKED]] and ok ~= 105 --[[APPL_BLOCKED]] and ok ~= 110 --[[TRANS_CANCELLED]] and ok ~= 130 --[[INVALID_PARAMETER]] then
      txn.emv.fallback = true
    end
  end
  return ok
end
