-------------------iTAXI----------------------------------------------
taxi = {}
taxicfg = {}

function itaxi_startup()
  if not taxicfg.signed_on then taxi.finishreturn = true; itaxi_chk_signon(); taxi.finishreturn = false end
  if not taxicfg.registered then taxicfg.registered = true; do_obj_gprs_register() end
  return 0
end

function itaxi_chk_signon()
  if taxicfg.taxi_no == "" then return itaxi_sign_on() 
  else taxicfg.signed_on = true; return itaxi_finish() end
end

function itaxi_sign_on()
  local scrlines = "WIDELBL,iTAXI_T,160,3,C;" .. "WIDELBL,iTAXI_T,161,4,C;"..",THIS,PRESS GREEN KEY,7,C;"..",THIS,TO CONTINUE,8,C;"
                   .. "BUTTONL_1,THIS,SIGN-ON,B,C;" 
  terminal.DisplayObject(scrlines,KEY.OK,0,0)
  return itaxi_auth_no()
end

function itaxi_auth_no()
  local scrlines = ",THIS,AUTHORITY NO,4,C;" .. "STRING," .. taxicfg.auth_no .. ",,6,15,10,1;".."BUTTONA,THIS,ALPHA ,B,C;"
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,ScrnTimeout)
  
  if screvent == "KEY_OK" then
    taxicfg.auth_no = scrinput
    terminal.SetJsonValue("iTAXI_CFG","AUTH_NO",taxicfg.auth_no)
    return itaxi_abn_no()
  else
    return itaxi_sign_on()
  end
end

function itaxi_abn_no()
 local scrlines = ",THIS,ENTER ABN,4,C;" .. "LNUMBER," .. taxicfg.abn_no .. ",0,7,14,11,11;"
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL+KEY.CLR,EVT.TIMEOUT,ScrnTimeout)
  
  if screvent == "KEY_OK" then
    taxicfg.abn_no = scrinput
    terminal.SetJsonValue("iTAXI_CFG","ABN_NO",taxicfg.abn_no)
    --return itaxi_taxi_no()
    return itaxi_select_driver()
  elseif screvent == "KEY_CLR" then
    return itaxi_auth_no()
  else
    return itaxi_sign_on()
  end
end

function itaxi_taxi_no()
  local scrlines = ",THIS,ENTER "..(taxicfg.hire and "HIRE CAR NO" or "TAXI NO")..",4,C;" .. "STRING," .. taxicfg.taxi_no .. ",,7,14,10,1;".."BUTTONA,THIS,ALPHA ,B,C;"
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL+KEY.CLR,EVT.TIMEOUT,ScrnTimeout)
  
  if screvent == "KEY_OK" then
    terminal.SetJsonValue("iTAXI_CFG","TAXI_NO",scrinput)
    taxicfg.taxi_no = scrinput
    taxicfg.signed_on = true
    return itaxi_finish()
  elseif screvent == "KEY_CLR" then
    return itaxi_abn_no()
  else
    return itaxi_sign_on()
  end
end

function itaxi_select_driver()
  taxicfg.serv_gst,taxicfg.comm = terminal.GetJsonValueInt("iTAXI_CFG","SERV_GST","COMM") -- this might have been switched to hire car value
  if taxicfg.h_comm == 0 then taxicfg.h_comm = 300 end
  if taxicfg.h_serv_gst == 0 then taxicfg.h_serv_gst = 1100 end
  local line1 = "TAXI DRIVER"
  local line2 = "HIRE CAR DRIVER"
  local line1txt = "SERVICE FEE:"..tostring(taxicfg.serv_gst/100.0).."%"
  local line2txt = "SERVICE FEE:"..tostring(taxicfg.h_serv_gst/100.0).."%"
  local scrlines = ",THIS,ENTER DRIVER TYPE,1,C;" .. "BUTTONL_1,THIS,"..line1..",P113,C;"..",THIS,"..line1txt..",6,C;".. "BUTTONL_2,THIS,"..line2..",P236,C;"..",THIS,"..line2txt..",12,C;"
  local scrkeys = KEY.CNCL
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  taxicfg.hire = nil
  if screvent == "BUTTONL_1" then
    terminal.SetJsonValue("iTAXI_CFG","DRIVERTYPE","TAXI")
    return itaxi_taxi_no()
  elseif screvent == "BUTTONL_2" then
	taxicfg.comm = taxicfg.h_comm
	taxicfg.serv_gst = taxicfg.h_serv_gst
    terminal.SetJsonValue("iTAXI_CFG","DRIVERTYPE","HIRE")
	taxicfg.hire = true
    return itaxi_taxi_no()
  else
    return itaxi_sign_on()
  end
end
function itaxi_swipe_insert()
  local nextstep = itaxi_pickup
  taxi = {}
  if common.track2 then
    taxi.track2 = common.track2 
    local swipeflag,cardname = swipecheck(taxi.track2)
    if swipeflag < 0 then 
      nextstep = itaxi_finish 
    elseif swipeflag == 0 then
      local scrlines = "WIDELBL,THIS,INSERT CARD,4,C;"
      local screvent = terminal.DisplayObject(scrlines,KEY.CNCL,EVT.TIMEOUT+EVT.SCT_IN,ScrnTimeout)
      if screvent ~= "CHIP_CARD_IN" then nextstep = itaxi_finish 
      else common.entry = "CHIP" end
    else taxi.cardname = cardname
    end
  end
  if common.entry == "CHIP" then 
    local retval = terminal.EmvTransInit()
    if retval ~= 0 then 
        terminal.ErrorBeep()
        local scrlines1="WIDELBL,THIS,CARD ERROR,2,C;" .. "WIDELBL,THIS,REMOVE CARD,4,C;"
        terminal.DisplayObject(scrlines1,0,EVT.SCT_OUT,0)
        nextstep = itaxi_finish
    else
        taxi.chipcard = true 
    end
  elseif common.entry == "CTLS" then taxi.ctls = "CTLS"
  end
  
  if nextstep ~= itaxi_finish then
    local inv,lastinv=taxicfg.inv, taxicfg.last_inv
    if tonumber(inv)-tonumber(lastinv)> taxicfg.max_txn then 
      terminal.ErrorBeep()
      local scrlines = "WIDELBL,THIS,SIGN OFF then ON,3,C;".."WIDELBL,THIS,THEN RETRY,4,C;".."WIDELBL,THIS,TRANSACTION,5,C;"
      local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,ScrnErrTimeout)
      nextstep = itaxi_finish
    end
  end
  return nextstep()
end

function itaxi_finish()
  if taxi.chipcard then terminal.EmvPowerOff()
    if terminal.EmvIsCardPresent() then
        local scrlines = "WIDELBL,,286,2,C;"
        terminal.DisplayObject(scrlines,0,EVT.SCT_OUT,0)
    end
  end
  if taxi.finishreturn then return taxi.finishreturn
  else 
    if taxi.reconnect then do_obj_gprs_register() end
    taxi = {};  common = {}; return do_obj_idle() 
  end
end

