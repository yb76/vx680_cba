function itaxi_ctls_tran()
    local amt = taxi.subtotal+taxi.serv_gst
    local translimit,cvmlimit=0,0
    local nosaf = 0
    local tr1,tr2,tlvs,emvres = terminal.CtlsCall(0,amt,nosaf)

    if tr2 ~= "" then
        if taxicfg.ctls_slimit > 0 and amt > taxicfg.ctls_slimit then tr2 = ""; emvres = "-1025"; end
    elseif tlvs ~= "" then
        local aid = get_value_from_tlvs("9F06",tlvs)
        translimit,cvmlimit =terminal.CTLSEmvGetLimit(aid)
        --if string.sub(aid,1,10)=="A000000003" and amt >= translimit or amt > translimit then tlvs = ""; emvres = "-1025" end
        --taxi.cvmlimit = cvmlimit
    end

    local safexceed = (nosaf ==1 and tonumber(emvres) == 0)
	if tr2 ~= "" then
        if not safexceed then
            local scrlines1 = "WIDELBL,THIS,PROCESSING..,3,C;" .. "WIDELBL,THIS,PLEASE WAIT,5,C;"
            terminal.DisplayObject(scrlines1,0,EVT.TIMEOUT,500)
        end
        taxi.ctls = "CTLS_S"
        taxi.tlvs = tlvs
        taxi.track2 = tr2
        return itaxi_pay_swipe()
    elseif tlvs ~= "" then
        taxi.CTemvrs = emvres
        if not safexceed then
            local scrlines1 = "WIDELBL,THIS,PROCESSING..,3,C;" .. "WIDELBL,THIS,PLEASE WAIT,5,C;"
            terminal.DisplayObject(scrlines1,0,EVT.TIMEOUT,500)
        else
            taxi.CTemvrs = "W30"
        end
        taxi.ctls = "CTLS_E"
        taxi.tlvs = tlvs
        taxi.chipcard = true 
        return itaxi_pay_swipe()        
    elseif emvres == "99" or emvres == "10" or emvres =="-1025" then 
        if emvres == "-1025" then terminal.DisplayObject("WIDELBL,THIS,NO CONTACTLESS,3,C;".. 
          "WIDELBL,THIS,FOR AMOUNT >".. string.format("%.2f",translimit/100.0) ..",5,C;",KEY.OK,EVT.TIMEOUT,2000) end
        return itaxi_paymentmethod()
    elseif emvres == "-1001" or emvres =="-1002" then 
		if emvres == "-1001" then taxi.track2 = terminal.GetTrack(2) else taxi.chipcard = true end
		return itaxi_pay_swipe()
	else
        terminal.ErrorBeep()
        if emvres == "-13" then
            if terminal.EmvIsCardPresent() then terminal.DisplayObject("WIDELBL,THIS,REMOVE CARD,3,C;",0,EVT.SCT_OUT,0)
            else    terminal.DisplayObject("WIDELBL,THIS,TRAN CANCELLED,3,C;",0,EVT.TIMEOUT,500)
            end
        else    terminal.DisplayObject("WIDELBL,THIS,CARD ERROR,3,C;",0,EVT.TIMEOUT,500)
        end
        return itaxi_finish() 
    end
end
