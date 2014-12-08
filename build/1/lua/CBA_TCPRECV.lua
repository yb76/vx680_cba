function tcprecv()
  local rcvmsg,tcperrmsg ="",""
  local chartimeout,timeout = "2000",config.tcptimeout
  if config.tcptimeout == "" then timeout = 30 end
  local mac_ok = true
  tcperrmsg,rcvmsg = terminal.TcpRecv(chartimeout,timeout)
  if config.no_online then config.no_online = nil; tcperrmsg="COMMS ERROR" end -- TESTING
  if tcperrmsg ~= "NOERROR" and tcperrmsg ~= "NO_RESPONSE" and tcperrmsg ~= "TIMEOUT" then tcperrmsg = "NO_RESPONSE" end
  
  if #rcvmsg > 10 then rcvmsg = string.sub(rcvmsg,11) end
  if #rcvmsg > 10 then
    local mti = string.sub(rcvmsg,1,4)
    if mti ~= "9830" then -- keep MAC residue Y
	  local macvalue = string.sub(rcvmsg,-16)
	  terminal.SetIvMode("0")
	  config.mab_recv = macvalue ..terminal.Enc (macvalue,"","16",config.key_kmacs)
	  mac_ok = mac_check(rcvmsg)
    end
	txn.tcprecved = true
  end
  if not mac_ok then return "MAC",""
  else return tcperrmsg,rcvmsg end
end
