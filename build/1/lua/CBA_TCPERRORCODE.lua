function tcperrorcode(errmsg)
  txn.tcperror = true
  local pstnerr_t = {LINE="W1",ANSWER="W2",BUSY="W3",NOPHONENUM="W4",CARRIER="W6",HOST="W6",SOCKET="W7",
               SHUTDOWN="W8",DHCP="W9",PPP_AUTH="W10",PPP_LCP="W11",IPCP="W12",ETH_SND_FAIL="W13",
               ETH_RCV_FAIL="W14",BATTERY="W15",COVERAGE="W16",SIM="W17",NETWORK="W18",PDP="W19",SIGNAL="W20",
               CONNECT="W21",GENERAL="W22",RCV_FAIL="W23",TIMEOUT="W24",ITIMEOUT="W25",MAC="W26",RCV_FAIL="W27",SND_FAIL="W28",
			   NO_RESPONSE="W29"
			   }
  pstnerr_t["SAF LIMIT EXCEEDED"] = "W30"
  pstnerr_t["CVM FALIED"] = "W31"
  pstnerr_t["REVERSAL PENDING"] = "W32"
  return(pstnerr_t[errmsg])
end