function itaxi_fmenu()
  local scrlines = "BUTTONL_1,THIS,CASH RECEIPT,P40,C;" .. "BUTTONL_2,iTAXI_T,73,P110,C;".. "BUTTONL_3,iTAXI_T,75,P180,C;".."BUTTONL_4,THIS,SEND TRANS,P250,C;"
  local scrkeys = KEY.CNCL+KEY.FUNC
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  taxi = {}
  
  if screvent == "BUTTONL_1" then
    taxi.cash = true
    return itaxi_pickup()
  elseif screvent == "BUTTONL_2" then
    return itaxi_reprint_menu()
  elseif screvent == "BUTTONL_3" then
    return itaxi_totals()
  elseif screvent == "BUTTONL_4" then
    itaxi_update()
    do_obj_gprs_register()
	return itaxi_finish()
  elseif screvent == "KEY_FUNC" then
    local pwd = terminal.GetJsonValue("IRIS_CFG","SETUP_PWD")
	if pwd == "" then pwd = "893701" end
    if check_pwd(pwd) then  return itaxi_smenu()
	else return itaxi_finish() end
  else
    return itaxi_finish()
  end
end

function itaxi_pickup()
  local nextstep = itaxi_dropoff
  if txn_allowed("PRCH") then
      if not taxicfg.pickup_scr then
        local loc0,loc1,loc2,loc3,loc4,loc5 = taxicfg.loc0,taxicfg.loc1,taxicfg.loc2,taxicfg.loc3,taxicfg.loc4,taxicfg.loc5
        local scrlines = "WIDELBL,THIS,PICK UP FROM,-1,C;" .. "BUTTONM_0,THIS,"..loc0..",2,C;" .. "BUTTONM_1,THIS," ..loc1..",4,C;" 
        .. "BUTTONM_2,THIS,"..loc2..",6,C;" .. "BUTTONM_3,THIS,"..loc3..",8,C;" .. "BUTTONM_4,THIS,"..loc4..",10,C;"
        .. "BUTTONM_5,THIS,"..loc5..",12,C;"
        taxicfg.pickup_scr = scrlines
      end

      local scrkeys = KEY.CNCL
      local screvents = EVT.TIMEOUT
      local screvent,scrinput = terminal.DisplayObject(taxicfg.pickup_scr,scrkeys,screvents,ScrnTimeout)
        
      if screvent == "BUTTONM_0" then
        taxi.pickup = taxicfg.loc0
      elseif screvent == "BUTTONM_1" then
        taxi.pickup = taxicfg.loc1
      elseif screvent == "BUTTONM_2" then
        taxi.pickup = taxicfg.loc2
      elseif screvent == "BUTTONM_3" then
        taxi.pickup = taxicfg.loc3
      elseif screvent == "BUTTONM_4" then
        taxi.pickup = taxicfg.loc4
      elseif screvent == "BUTTONM_5" then
        taxi.pickup = taxicfg.loc5
      else
        nextstep = itaxi_finish
      end
    else
        nextstep = itaxi_finish
    end
  return nextstep()
end

function itaxi_dropoff()
  local nextstep = itaxi_meter
  if not taxicfg.dropoff_scr then
    local loc0,loc1,loc2,loc3,loc4,loc5 = taxicfg.loc0,taxicfg.loc1,taxicfg.loc2,taxicfg.loc3,taxicfg.loc4,taxicfg.loc5
    local scrlines = "WIDELBL,THIS,DROP OFF TO,-1,C;" .. "BUTTONM_0,THIS,"..loc0..",2,C;" .. "BUTTONM_1,THIS,"..loc1..",4,C;"
                .. "BUTTONM_2,THIS,"..loc2..",6,C;" .. "BUTTONM_3,THIS,"..loc3..",8,C;" .. "BUTTONM_4,THIS,"..loc4..",10,C;" .. "BUTTONM_5,THIS,"..loc5..",12,C;"
    taxicfg.dropoff_scr = scrlines
  end

  local scrkeys = KEY.CNCL+KEY.CLR
  local screvent,scrinput = terminal.DisplayObject(taxicfg.dropoff_scr,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  
  if screvent == "BUTTONM_0" then
    taxi.dropoff = taxicfg.loc0
  elseif screvent == "BUTTONM_1" then
    taxi.dropoff = taxicfg.loc1
  elseif screvent == "BUTTONM_2" then
    taxi.dropoff = taxicfg.loc2
  elseif screvent == "BUTTONM_3" then
    taxi.dropoff = taxicfg.loc3
  elseif screvent == "BUTTONM_4" then
    taxi.dropoff = taxicfg.loc4
  elseif screvent == "BUTTONM_5" then
    taxi.dropoff = taxicfg.loc5
  elseif screvent == "KEY_CLR" then
    nextstep = itaxi_pickup
  else
    nextstep = itaxi_finish
  end
  return nextstep()
end

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

function itaxi_other_charges()
  local otherchg = taxi.otherchg or 0
  local scrlines = "WIDELBL,iTAXI_T,94,2,C;" .. "AMOUNT," .. otherchg ..",5,5,C,8;"

  local scrkeys = KEY.OK+KEY.CNCL+KEY.CLR
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" then
    taxi.otherchg = tonumber(scrinput)
    taxi.subtotal = taxi.meter + taxi.otherchg
    return itaxi_pay()
  elseif screvent == "KEY_CLR" then
    taxi.otherchg = 0
    return itaxi_meter()
  else
    return itaxi_finish()
  end
end

function round_near5(num_input)
  local iret = 0
  local num10 = math.floor(num_input/10)*10
  local num_left = num_input - num10
  if num_left >= 7.50 then iret = num10 + 10
  elseif num_left < 2.5 then iret = num10
  else iret = num10 + 5 end
  return (iret)
end

function itaxi_tip()
  local amt = taxi.subtotal + ( not taxi.cash and taxi.serv_gst or 0)
  local line1 = "TOTAL FARE:" .. string.format("%10s", string.format( "$%.2f", amt/100))
  local amt2 = math.floor(amt/100 + 2.50)*100
  local amt5 = round_near5(amt/100+ 5)*100
  local amt10 =round_near5(amt/100+10)*100

  local s1,s2,s3 = string.format("$%.0f",amt2/100),string.format("$%.0f",amt5/100),string.format("$%.0f",amt10/100)
  if #s1 ==2 then s1 = " "..s1 end;if #s2 ==2 then s2 = " "..s2 end;if #s3 ==2 then s3 = " "..s3 end
  if #s1 ==3 then s1 = s1.." " end;if #s2 ==3 then s2 = s2.." " end;if #s3 ==3 then s3 = s3.." " end
  local scrlines = "WIDELBL,THIS," .. line1 ..",1,5;" 
    .. ",THIS,  WOULD YOU LIKE TO TIP YOUR   DRIVER? ROUND YOUR TOTAL TO:,3,C;"   
    .."BUTTONS_1,THIS,"..s1..",7,4;"
    .."BUTTONS_2,THIS,"..s2..",7,20;"
    .."BUTTONS_3,THIS,"..s3..",7,36;"
    .."BUTTONL_4,THIS,".."CONTINUE"..",B,C;"

  local scrkeys = KEY.OK+KEY.CNCL
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)

  taxi.tip = 0
  local tip_gst = 0
  if screvent == "BUTTONL_4" then
  elseif screvent == "BUTTONS_1" then
		tip_gst = amt2 - amt
  elseif screvent == "BUTTONS_2" then
		tip_gst = amt5 - amt
  elseif screvent == "BUTTONS_3" then
		tip_gst = amt10 - amt
  end
  if tip_gst > 0 then 
    local pct = 1+ tonumber (taxicfg.serv_gst)/10000
    taxi.tip = taxi.cash and tip_gst or math.floor( tip_gst/pct + 0.5)
    taxi.meter = taxi.meter + taxi.tip
    taxi.subtotal = taxi.meter + taxi.otherchg
    taxi.serv_gst = taxi.serv_gst + tip_gst - taxi.tip
	taxi.tipgst = tip_gst
  end
  
  if screvent == "KEY_CLR" or screvent == "TIME" or screvent == "CANCEL" then
    return itaxi_finish
  else return nil
  end
