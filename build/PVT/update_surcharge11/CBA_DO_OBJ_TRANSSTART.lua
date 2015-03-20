function do_obj_transstart()
  local scrlines = "WIDELBL,,27,2,C;" .."WIDELBL,,26,4,C;"
  terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
  local pan = txn.fullpan
  if txn.cv1 and txn.cv3 and txn.cv4 then
	trans_keys()
	local emvpin = txn.chipcard and not txn.ctls and not txn.earlyemv and not txn.emv.fallback
	txn.pinblock = terminal.PinBlockCba(config.key_card,config.key_pin,pan,"0")
  end
  return do_obj_txn_req()
end
