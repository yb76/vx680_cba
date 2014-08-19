function itaxi_meter()
  local meteramt = taxi.meter or 0
    local scrlines = "WIDELBL,iTAXI_T,93,2,C;" .. "AMOUNT," .. meteramt ..",5,5,C,9,1;"
  local scrkeys = KEY.OK+KEY.CNCL+KEY.CLR
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" then
    taxi.meter = tonumber(scrinput)
    return itaxi_other_charges()
  elseif screvent == "KEY_CLR" then
    taxi.meter = 0
    return itaxi_dropoff()
  else
    return itaxi_finish()
  end
end