end

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
    elseif emvres == "98" then 
		return itaxi_ctls_tran()
    elseif emvres == "99" or --[[emvres == "10" or]] emvres =="-1025" then 
        if emvres == "-1025" then terminal.DisplayObject("WIDELBL,THIS,NO CONTACTLESS,3,C;".. 
          "WIDELBL,THIS,FOR AMOUNT >".. string.format("%.2f",translimit/100.0) ..",5,C;",KEY.OK,EVT.TIMEOUT,2000) end
        return itaxi_paymentmethod()
    elseif emvres == "-1001" or emvres =="-1002" then 
		if emvres == "-1001" then taxi.track2 = terminal.GetTrack(2) else taxi.chipcard = true end
		return itaxi_pay_swipe()
	else
        terminal.ErrorBeep()
        if emvres == "-13" or emvres == "-1" then
            if terminal.EmvIsCardPresent() then terminal.DisplayObject("WIDELBL,THIS,REMOVE CARD,3,C;",0,EVT.SCT_OUT,0)
            else    terminal.DisplayObject("WIDELBL,THIS,TRAN CANCELLED,3,C;",KEY.OK+KEY.CNCL,EVT.TIMEOUT,5000)
            end
        else    terminal.DisplayObject("WIDELBL,THIS,CARD ERROR,3,C;",KEY.OK+KEY.CNCL,EVT.TIMEOUT,5000)
        end
        return itaxi_finish() 
    end
end

function itaxi_paymentmethod(noinsert)
    local scrlines = "WIDELBL,THIS,SWIPE/INSERT,1,C;".."WIDELBL,THIS,CARD,2,C;"
    local screvents = EVT.TIMEOUT+EVT.MCR+EVT.SCT_IN
	if noinsert then
    	scrlines = "WIDELBL,THIS,SWIPE CARD,2,C;"
    	screvents = EVT.TIMEOUT+EVT.MCR
	end
    local scrkeys  = KEY.CNCL
    taxi.CTemvrs=nil; taxi.tlvs = nil; taxi.ctls = nil; terminal.Sleep(2000)
    local screvent = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)

    if screvent == "MCR" then taxi.track2 = terminal.GetTrack(2); return itaxi_pay_swipe()
    elseif screvent == "CHIP_CARD_IN" then taxi.chipcard = true; return itaxi_pay_swipe()
    else return itaxi_finish()
    end
end

function itaxi_cash()
  local scrlines1 = "WIDELBL,,37,2,C;" .."WIDELBL,,26,4,C;"
  terminal.DisplayObject(scrlines1,0,0,0)
  local timestr = terminal.Time( "DD/MM/YY        hh:mm:ss" )
  local otherchgstr = ""
  if taxi.otherchg > 0 then otherchgstr = "OTHR CHRGS:\\R".. string.format("$%.2f",taxi.otherchg/100) .."\\n" end
  local auth_no,abn_no,taxi_no =  taxicfg.auth_no,taxicfg.abn_no,taxicfg.taxi_no
  local abn_str = abn_no and (taxi.subtotal > 7500 or taxi.subtotal<=7500 and not taxicfg.abn_skip) and ( "DRVR ABN:\\R" .. abn_no .."\\n" ) or ""
  local header,mtrailer,ctrailer = itaxi_get_print()

  local prtvalue= header .. "\\CCASH RECEIPT\\n" ..
            "\\4\\w------------------------------------------\\n" ..
            "\\fMERCHANT ID:\\R" .. string.sub(config.mid,-8) .. "\\n" ..
            "\\fTERMINAL ID:\\R" .. config.tid .. "\\n" ..
            "\\fDRIVER NO:\\R" .. (auth_no or "") .. "\\n" ..
            abn_str ..
            "TAXI NO:\\R" .. (taxi_no or "") .."\\n" ..
            "\\4\\W\\CTAX INVOICE\\n" ..
            "\\f\\C" .. timestr .."\\n" ..
            "\\4\\w------------------------------------------\\n" ..
            "\\fPICK UP:\\R" .. taxi.pickup .."\\n" ..
            "\\fDROP OFF:\\R" .. taxi.dropoff .. "\\n\\n" ..
            "METER FARE:\\R" .. string.format("$%.2f",taxi.meter/100) .. "\\n" ..
            otherchgstr ..
            "\\f \\R----------\\n" ..
            "\\fTOTAL:\\R" .. string.format("$%.2f", taxi.subtotal/100) .. "\\n\\n" ..
            "\\C** CASH RECEIPT **\\n\\n" .. ctrailer

  terminal.Print(prtvalue,true)
  checkPrint(prtvalue)
  return itaxi_finish()
end

function itaxi_pay()
  taxi.serv_gst = 0
  if taxicfg.serv_gst > 0 then taxi.serv_gst = math.floor(taxi.subtotal / 10000 * tonumber (taxicfg.serv_gst)+0.5) end
  local line1 = "PICK UP:" .. string.format("%13s", taxi.pickup )
  local line2 = "DROP OFF:" .. string.format("%12s", taxi.dropoff )
  local line3 = "TOTAL FARE:" .. string.format("%10s", string.format( "$%.2f", taxi.subtotal/100))
  local line4,line5,line6,line7 = "103","104","105","163"
  local scrlines = ",THIS," .. line1 ..",0,5;" .. ",THIS," .. line2 ..",1,5;" .. "WIDELBL,THIS," .. line3 ..",3,5;" 
              .. ",THIS,IS THIS CORRECT?,6,C;"   .. "BUTTONS_1,iTAXI_T," .. line6 ..",B,10;"
          .. "BUTTONS_2,iTAXI_T," .. line7 ..",B,33;"
  
  local scrkeys = KEY.OK+KEY.CNCL+KEY.CLR
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  
  if screvent == "KEY_OK" or screvent == "BUTTONS_1" then
    local ret = itaxi_tip()
    if ret then return ret()
	elseif taxi.cash then return itaxi_cash()
    elseif not check_logon_ok() then
        return itaxi_finish()
    elseif taxi.ctls then
        return itaxi_ctls_tran()
    elseif not taxi.chipcard and not taxi.track2 then
        return itaxi_ctls_tran()
    else 
        return itaxi_pay_swipe()
    end
  elseif screvent == "BUTTONS_2" or screvent == "KEY_CLR" then
    return itaxi_meter()
  else
    return itaxi_finish()
  end
end

function itaxi_pay_swipe()
  local amt = taxi.subtotal + taxi.serv_gst
  local ddmm = terminal.Time("DDMM")
  local dd,mm = tonumber(string.sub(ddmm,1,2)),tonumber(string.sub(ddmm,3,4))
  if taxicfg.day ~= dd then 
    taxicfg.day = dd
    taxicfg.daily = 0
    terminal.SetJsonValue("iTAXI_CFG","DAY",dd)
    terminal.SetJsonValue("iTAXI_CFG","DAILY","0")
  end
  if taxicfg.month ~= mm then 
    taxicfg.month = mm
    taxicfg.monthly = 0
    terminal.SetJsonValue("iTAXI_CFG","MONTH",mm)
    terminal.SetJsonValue("iTAXI_CFG","MONTHLY","0")
  end 
  if amt + taxicfg.daily > taxicfg.day_limit then return itaxi_above_limit("DAY", taxicfg.day_limit)
  elseif amt + taxicfg.monthly > taxicfg.month_limit then return itaxi_above_limit("MONTH", taxicfg.month_limit)
  else return itaxi_pay_do()
  end
