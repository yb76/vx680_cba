function do_obj_shft_reset()
  local scrlines = "WIDELBL,,37,4,C,;" .. "WIDELBL,,26,6,C,;"
  local screvent,scrinput = terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
  local doubleh=""
  local prtvalue=""
  if ecrd.HEADER then prtvalue = ecrd.HEADER else doubleh = "\\h" end
  local mytime2=terminal.Time("DD/MM/YY  hh:mm")
  local prchamt,cashamt,tipsamt,rfndamt,prchnum,cashnum,tipsnum,rfndnum= terminal.GetJsonValueInt("SHFT","PRCHAMT","CASHAMT","TIPSAMT","RFNDAMT","PRCHNUM","CASHNUM","TIPSNUM","RFNDNUM")
  prchamt=prchamt/100
  cashamt=cashamt/100
  tipsamt=tipsamt/100
  rfndamt=rfndamt/100
  local value="\\C\\f"..doubleh.."------------------------\\n\\C" ..config.servicename.."\\n"..
    "\\C" .. config.merch_loc0 .."\\n" ..
    "\\C" .. config.merch_loc1 .."\\n\\n" ..
    "MERCHANT ID:\\R"..string.sub(config.mid,-8).."\\n" ..
    "TERMINAL ID:\\R"..config.tid.."\\n\\n"..
	"DATE:\\R"..mytime2.."\\n\\n"..
    "SHIFT TOTALS\\R\\n"..
    "------------------------\\n"..
    "PURCHASE ".. string.format("%03s",prchnum) .."\\R".. string.format("$%.2f",prchamt).."\\n"..
    "------------------------\\n"
    ecrd.BODY = value
	prtvalue = prtvalue .. value ..(ecrd.TRAILER or "") .."\\n"
	terminal.Print(prtvalue,true);
	checkPrint(prtvalue)
    terminal.FileRemove("SHFT")
  return do_obj_txn_finish(true)
end
