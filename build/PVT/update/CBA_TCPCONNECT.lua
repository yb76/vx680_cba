function tcpconnect()
  local tcperrmsg = terminal.TcpConnect( "1",config.apn,"B1","0","",config.hip,config.port,"10","4096","10000")
  return(tcperrmsg)
end