end

function itaxi_above_limit( dm, limit)
  local scrlines = "WIDELBL,iTAXI_T,".. (dm == "DAY" and "140" or "141") ..",1,C;" .. "WIDELBL,iTAXI_T,142,2,C;"
                .. ",THIS," .."So far:".. string.format("%14.2f",limit/100) ..",6,4;"
  terminal.ErrorBeep()
  terminal.DisplayObject(scrlines,KEY.CNCL,EVT.TIMEOUT,ScrnErrTimeout)
  return itaxi_finish()
end

function itaxi_pay_do()
  ecrd = {}
  local otherchgstr = ""
  if taxi.otherchg and taxi.otherchg > 0 then otherchgstr = "OTHR CHRGS:\\R".. string.format("$%.2f",taxi.otherchg/100) .."\\n" end
  ecrd.POO = "YES"; ecrd.TRACK = "YES"; ecrd.AMT = taxi.subtotal + taxi.serv_gst
  ecrd.KEEP = taxi.subtotal; ecrd.FUNCTION = "PRCH" ; ecrd.TIMER = ""
  ecrd.HEADER,ecrd.MTRAILER,ecrd.CTRAILER = itaxi_get_print()
  local tipstr = taxi.tip and taxi.tip > 0 and "\\fTIP:\\R"..string.format("%.2f",taxi.tip/100).. "\\n" or ""

  local abn_str = taxicfg.abn_no and (taxi.subtotal+taxi.serv_gst > 7500 or taxi.subtotal+taxi.serv_gst<=7500 and not taxicfg.abn_skip) and ( "DRVR ABN:\\R" .. taxicfg.abn_no .."\\n" ) or ""
  ecrd.HEADER_OK = "\\f\\W\\CTAX INVOICE\\n" .. "\\fINV#:\\R"..taxicfg.inv.."\\n" ..
    "\\fDRIVER NO:\\R" .. (taxicfg.auth_no or "") .. "\\n" ..
    abn_str ..
    "TAXI NO:\\R" .. (taxicfg.taxi_no or "") .."\\n" ..
    "\\fPICK UP:\\R" .. taxi.pickup .."\\n" ..
    "DROP OFF:\\R" .. taxi.dropoff .. "\\n" ..
    "METER FARE:\\R" .. string.format("$%.2f",(taxi.meter - taxi.tip or 0)/100) .. "\\n" ..
    otherchgstr ..
    "\\f \\R----------\\n" ..
    "\\fTOTAL FARE:\\R" .. string.format( "$%.2f", (taxi.subtotal- taxi.tip or 0)/100)  .. "\\n" ..
	tipstr ..
    "SERVICE+GST:\\R" .. string.format( "$%.2f", taxi.serv_gst/100)  .. "\\n" ..
    "\\f \\R----------\\n" ..
    "\\fTOTAL:\\R" .. string.format( "$%.2f", (taxi.subtotal+ taxi.serv_gst )/100) .."\\n"
  ecrd.TRACK2 = taxi.track2
  ecrd.CARDNAME = taxi.track2 and taxi.cardname
  ecrd.CTLS = taxi.ctls
  ecrd.TLVs = taxi.tlvs 
  ecrd.CTEMVRS    = taxi.CTemvrs
  ecrd.CVMLIMIT = taxi.cvmlimit
  ecrd.CHIPCARD = taxi.chipcard
  ecrd.ENTRY = taxi.entry
  ecrd.RETURN = itaxi_finish
  return do_obj_iecr_start()
end

function itaxi_smenu ()
  local scrlines = "LARGE,iTAXI_T,1,0,C;" .."BUTTONM_1,iTAXI_T,3,2,C;" .."BUTTONM_2,iTAXI_T,4,4,C;".."BUTTONM_3,iTAXI_T,5,6,C;".."BUTTONM_4,iTAXI_T,6,8,C;".."BUTTONM_5,iTAXI_T,7,10,C;".."BUTTONM_6,THIS,TIME ADJUSTMENT,12,C;"

  local scrkeys  = KEY.CLR+KEY.CNCL
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "TIME" or screvent == "CANCEL" or screvent == "KEY_CLR" then 
    return itaxi_finish()
  elseif screvent == "BUTTONM_1" then
    return itaxi_serv_gst()
  elseif screvent == "BUTTONM_2" then
    return itaxi_commission()
  elseif screvent == "BUTTONM_3" then
    return itaxi_header()
  elseif screvent == "BUTTONM_4" then
    return itaxi_trailer12()
  elseif screvent == "BUTTONM_5" then
    return itaxi_abn_option()
  elseif screvent == "BUTTONM_6" then
    return itaxi_timeoffset()
  else
    return itaxi_smenu()
  end
end

function itaxi_serv_gst ()
  local scrlines = "LARGE,iTAXI_T,8,2,C;" .."LPERCENT,"..taxicfg.serv_gst..",0,5,20,6;"
  local scrkeys  = KEY.CLR+KEY.CNCL+KEY.OK
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" and taxicfg.serv_gst ~= tonumber(scrinput) then
    taxicfg.serv_gst = tonumber(scrinput) or 0
    if taxicfg.hire then taxicfg.h_serv_gst=taxicfg.serv_gst; terminal.SetJsonValue("iTAXI_CFG","HIRE_SERV_GST",scrinput)
	else terminal.SetJsonValue("iTAXI_CFG","SERV_GST",scrinput) end
  end
  return itaxi_smenu()
end

function itaxi_commission ()
  local scrlines = "LARGE,iTAXI_T,9,2,C;" .."LPERCENT,"..taxicfg.comm..",0,5,20,6;"
  local scrkeys  = KEY.CLR+KEY.CNCL+KEY.OK
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" and taxicfg.comm ~= tonumber(scrinput) then
    taxicfg.comm = tonumber(scrinput)
    if taxicfg.hire then taxicfg.h_comm=taxicfg.comm; terminal.SetJsonValue("iTAXI_CFG","HIRE_COMM",scrinput)
    else terminal.SetJsonValue("iTAXI_CFG","COMM",scrinput) end
  end
  return itaxi_smenu()
end

function itaxi_header ()
  local scrlines = "LARGE,iTAXI_T,40,2,C;" .."LARGE,iTAXI_T,41,3,C;".."BUTTONM_1,iTAXI_T,60,5,C;" .."BUTTONM_2,iTAXI_T,61,7,C;"
  local scrkeys  = KEY.CLR+KEY.CNCL
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "BUTTONM_1" then
    scrlines = "LARGE,iTAXI_T,42,2,C;" .."STRING,"..taxicfg.header0..",0,6,1,42;" .."BUTTONA,THIS,ALPHA ,B,C;"
    screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
    if screvent == "KEY_OK" and scrinput ~= taxicfg.header0 then
      terminal.SetJsonValue("iTAXI_CFG","HEADER0",scrinput)
	  taxicfg.header0 = scrinput
    end
  elseif screvent == "BUTTONM_2" then
    scrlines = "LARGE,iTAXI_T,43,2,C;" .."STRING,"..taxicfg.header1..",0,6,1,42;" .."BUTTONA,THIS,ALPHA ,B,C;"
    screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
    if screvent == "KEY_OK" and scrinput ~= taxicfg.header1 then
      terminal.SetJsonValue("iTAXI_CFG","HEADER1",scrinput)
	  taxicfg.header1 = scrinput
    end
  end
  return itaxi_smenu()
end

