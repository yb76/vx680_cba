function do_obj_logon_nok(errormsg)
  local result,rcpttxt,disptxt = "",errormsg,errormsg
  if errormsg and #errormsg == 2 then result = "DECLINED"; rcpttxt = cba_errorcode("H"..errormsg); disptxt = rcpttxt
  else result= "CANCELLED" end

  local scrlines = "WIDELBL,THIS,LOGON "..result..",4,C;".."WIDELBL,THIS,"..disptxt..",6,C;"
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL+KEY.CLR,EVT.TIMEOUT,ScrnErrTimeout)--AR Timeout

  local timestr = terminal.Time( "DD/MM/YY hh:mm" )
  result = "\\n" ..result .. "\\R" ..(errormsg or "") .."\\n"

  if rcpttxt ~= errormsg then  result = result .. "\\R" .. rcpttxt .."\\n" end
  local prtdata = "\\C\\H" .. config.servicename .."\\n\\n" ..
                  "\\C" .. config.merch_loc0 .."\\n" ..
                  "\\C" .. config.merch_loc1 .."\\n" ..
                  "\\CBANK LOGON\\n\\n" ..
                  "MERCHANT ID:\\R" .. string.sub(config.mid,-8) .. "\\n" ..
                  "TERMINAL ID:\\R" .. config.tid .."\\n" ..
                  "DATE/TIME:\\R" .. timestr .. "\\n" ..
                  "BANK REF:\\R" .. string.format("%06d",txn.stan or 0).. "\\n" ..
                  "PPID:\\R" .. config.ppid .. "\\n" ..
				  result .. "\\n" ..
				  "\\4------------------------------------------\\n"
  terminal.Print(prtdata,true)
  checkPrint(prtdata)
  if config.logok then config.logok = false end
  return do_obj_txn_finish()
end
