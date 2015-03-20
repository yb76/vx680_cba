function tcpsend(msg)
  local tcperrmsg = ""
  tcperrmsg = terminal.TcpSend("6000013000"..msg)
  txn.tcpsent = true
  txn.stan = config.stan
  if config.stan == nil or config.stan == "" or tonumber(config.stan) >= 999999 then config.stan = "000001"
  else config.stan = string.format("%06d",tonumber(config.stan) + 1) end
  terminal.SetJsonValue("CONFIG","STAN",config.stan)
  local mti = string.sub(msg,1,4)
  if true or mti ~= "9820" then -- keep MAC residue X
	local macvalue = string.sub(msg,-16)
	terminal.SetIvMode("0")
	config.mab_send = macvalue ..terminal.Enc (macvalue,"","16",config.key_kmacs)
  end

  return(tcperrmsg)
end