function itaxi_trailer12 ()
  local scrlines = "LARGE,iTAXI_T,50,2,C;" .."BUTTONM_1,iTAXI_T,60,5,C;" .."BUTTONM_2,iTAXI_T,61,7,C;".."BUTTONM_3,iTAXI_T,62,9,C;"
  local scrkeys  = KEY.CLR+KEY.CNCL
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  local nextstep = itaxi_smenu
  if screvent == "BUTTONM_1" then
        scrlines = "LARGE,iTAXI_T,52,2,C;" .."STRING,"..taxicfg.trailer0..",0,6,3,30;".."BUTTONA,THIS,ALPHA ,B,C;"
        screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
        if screvent == "KEY_OK" and scrinput ~= taxicfg.trailer0 then
            terminal.SetJsonValue("iTAXI_CFG","TRAILER0",scrinput)
            taxicfg.trailer0 = scrinput
        end
  elseif screvent == "BUTTONM_2" then
        scrlines = "LARGE,iTAXI_T,53,2,C;" .."STRING,"..taxicfg.trailer1..",0,6,3,30;".."BUTTONA,THIS,ALPHA ,B,C;"
        screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
        if screvent == "KEY_OK" and scrinput ~= taxicfg.trailer1 then
            terminal.SetJsonValue("iTAXI_CFG","TRAILER1",scrinput)
            taxicfg.trailer1 = scrinput
        end
  elseif screvent == "BUTTONM_3" then
        scrlines = "LARGE,iTAXI_T,54,2,C;" .."STRING,"..taxicfg.trailer2..",0,6,3,30;".."BUTTONA,THIS,ALPHA ,B,C;"
        screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
        if screvent == "KEY_OK" and scrinput ~= taxicfg.trailer2 then
            terminal.SetJsonValue("iTAXI_CFG","TRAILER2",scrinput)
            taxicfg.trailer2 = scrinput
        end
  end
  return nextstep()
end

function itaxi_abn_option()
  local scrlines = "LARGE,iTAXI_T,7,2,C;" .."LARGE,THIS,PRINT ABN IF TOTAL IS,5,C;".."LARGE,THIS,LESS OR EQUAL $75?,6,C;".."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
  local scrkeys  = KEY.CNCL
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "BUTTONS_1" and taxicfg.abn_skip then
    taxicfg.abn_skip = nil
    terminal.SetJsonValue("ITAXI_OPTIONS","ABN_SKIP","NO")
  elseif screvent == "BUTTONS_2" and not taxicfg.abn_skip then
    taxicfg.abn_skip = true
    terminal.SetJsonValue("ITAXI_OPTIONS","ABN_SKIP","YES")
  end
  return itaxi_smenu()
end

function itaxi_timeoffset()
  local s_tz = "0"
  local tz = terminal.GetJsonValue("iTAXI_CFG","RISTIMEOFFSET")
  if tz and tz ~= "" then s_tz = tz end
  
  local scrlines = "LARGE,THIS,TIME TO ADJUST (MINUTES),2,C;" .."STRING," .. s_tz .. ",,6,18,10,1;".."BUTTONA,THIS,ALPHA ,B,C;"
  local scrkeys  = KEY.CLR+KEY.CNCL+KEY.OK
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" and s_tz ~= scrinput then
    if not tonumber(scrinput) then 
		 terminal.DisplayObject("WIDELBL,THIS,INVALID NUMBER,3,C;",scrkeys,EVT.TIMEOUT,ScrnErrTimeout)
    else terminal.SetJsonValue("iTAXI_CFG","RISTIMEOFFSET",scrinput)
		 config.timeadjust = scrinput
	end
  end
  return itaxi_smenu()
end

function itaxi_pay_revert(rtnvalue)
  terminal.FileRemove("TAXI"..tostring(taxi.current_taxi_idx))
  terminal.SetArrayRange("TAXI","",taxi.current_taxi_idx)
  terminal.FileRemove("iTAXI_TXN"..tostring(taxi.current_taxitxn_idx))
  terminal.SetArrayRange("iTAXI_TXN","",taxi.current_taxitxn_idx)
  taxicfg.inv = string.format("%06d", tonumber(taxicfg.inv)-1 )
  terminal.SetJsonValue("iTAXI_CFG","INV", taxicfg.inv)
  if rtnvalue then return rtnvalue
  else return itaxi_finish() end
end

function itaxi_pay_done(rtnvalue)
  local taxi_min,taxi_next= terminal.GetArrayRange("TAXI")
  local inv = tonumber( taxicfg.inv )
  if taxi_next >0 and taxi_next - taxi_min > taxicfg.max_kept_inv then
    terminal.FileRemove("TAXI" .. taxi_min)
    taxi_min = taxi_min + 1
  end

  local tipstr = taxi.tip and taxi.tip > 0 and (",TIP:"..taxi.tip) or ""

  local taxi_nextfile = "TAXI"..taxi_next
  taxi.current_taxi_idx = taxi_next
  local taxistr = "{TYPE:DATA,NAME:"..taxi_nextfile..",GROUP:CBA,VERSION:2.0,INV:"..inv..",STAN:"..ecrd.INV..",TXNTOTAL:"..ecrd.AMT..",SUBTOTAL:"..ecrd.KEEP..",HEADER:".. ecrd.HEADER..",HEADER_OK:"..ecrd.HEADER_OK..",MRECEIPT:"..ecrd.MRECEIPT..",TRAILER:"..ecrd.MTRAILER..",EMVRCPT:"..ecrd.emvrcpt..",CRCPT:"..ecrd.CRECEIPT..tipstr.."}"
  
  terminal.NewObject(taxi_nextfile,taxistr)
  if #ecrd.emvrcpt > 0 then terminal.NewObject("LASTEMV_RCPT",taxistr) end
  terminal.SetArrayRange("TAXI",taxi_min,taxi_next+1)

  local taxitxn_min,taxitxn_next= terminal.GetArrayRange("iTAXI_TXN")
  local taxitxn_nextfile = "iTAXI_TXN"..taxitxn_next
  local account = ( ecrd.ACCOUNT == "4" and "CR" or ( ecrd.ACCOUNT=="1" and "SAV" or "CHQ"))
  local dt = string.sub(ecrd.DATE,3,4)..string.sub(ecrd.DATE,1,2) --ddmm
  local taxitxnstr = "{TYPE:DATA,NAME:iTAXI_TXN"..taxitxn_next..",GROUP:CBA,VERSION:2.0,DATE:"..dt..",TIME:"..ecrd.TIME..",TID:"..ecrd.TID..",DRIVER:"..taxicfg.auth_no..",ABN:"..taxicfg.abn_no..",TAXI:"..taxicfg.taxi_no..",STAN:"..ecrd.INV..",INV:"..inv..",METER:"..taxi.meter..",FARE:"..ecrd.KEEP..",TOTAL:"..ecrd.AMT..",COMM:"..taxicfg.comm..",PICK_UP:"..taxi.pickup..",DROP_OFF:"..taxi.dropoff..",PAN:TODO,CARDNO:"..ecrd.CARDNO..",ACCOUNT:"..account..",RC:"..ecrd.RC..",AUTHID:"..ecrd.AUTHID..tipstr.."}"
  terminal.NewObject(taxitxn_nextfile,taxitxnstr)
  terminal.SetArrayRange("iTAXI_TXN","",taxitxn_next+1)
  taxi.current_taxitxn_idx = taxitxn_next

  taxicfg.daily = taxicfg.daily + ecrd.AMT
  taxicfg.monthly = taxicfg.monthly + ecrd.AMT
  inv = inv + 1
  taxicfg.inv = string.format("%06d", inv )
  terminal.SetJsonValue("iTAXI_CFG","INV", taxicfg.inv)
  terminal.SetJsonValue("iTAXI_CFG","DAILY",taxicfg.daily)
  terminal.SetJsonValue("iTAXI_CFG","MONTHLY",taxicfg.monthly)
  if rtnvalue then return rtnvalue
  else return itaxi_finish() end
