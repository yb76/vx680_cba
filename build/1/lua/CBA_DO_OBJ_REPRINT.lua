function do_obj_reprint()
  local scrlines = "WIDELBL,,37,4,C;" .. "WIDELBL,,26,6,C;"
  local prt_keep = "**DUPLICATE**\\n\\n"..terminal.GetJsonValue("DUPLICATE","RECEIPT").."\\n"
  terminal.Print(prt_keep,true)
  checkPrint(prt_keep)
  return do_obj_txn_finish()
end
