function itaxi_above_limit( dm, limit)
  local scrlines = "WIDELBL,iTAXI_T,".. (dm == "DAY" and "140" or "141") ..",1,C;" .. "WIDELBL,iTAXI_T,142,2,C;"
                .. ",THIS," .."So far:".. string.format("%14.2f",limit/100) ..",6,4;"
  terminal.ErrorBeep()
  terminal.DisplayObject(scrlines,KEY.CNCL,EVT.TIMEOUT,ScrnErrTimeout)
  return itaxi_finish()
end