end

function itaxi_reprint_menu()
  local scrlines = ",THIS,REPRINT,-1,C;" .."BUTTONM_1,iTAXI_T,152,2,C;" .."BUTTONM_2,iTAXI_T,153,4,C;".."BUTTONM_3,iTAXI_T,154,6,C;" .."BUTTONM_4,iTAXI_T,155,8,C;" .. "BUTTONM_5,THIS,LAST DECLINED TXN,10,C;".. "BUTTONM_6,THIS,LAST EMV TXN,12,C;"
  local scrkeys  = KEY.CLR+KEY.CNCL
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  local taxi_min,taxi_next= terminal.GetArrayRange("TAXI")
  local shft_min,shft_next= terminal.GetArrayRange("PREV_SHFT")
  
  if  screvent == "BUTTONM_1" then
    if taxi_min == taxi_next then -- no array item
      return itaxi_reprint_no_inv()
    else return itaxi_reprint_do() end
  elseif  screvent == "BUTTONM_2" then
    return itaxi_reprint()
  elseif  screvent == "BUTTONM_3" then
    if shft_min == shft_next then return itaxi_retotal_no_batch()
    else return itaxi_retotal(shft_next-1) end
  elseif screvent == "BUTTONM_4" then
    return itaxi_retotal()
  elseif screvent == "BUTTONM_5" then
    return itaxi_reprint_do(0,"TAXI_Dclnd")
  elseif screvent == "BUTTONM_6" then
    return itaxi_reprint_do(nil,"LASTEMV_RCPT",true)
  elseif screvent == "KEY_CLR" then
    return itaxi_fmenu()
  else
    return itaxi_finish()
  end
end

function itaxi_reprint()
  local scrlines = ",THIS,REPRINT,-1,C;"..",iTAXI_T,120,5,C;" .."LNUMBER,,0,7,15,6;".."BUTTONL,THIS,PRINT,B,C"
  local screvent,scrinput=terminal.DisplayObject(scrlines,KEY.OK+KEY.CLR+KEY.CNCL,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" or screvent == "BUTTONL" then
    if #scrinput > 0 then return itaxi_reprint_do(tonumber(scrinput))
    else return itaxi_reprint()
    end
  elseif screvent == "KEY_CLR" then
     return itaxi_reprint_menu()
  else
    return itaxi_finish()
  end
end

function itaxi_reprint_no_inv()
  local scrlines = ",THIS,REPRINT,-1,C;" .."WIDELBL,THIS,INVOICE DOES,3,C;" .."WIDELBL,THIS,NOT EXIST,4,C;"
  terminal.ErrorBeep()
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL,EVT.TIMEOUT,ScrnErrTimeout)
  if screvent == "TIME" or screvent == "KEY_CLR" then
     return itaxi_reprint_menu()
  else
    return itaxi_finish()
  end
end

function itaxi_reprint_do(inv_p,rcptfile,emvprint)
  local inv,found,taxifile=0,false,""
  if rcptfile then taxifile = rcptfile; found = true
  else
    local taxi_min,taxi_next= terminal.GetArrayRange("TAXI")
    if taxi_next == taxi_min then found = false
    elseif inv_p == nil then taxifile = "TAXI"..tostring(taxi_next-1);found = true 
    else 
        for i = taxi_next-1,taxi_min,-1 do
            taxifile = "TAXI" .. i
            inv = tonumber(terminal.GetJsonValue(taxifile,"INV"))
            if inv == inv_p then found = true; break end
        end
    end
  end
  
  if not found then return itaxi_reprint_no_inv()
  else
    local dup_str = "\\4\\W\\i   ** DUPLICATE **   \\n"
    local scrlines = ",THIS,REPRINT,-1,C;" .."WIDELBL,iTAXI_T,122,3,C;" .."WIDELBL,iTAXI_T,123,4,C;" 
    terminal.DisplayObject(scrlines,0,0,0)
    local header,header_ok,mreceipt,trailer,trailer_ok,EmvData,CustRcpt = terminal.GetJsonValue(taxifile,"HEADER","HEADER_OK","MRECEIPT","TRAILER","TRAILER_OK","EMVRCPT","CRCPT")
    terminal.Print(header,false)
    terminal.Print(dup_str,false)
    if #header_ok > 0 then terminal.Print(header_ok,false); terminal.Print(dup_str,false) end
    terminal.Print(mreceipt,false)
    terminal.Print(dup_str,false)
    terminal.Print(trailer,false)
    if emvprint then terminal.Print(EmvData,false) end
    
    if trailer_ok and #trailer_ok > 0 then terminal.Print(trailer_ok,false) end
    terminal.Print("\\n",true)
    
    if not emvprint then
        local scrlines = "WIDELBL,,36,4,C;" .."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
        local screvent,_ = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,ScrnTimeout)
        if screvent == "BUTTONS_1" or screvent == "TIME" or screvent == "KEY_OK" then
            scrlines = "WIDELBL,,37,2,C;" .."WIDELBL,,26,4,C;"
            terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
            local who = "\\CCUSTOMER\\n\\CCOPY\\n"
            terminal.Print(header,false)
            terminal.Print(dup_str,false)
            if trailer_ok and #trailer_ok > 0 then terminal.Print(header_ok,false); terminal.Print(dup_str,false) end
            terminal.Print(CustRcpt,false)
            terminal.Print(dup_str,false)
            terminal.Print(trailer,false)
            if trailer_ok and #trailer_ok > 0 then terminal.Print(trailer_ok,false) end
            terminal.Print("\\n",true)
        end
    end
    return itaxi_fmenu()
  end
end

function itaxi_retotal_no_batch()
    local scrlines = ",THIS,REPRINT,-1,C;" .."WIDELBL,THIS,SHIFT DOES,3,C;".."WIDELBL,THIS,NOT EXIST,4,C;"
     terminal.ErrorBeep()
    local screvent = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR,EVT.TIMEOUT,ScrnErrTimeout)
    if screvent == "CANCEL" then
        return itaxi_finish()
    else
        return itaxi_reprint_menu()
    end
end

