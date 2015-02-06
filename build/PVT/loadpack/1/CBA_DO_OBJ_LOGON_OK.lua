function do_obj_logon_ok()
  if txn.manuallogon then
    local timestr = terminal.Time( "DD/MM/YY hh:mm" )
    local scrlines = "WIDELBL,,35,4,C;"
    local screvent,scrinput = terminal.DisplayObject(scrlines,0,0,0)
    local prtdata = "\\C\\H" .. config.servicename .."\\n\\n" ..
                  "\\C" .. config.merch_loc0 .."\\n" ..
                  "\\C" .. config.merch_loc1 .."\\n" ..
                  "\\CBANK LOGON\\n\\n" ..
                  "MERCHANT ID:\\R" .. string.sub(config.mid,-8) .. "\\n" ..
                  "TERMINAL ID:\\R" .. config.tid .."\\n" ..
                  "DATE/TIME:\\R" .. timestr .. "\\n" ..
                  "BANK REF:\\R" .. string.format("%06d",txn.stan).. "\\n" ..
                  "APPROVED\\R00\\n" ..
				  "\\4------------------------------------------\\n"
    terminal.Print(prtdata,true)
    checkPrint(prtdata)
  end
  return do_obj_advice_start(true)
end