function itaxi_retotal(fileno)
    local batchno = 0
    local shftfile = nil
    local scrlines,screvent,scrinput ="","",""
    if not fileno then
        scrlines = ",THIS,REPRINT,-1,C;" ..",iTAXI_T,124,5,C;".."LNUMBER,,0,7,15,6,1;".."BUTTONL,THIS,PRINT,B,C"
        screvent,scrinput = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL+KEY.CLR,EVT.TIMEOUT,30000)
        batchno = (scrinput and #scrinput>0 and tonumber(scrinput) or 0)
        if batchno > 0 and ( screvent == "KEY_OK" or screvent == "BUTTONL" ) then
            local shft_min,shft_next= terminal.GetArrayRange("PREV_SHFT")
            for i = shft_next-1,shft_min,-1 do
              local bch = terminal.GetJsonValue("PREV_SHFT"..i,"BATCH")
              if bch ~= "" and tonumber(bch) == batchno then shftfile= "PREV_SHFT"..i; break end
            end
        end
    else shftfile = "PREV_SHFT"..fileno
    end

    if screvent == "KEY_CLR" then
        return itaxi_reprint_menu()
    elseif screvent == "TIME" or screvent=="CANCEL" then
        return itaxi_finish()
    elseif not shftfile then return itaxi_retotal_no_batch()
    else
        local header,body,trailer = terminal.GetJsonValue(shftfile,"HEADER","BODY","TRAILER")
        local dup_str = "\\4\\W\\i   ** DUPLICATE **   \\n"
        local scrlines = "WIDELBL,iTAXI_T,122,2,C;" .."WIDELBL,iTAXI_T,123,3,C;" 
        terminal.DisplayObject(scrlines,0,0,0)
        local prtvalue = header..dup_str..body..dup_str..trailer..dup_str.."\n\n"
        terminal.Print(prtvalue,true)
        checkPrint(dup_str)
        return itaxi_fmenu()
    end
end

function itaxi_totals()
  local header,trailer = "","\\n\\4\\W\\iINV No.\\RFARE\\n\\4\\W"
  local taxi_min,taxi_next= terminal.GetArrayRange("TAXI")
  local subtotal_d,num_d,tips_d = 0,0,0
  local inv,last_inv,batch = taxicfg.inv,taxicfg.last_inv,taxicfg.batch  

  check_logon_ok()
  local rev_exist = config.safsign and string.find(config.safsign,"+")
  local saf_exist = config.safsign and string.find(config.safsign,"*")
  if (saf_exist or rev_exist) then
    local scrlines = "WIDELBL,THIS,"..(rev_exist and "REVERSAL" or "")..(saf_exist and " SAF" or "") ..",2,C,;".."WIDELBL,THIS,PENDING,3,C;"
    terminal.DisplayObject(scrlines,KEY.OK,EVT.TIMEOUT,2000)
  end

  local saf_inv = {}
  local safmin,safmax= terminal.GetArrayRange("SAF")
  if safmax > safmin then 
    for i=safmin,safmax-1 do 
        local roc = terminal.GetJsonValue("SAF"..i,"ROC")
        if #roc > 0 then saf_inv[i - safmin + 1] = tonumber(roc) end
    end
  end 
    
  for i = taxi_next-1,taxi_min,-1 do
      local taxifile = "TAXI" .. i
      local inv,subtotal,stan,tip=terminal.GetJsonValue(taxifile,"INV","SUBTOTAL","STAN","TIP")
      if #inv >0 and tonumber(inv)==tonumber(last_inv) then break 
      elseif inv =="" or subtotal=="" then
      else 
        local offline_pending = false
        if stan ~= "" and #saf_inv > 0 then for _,v in ipairs(saf_inv) do if tonumber(v) == tonumber(stan) then offline_pending = true end end end
        subtotal_d = subtotal_d + tonumber(subtotal)
        local itip = (tip=="" and 0 or tonumber(tip))
        tips_d = tips_d + itip
        num_d = num_d + 1
        trailer = trailer .. ( offline_pending and "*" or "") ..string.format("%06s",inv) .."\\R" ..string.format("$%.2f",tonumber(subtotal-itip)/100) .."\\n"
      end
  end

  local s1 = string.format("%-10s%16s","BATCH:","#"..batch)
  local scrlines = ",THIS,"..s1..",0,3;" 
  local inv_s,lastinv_s = "",""
  if num_d > 0 then 
    s1 = string.format("%-10s%16s","FROM INV:","#"..tostring(tonumber(last_inv)+1))
    scrlines = scrlines .. ",THIS,"..s1..",1,3;"
    s1 = string.format("%-10s%16s","TO INV:","#"..tostring(tonumber(inv)-1))
    scrlines = scrlines .. ",THIS,"..s1..",2,3;"
  end
  if tips_d>0 then subtotal_d = subtotal_d -tips_d end
  s1 = string.format("%-10s%16s","TOTAL:",string.format("$%.2f",subtotal_d/100))
  scrlines = scrlines.. ",THIS,"..s1 ..",3,3;"
  scrlines = scrlines.. "WIDELBL,iTAXI_T,110,6,C;" .."WIDELBL,iTAXI_T,111,7,C;" .."BUTTONS_YES,iTAXI_T,105,B,10;"  .."BUTTONS_NO,iTAXI_T,163,B,33;" 
  
  local screvent,_=terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "TIME" then 
    return itaxi_finish()
  elseif screvent == "KEY_CLR" or screvent=="BUTTONS_NO" or screvent == "CANCEL" then 
    return itaxi_finish()
  elseif screvent == "KEY_OK" or screvent== "BUTTONS_YES" then
    if subtotal_d == 0 then return itaxi_totals_not()
    else
 
      local comm,header1,header0,auth_no,abn_no,taxi_no = taxicfg.comm,taxicfg.header1,taxicfg.header0,taxicfg.auth_no,taxicfg.abn_no,taxicfg.taxi_no
      local hdr1 = header1 ..string.format(" %.2f",taxicfg.comm/100) .."%"
      local comm_d = math.floor((subtotal_d+tips_d) * tonumber(comm)/ 10000)
      local payable_d = subtotal_d+tips_d + comm_d
      local batch4 = string.sub( string.format("%06s",batch),3,6)
      local mytime = terminal.Time( "DDMMYYhhmm")
	  local tipstr = tips_d > 0 and ( "TIPS:\\R"..string.format("$%.2f",tips_d/100).."\\n") or ""
      trailer = trailer .." \\R----------\\n" .."TOTAL FARES:\\R"..string.format("$%.2f",subtotal_d/100).."\\n("..
        num_d.." TRANSACTIONS)\\n\\n"..tipstr.."DRIVER BONUS:\\R"..string.format("$%.2f",comm_d/100).."\\n(GST INCL.)\\nDRIVER PAY:\\R"..string.format("$%.2f",payable_d/100).."\\n"
        .."\\4\\W\\C"..hdr1..
        "\\n\\*"..string.format("%04s",batch4)..config.tid..string.format("%06d",payable_d)..mytime..
        "\\3\\C"..string.format("%04s",batch4)..config.tid..string.format("%06d",payable_d)..mytime .."\\n"
      header = "\\ggmcabs.bmp\\n\\4\\W\\C"..header0.."\\n\\C"..hdr1.."\\n\\n\\CDRIVER NO:\\R"..auth_no.."\\n\\CDRVR ABN:\\R"..abn_no.."\\n\\CTAXI NO:\\R" ..
        taxi_no.."\\n\\n\\CBatch #:"..batch.."\\n\\n"

      local inv,batch= taxicfg.inv, taxicfg.batch

      taxicfg.batch = string.format("%06d",tonumber(taxicfg.batch) + 1)
      taxicfg.last_inv = string.format("%06d",tonumber(taxicfg.inv) - 1)
      taxicfg.auth_no = ""
      taxicfg.abn_no = ""
      taxicfg.taxi_no = ""
      terminal.SetJsonValue("iTAXI_CFG","BATCH",taxicfg.batch)
      terminal.SetJsonValue("iTAXI_CFG","LAST_INV",taxicfg.last_inv)
      terminal.SetJsonValue("iTAXI_CFG","ABN_NO","")
      terminal.SetJsonValue("iTAXI_CFG","AUTH_NO","")
      terminal.SetJsonValue("iTAXI_CFG","TAXI_NO","")

      ecrd = {}
      ecrd.FUNCTION = "SHFT"
      ecrd.RETURN = itaxi_totals_done
      ecrd.HEADER = header; ecrd.TRAILER=trailer
      return do_obj_iecr_start()
    end
  end
end

function itaxi_update()
  local idx , upmsg,upload_ok = 0, "",true
  local scrlines = "WIDELBL,THIS,UPDATE,3,C;".."WIDELBL,THIS,IN PROGRESS,4,C;"..",THIS,**PLEASE WAIT**,7,C"
  local screvent,_=terminal.DisplayObject(scrlines,0,0,0)
  local taxitxn_min,taxitxn_next= terminal.GetArrayRange("iTAXI_TXN")

  for i=taxitxn_min,taxitxn_next-1 do
    local msg = terminal.GetJsonObject("iTAXI_TXN"..i)
    upmsg = upmsg .. msg
    if idx >= 10 or i == taxitxn_next - 1 then 
      if not string.find(upmsg,"NAME:iTAXI_TXN0,") then upmsg = string.gsub(upmsg,"NAME:iTAXI_TXN"..i,"NAME:iTAXI_TXN0") end -- server require one iTAXI_TXN0
      terminal.UploadMsg(upmsg)
      terminal.SetJsonValue("iTAXI_RESULT","TEXT","*")  
      terminal.Remote() 
      local result = terminal.GetJsonValue("iTAXI_RESULT","TEXT")
      if result == "*" then upload_ok=false; break  -- upload failed
      else 
        for k=idx,1,-1 do terminal.FileRemove("iTAXI_TXN"..i-idx+k) end
        terminal.SetArrayRange("iTAXI_TXN",i+1,"")
        idx = 1; upmsg = ""
      end
    end
    idx = idx + 1
  end
  if upload_ok then
    terminal.UploadObj("iPAY_CFG")  
    terminal.SetJsonValue("iTAXI_CFG","BATCH_SENT",taxicfg.batch)
    terminal.UploadObj("iTAXI_CFG")
    terminal.SetJsonValue("iTAXI_RESULT","TEXT","*")  
    terminal.Remote()
    local result = terminal.GetJsonValue("iTAXI_RESULT","TEXT")
    if result == "*" then upload_ok=false end
  else
    terminal.ErrorBeep()
    scrlines = "WIDELBL,THIS,UPLOAD,2,C,;".."WIDELBL,THIS,FAILED,3,C;"
    terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL+KEY.CLR,EVT.TIMEOUT,ScrnErrTimeout)
  end
  return upload_ok 
end

function itaxi_totals_not()
  terminal.ErrorBeep()
  local scrlines = "WIDELBL,iTAXI_T,144,2,C;" 
  terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL,EVT.TIMEOUT,ScrnTimeout)
  taxicfg.auth_no = ""
  taxicfg.abn_no = ""
  taxicfg.taxi_no = ""
  terminal.SetJsonValue("iTAXI_CFG","AUTH_NO","")
  terminal.SetJsonValue("iTAXI_CFG","ABN_NO","")
  terminal.SetJsonValue("iTAXI_CFG","TAXI_NO","")
  return itaxi_sign_on()
end

function itaxi_totals_done()

  local shft_min,shft_next= terminal.GetArrayRange("PREV_SHFT")
  if shft_next - shft_min > taxicfg.max_kept_batch then
    terminal.SetArrayRange("PREV_SHFT",shft_min+1,"")
    terminal.FileRemove("PREV_SHFT"..shft_min)
  end
  local shft_nextfile = "PREV_SHFT"..shft_next
  local lastbatch = string.format("%06d",tonumber(taxicfg.batch) - 1)
  local SHFT= { TYPE="DATA",NAME=shft_nextfile,GROUP="CBA",VERSION="1",BATCH=lastbatch,
    HEADER=ecrd.HEADER, BODY=ecrd.BODY, TRAILER=ecrd.TRAILER}
    terminal.SetArrayRange("PREV_SHFT","",shft_next+1)
  local shftstr = jsontable2string (SHFT)
  terminal.NewObject(shft_nextfile,shftstr)
  ecrd ={}
  itaxi_update()
  do_obj_gprs_register()
  return itaxi_sign_on()
end

function itaxi_get_print()
  return taxicfg.header,taxicfg.mtrailer,taxicfg.ctrailer
end

function itaxi_init_cfg()
  taxicfg.header0,taxicfg.header1,taxicfg.trailer0,taxicfg.trailer1,taxicfg.trailer2,taxicfg.trailer3,taxicfg.abn_no,taxicfg.abn,taxicfg.taxi_no,taxicfg.auth_no,taxicfg.inv,taxicfg.last_inv,taxicfg.batch= 
  terminal.GetJsonValue("iTAXI_CFG","HEADER0","HEADER1","TRAILER0","TRAILER1","TRAILER2","TRAILER3","ABN_NO","ABN","TAXI_NO","AUTH_NO","INV","LAST_INV","BATCH")
  taxicfg.comm,taxicfg.serv_gst,taxicfg.day,taxicfg.month,taxicfg.daily,taxicfg.monthly,taxicfg.day_limit,taxicfg.month_limit,taxicfg.ctls_slimit,taxicfg.h_serv_gst,taxicfg.h_comm =terminal.GetJsonValueInt("iTAXI_CFG","COMM","SERV_GST","DAY","MONTH","DAILY","MONTHLY","DAY_LIMIT","MONTH_LIMIT","CTLS_S_LIMIT","HIRE_SERV_GST","HIRE_COMM")
  local drivertype = terminal.GetJsonValue("iTAXI_CFG","DRIVERTYPE")
  if drivertype == "HIRE" then
	taxicfg.comm = taxicfg.h_comm
	taxicfg.serv_gst = taxicfg.h_serv_gst
	if taxicfg.serv_gst==0 and taxicfg.comm==0 then taxicfg.comm = 300;taxicfg.serv_gst = 1100;
		terminal.SetJsonValue("iTAXI_CFG","HIRE_SERV_GST",taxicfg.serv_gst);terminal.SetJsonValue("iTAXI_CFG","HIRE_COMM",taxicfg.comm)
	end
	taxicfg.hire = true
  end
  taxicfg.header = "\\ggmcabs.bmp" .."\\f\\C" .. taxicfg.header0 .. "\\n" .."\\C" .. taxicfg.header1 .. "\\n"
  local cfgtrailer2 = ( taxicfg.trailer2 == "" and "" or ("\\4\\H\\C" .. taxicfg.trailer2 .. "\\n"))
  local cfgtrailer3 = ( taxicfg.trailer3 == "" and "" or ("\\4\\H\\C" .. taxicfg.trailer3 .. "\\n"))
  taxicfg.mtrailer = ""
  taxicfg.ctrailer = "\\4\\H\\C" .. taxicfg.trailer0 .. "\\n".. "\\4\\H\\C" .. taxicfg.trailer1 .. "\\n" .. cfgtrailer2
  taxicfg.max_kept_inv,taxicfg.max_kept_batch,taxicfg.max_txn= terminal.GetJsonValueInt("ITAXI_OPTIONS","MAX_KEPT_INV","MAX_KEPT_BATCH","MAX_TXN")
  taxicfg.loc0,taxicfg.loc1,taxicfg.loc2,taxicfg.loc3,taxicfg.loc4,taxicfg.loc5,taxicfg.abn_skip = terminal.GetJsonValue("ITAXI_OPTIONS","LOC0","LOC1","LOC2","LOC3","LOC4","LOC5","ABN_SKIP")
  if taxicfg.abn_skip~="NO" then taxicfg.abn_skip=true else taxicfg.abn_skip=nil end
  
end

itaxi_init_cfg()
callback.sk1_func = itaxi_swipe_insert
callback.sk2_func = itaxi_fmenu
callback.mcr_func = itaxi_swipe_insert
callback.chip_func = itaxi_swipe_insert
itaxi_startup()
