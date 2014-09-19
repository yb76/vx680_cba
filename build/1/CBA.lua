--[[

Change Log:
2012/07/30-Anand Rai-Add change log and comment dead code.
2012/08/01-Anand Rai, Dwarika pandey - Verify and Modify Screen timeout.
2012/08/03-Anand Rai, Dwarika pandey - Verify and Modify Screen timeout.
2012/08/03-Bo Yang - change screen as per doc V1.9 .
2012/08/14-Dwarika - Amount MIN MAX Validation and centered align.
2012/08/14-Dwarika - Scrntimeout is reset to 30000 as per GM_CBA Sepcs doc 2.1.
2012/08/14-Dwarika - Yellow key functionality on logon init.
2012/08/14-Dwarika - Yellow key functionality on Select account.
2012/08/15-Dwarika - Standard Key functionality on Second copy receipt.
2012/08/16-Dwarika - Min Max input value on Card Entry, Exp Date and Card Verification Code Screen.
2012/08/16-Dwarika - Input Text Max Centered on Card Entry, Exp Date and Card Verification Code Screen.
2012/08/16-Dwarika - Standard Key Functionality on Card Entry, Exp Date and Card Verification Code Screen.
2012/08/16-Dwarika - Standard Key Functionality on Signature screen.
2012/08/16-Anand Rai - SCRN ID 121, KEY OK, Text change.
2012/08/16-Anand Rai - SCRN ID 120, KEY OK, Text change.
2012/08/16-Dwarika - Standard Key Functionality on do_obj_trantimeout.
2012/08/16-Dwarika - Return idle timeout on CardEntry.
2012/08/17-Dwarika - Return idle and timeout and text change on CardExpired.
2012/08/17-Dwarika - Return idle, Red key and timeout on Transaction operator timeout.
2012/08/17-Dwarika - Yellow key disable on Account selection.
2012/08/17-Dwarika - Yellow key disable and added space between two label on Card expired screen.
2012/08/17-Dwarika - Yellow key disable and added error beep on Invalid month screen.
2012/08/18-Dwarika - Standard Key functionality on Sig ok and warning screen.
2012/08/18-Dwarika - Timeout value on warning screen.
2012/08/18-Dwarika - Timeout value on Transaction cancel screen.
2012/08/23-Matthew - Screen layout changes (LARGE not aligning, changing to TEXT, button positions)
2012/09/22-Dwarika - change murchant copy to customer copy for second receipt, to fix bug id 3338 from Bash report by CBA.
2012/09/22-Dwarika - Print Merchant ID for declined transactios, logon etc,to fix bug id 3345 from Bash report by CBA.
2012/09/22-Dwarika - change response code for sign declined transaction to fix bug id 3338 from Bash report by CBA.
2012/09/24-Dwarika -- Software check after logon BUG ID 3341 from bash report by CBA
2012/09/25-Dwarika - change Filed 22 value for offline PIN verification to fix bug id 3361 from Bash report by CBA.
]]

----------------------------iPAY---------------------------------------
function do_obj_cba_mcr_chip()
  check_logon_ok()
  local ok = true
  local nextstep = do_obj_cba_swipe_insert
  txn.func = "PRCH"
  if not check_logon_ok() then ok = false ; nextstep = do_obj_txn_finish end
  if not txn_allowed(txn.func) then ok = false ; nextstep = do_obj_txn_finish end
  if ok and common.track2 then txn.track2 = common.track2 ; common = {}
    txn.swipefirst = 1
    local _,_,_,trk2 = string.find(txn.track2, "(%d*)=(%d*)")
	local chipflag = (trk2 and string.sub(trk2,5,5) or "")
    if chipflag == "2" or chipflag == "6" then
		
      terminal.ErrorBeep()
      local scrlines = "LARGE,THIS,INSERT CARD,2,C;"
      local scrkeys  = KEY.CNCL
      local screvents = EVT.TIMEOUT+EVT.SCT_IN
      local screvent,_ = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)
      if screvent ~= "CHIP_CARD_IN" then nextstep = do_obj_txn_finish 
      else txn.chipcard = true end
	 
    end
  elseif ok then txn.chipcard = true end
  return nextstep()
end

function do_obj_cba_swipe_insert()
	txn.emv = {}
	local ok = 0
	
	if txn.ctls == "CTLS_E" then
		txn.chipcard = true
		txn.cvmlimit = ecrd.CVMLIMIT
	elseif txn.chipcard then 
		ok = emv_init()
	end
	if ok ~= 0 then 
		return do_obj_emv_error(ok)
	else 
		if ecrd.FUNCTION then 
			local func = txn.func
			check_logon_ok() 
			txn.func = func
		end
		return do_obj_prchamount()
	end
end

function emv_init()
  local ok = 0
  if txn.chipcard then
	ok = terminal.EmvTransInit()
	local amt,acctype = ecrd.AMT,0
    if ok == 0 then ok = terminal.EmvSelectApplication(amt,acctype) end
    if ok ~= 0 and ok ~= 103 --[[CARD_REMOVED]] and ok ~= 104 --[[CARD_BLOCKED]] and ok ~= 105 --[[APPL_BLOCKED]] and ok ~= 110 --[[TRANS_CANCELLED]] and ok ~= 130 --[[INVALID_PARAMETER]] then
      txn.emv.fallback = true
    end
  end
  return ok
end

function check_logon_ok()
	if config.logok == true then return true
	else 
		local scrlines = ""
		if config.tid == "" or config.mid == "" then
			scrlines = "WIDELBL,,51,2,C;" .. "WIDELBL,,53,4,C;"
			local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,0,0)
			return false
		end
		
		scrlines = "WIDELBL,,21,2,C;"
		terminal.DisplayObject(scrlines,0,0,0)
		local txnbak = txn
		txn = {}
		txn.func = "LGON"
		txn.finishreturn = true
	 	scrlines = "WIDELBL,THIS,LOGON,2,C;" .. "WIDELBL,THIS,PLEASE WAIT,3,C;"
		terminal.DisplayObject(scrlines,0,EVT.TIMEOUT,ScrnTimeoutHF)
		do_obj_logon_start()
		txn = txnbak
		txn.finishreturn = false
	  return config.logok
	end
end

function check_rev_ok()
	local revok =  ( not config.safsign or config.safsign and do_obj_saf_rev_send("REVERSAL") )
	if not revok then return false else return true end
end

function txn_allowed(txnfunc)
  if config.txn_check_inited == nil then
	local prch,moto = terminal.GetJsonValue("CONFIG","PRCH","MOTO")
    if prch == "NO" then config.txn_prch_disabled = true end
	if moto == "NO" then config.txn_moto_disabled = true end
	config.txn_check_inited = true
  end
  
  if txnfunc == "PRCH" then return not config.txn_prch_disabled 
  elseif  txnfunc == "MOTO" then return not config.txn_moto_disabled 
  else 
    local txncfg = terminal.GetJsonValue("CONFIG",txnfunc)
	if txncfg == "NO" then return false else return true end
  end
end

function do_obj_advice_start(auto)
	local scrlines,scrkeys,screvents,timeout = "","","",0
	if not auto then
	 scrlines = "WIDELBL,THIS,SOFTWARE,2,C;" .. "WIDELBL,THIS,CHECK,3,C;".."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
	 scrkeys  = KEY.CLR+KEY.CNCL
	 screvents = EVT.TIMEOUT
	 timeout = ScrnTimeout
	else
	 scrlines = "WIDELBL,THIS,SOFTWARE,2,C;" .. "WIDELBL,THIS,CHECK,3,C;".."WIDELBL,THIS,PLEASE WAIT,4,C;"
	 scrkeys  = 0
	 screvents = EVT.TIMEOUT
	 timeout = ScrnTimeoutHF
	end
	local screvent,_ = terminal.DisplayObject(scrlines,scrkeys,screvents,timeout)
	if auto or screvent == "BUTTONS_1" then
	  local scrlines = "WIDELBL,,21,4,C;"
	  terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
	  local tcpreturn = tcpconnect()
	  if tcpreturn == "NOERROR" then 
		 if not auto then
		 	check_logon_ok() 
		 	return do_obj_txn_finish()
		 else return do_obj_advice_req()
		 end
	  else scrlines = "WIDELBL,THIS,NO RESPONSE,4,C;"
		screvent,_ = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)
		return do_obj_txn_finish()
	  end
	else  
		return do_obj_txn_finish()
	end
end

function do_obj_advice_req()

  --[[
  --  0000 1000 0000 0010 0100 0010 0100 0000
  --  08024040
  --  01 10 31383030353039313833
  --  02 10 313830303530 39313833
  --  03 01 30
  --  04 01 60
  --  05 01 30
  --  06 01 30
  --  07 01 30
  --  08 01 10
  --  09 02 0030
  --  10 01 30
  --  11 06 000000000000
  --  12 06 000000000000
  --  31 01 01
  --  32 01 00
  --  33 06 000000000000
  --  34 01 30
  --  35 02 0100
  --  36 06 000000000000
  --  37 06 000000000000
  --  38 06 000000000000
  ]]--
  
  local fld63 = "08024040011031383030353039313833021031383030353039313833030130040160050130060130070130080110090200301001301106000000000000120600000000000031010132010033060000000000003401303502"..string.format("%04d",config.saf_limit or 10).."360600000000000037060000000000003806000000000000"

  local fld48 = terminal.HexToString("VX670   001A")  
  
  local fld71 = "0001"
  local fld72 = "0001"
  local msg_flds={"0:620","3:".. "950000","11:"..config.stan,"41:"..config.tid,"42:"..config.mid,"48:"..fld48,"63:"..fld63,"71:"..fld71,"72:"..fld72,"128:KEY="..config.key_kmacs}
  local as2805msg = terminal.As2805Make( msg_flds)
  local ok = true

  local retmsg = tcpsend(as2805msg)
  if retmsg ~= "NOERROR" then txn.tcperror = true; ok = false end
  if ok then retmsg,as2805msg = tcprecv() end
    if ok and retmsg ~= "NOERROR" then txn.tcperror = true; ok = false end
	if ok and (not as2805msg or as2805msg=="") then txn.tcperror = true; ok = false; retmsg = "NO_RESPONSE" end
	if not ok then return do_obj_txn_nok(retmsg)
    else
		local fld63 =""
		local msg_t = {"GETS,12","GETS,13","GETS,39","GETS,48","GETS,61","GETS,63"}

		local errmsg,fld12,fld13,fld39,fld48,fld61,fld63 = terminal.As2805Break( as2805msg, msg_t )
		
		if fld39 and #fld39>0 then txn.rc = fld39 end
		if fld39 ~="00" then return do_obj_txn_nok(fld39)
		else
			if #fld63 > 5 then terminal.SetJsonValue("0630","63",fld63) end
			local banktime = nil
			if fld12 and fld13 then banktime = fld13..fld12 end
			if banktime and string.len(banktime)  == 10 then
				local yyyymm = terminal.Time( "YYYYMM")
				local yyyy,mm = string.sub(yyyymm,1,4),string.sub(yyyymm,5,6)
				if mm == "01" and string.sub(banktime,1,2) == "12" then yyyy = tonumber(yyyy) -1 end
				if mm == "12" and string.sub(banktime,1,2) == "01" then yyyy = tonumber(yyyy) +1 end
				terminal.TimeSet(yyyy..banktime,config.timeadjust)
			end
			local timestr = terminal.Time( "DD/MM/YY hh:mm" )
			if txn.manuallogon then
  			  local prtdata = "\\C\\H" .. config.servicename .."\\n\\n" ..
                  "\\C" .. config.merch_loc0 .."\\n" ..
                  "\\C" .. config.merch_loc1 .."\\n" ..
                  "\\CSOFTWARE CHECK\\n\\n" ..
                  "MERCHANT ID:\\R" .. string.sub(config.mid,-8) .. "\\n" ..
                  "TERMINAL ID:\\R" .. config.tid .."\\n" ..
                  "DATE/TIME:\\R" .. timestr .. "\\n" ..
                  "BANK REF:\\R" .. string.format("%06d",txn.stan).. "\\n" ..
                  "APPROVED\\R00\\n" ..
				  "\\4------------------------------------------\\n"
		      terminal.Print(prtdata,true)
		      checkPrint(prtdata)
			end
  			do_obj_saf_rev_start()
        	return do_obj_txn_finish()
	  end
    end
end

function do_obj_prchamount()
  if ecrd.AMT then txn.prchamt = ecrd.AMT end
  txn.cashamt = 0
  if not txn.prchamt then txn.prchamt = 0 end
  txn.totalamt = txn.prchamt + txn.cashamt
  return do_obj_swipecard()
end

function do_obj_swipecard()
  local scrlines = "WIDELBL,THIS,SWIPE/INSERT,1,C;".."WIDELBL,THIS,CARD,2,C;"
  local scrkeys  = KEY.CNCL
  local screvents = EVT.TIMEOUT+EVT.MCR+EVT.SCT_IN
  local cardreject = false
  if txn.emv_retry then scrlines = "WIDELBL,THIS,INSERT CARD,2,C;"; screvents = EVT.TIMEOUT+EVT.SCT_IN end

  if txn.chipcard and txn.emv.fallback then
    scrlines = "WIDELBL,THIS,SWIPE CARD,2,C;"
    scrkeys  = KEY.CNCL
    screvents = EVT.TIMEOUT+EVT.MCR
  elseif txn.swipefirst == 1 and not txn.ctls and not txn.cardname then
    local swipeflag,cardname = swipecheck( txn.track2)
	if swipeflag < 0 then cardreject = true
	elseif swipeflag == 0 then
      scrlines = "WIDELBL,THIS,INSERT CARD,2,C;"
      screvents = EVT.TIMEOUT+EVT.SCT_IN
      txn.swipefirst = nil
      txn.track2 = nil	
	elseif swipeflag > 0 then
		txn.cardname = cardname
	end
  end
  
  if txn.CTEMVRS and txn.CTEMVRS == "10" then return do_obj_transdial() --offline declined
  elseif txn.CTEMVRS and txn.CTEMVRS == "W30" then return do_obj_transdial() --offline declined
  elseif cardreject then return do_obj_txn_finish()
  elseif txn.swipefirst == 1 then return do_obj_account()
  elseif txn.chipcard and not txn.emv.fallback and not txn.emv_retry then 
	return do_obj_account()
  else
    txn.track2 = nil
    local screvent,_ = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)
    if screvent == "MCR" then
      txn.track2 = terminal.GetTrack(2)
      if txn.track2 == nil or #txn.track2 < 11 then return do_obj_swipecard()
      elseif not txn.emv.fallback then txn.swipefirst = 1;return do_obj_swipecard() -- double check the chipflag
      elseif txn.totalamt then return do_obj_account() 
	  else txn.swipefirst = 1; return do_obj_prchamount() end
    elseif screvent == "TIME" then
      return do_obj_trantimeout()
    elseif screvent == "CANCEL" then
      return do_obj_txn_finish()
    elseif screvent == "CHIP_CARD_IN" then
      txn.chipcard = true
      local ok = emv_init()
	  if ok ~= 0 then return do_obj_emv_error(ok)
      else txn.emv_retry = true
		if txn.totalamt then return do_obj_account() else return do_obj_prchamount() end
	  end
    end
  end
end

function get_cardinfo()
  terminal.DisplayObject("WIDELBL,THIS,READING DATA,2,C;".."WIDELBL,,26,4,C;",0,0,ScrnTimeoutZO)
  if txn.chipcard and not txn.emv.fallback then
	if txn.ctls == "CTLS_E" then
		local TxnTlvs = txn.TLVs
		local EMVPAN = ""
		local EMVPANSeq = ""
		local EMVTRACK2 = ""
		local EMV9F27 = ""
		local EMV9500 = ""
		local fARQC = "0"
		local fMaster = "0"
		
		EMVPAN = get_value_from_tlvs("5A00")
		if string.sub(EMVPAN,1,1) == "5" then fMaster = "1" end
		EMVPANSeq = get_value_from_tlvs("5F34")
		EMVTRACK2 = get_value_from_tlvs("5700")

		txn.ctlsPin = nil
		local EMVCVMR = get_value_from_tlvs("9F34")
		local EMV9F6C = get_value_from_tlvs("9F6C")
		local EMV9F66 = get_value_from_tlvs("9F66")

		if not txn.ctlsPin and #EMV9F66 > 0  then --VISA
			local tag9f66_2 = tonumber(string.sub( EMV9F66,3,4),16)
			local tag9f6c_1 = #EMV9F6C>0 and tonumber(string.sub( EMV9F6C,1,2),16) or 0
			local tag9f6c_2 = #EMV9F6C>0 and tonumber(string.sub( EMV9F6C,3,4),16) or 0
			
			local pinflag = hasbit(tag9f6c_1,bit(8)) 
			local signflag = hasbit(tag9f6c_1,bit(7)) or (--[[txn.totalamt >= txn.cvmlimit and]] EMV9F6C =="") --boyang TESTING
			if pinflag or signflag then
				if pinflag and config.no_pin then
					txn.rc = "W31"
					txn.tcperror = true
					return false,"CVM FAILED"
				end
				txn.ctlsPin = pinflag and "2" or signflag and "1" or "4"
			else txn.ctlsPin = "4"
			end
		elseif string.sub(EMVCVMR,2,2) == "2" then txn.ctlsPin = "2" --Enciphered PIN verified online
		elseif string.sub(EMVCVMR,2,2) == "E" then txn.ctlsPin = "1" --Signature (paper).
		elseif string.sub(EMVCVMR,2,2) == "F" then txn.ctlsPin = "4" --No CVM required.
		end

		if not txn.ctlsPin then txn.ctlsPin = "4" end
		if EMVPAN ~= "" then txn.emv.pan = EMVPAN end
		if EMVPANSeq~= "" then txn.emv.panseqnum = EMVPANSeq  end
		if EMVTRACK2~= "" then txn.emv.track2 = EMVTRACK2 end
		if txn.emv.track2 and #txn.emv.track2 > 37 then txn.emv.track2 = string.sub( txn.emv.track2,1,37) end	
	end
	
    if terminal.EmvReadAppData() == 0 then
       txn.emv.pan,txn.emv.panseqnum,txn.emv.track2 = terminal.EmvGetTagData(0x5A00,0x5F34,0x5700)
       if txn.emv.track2 and #txn.emv.track2 > 37 then txn.emv.track2 = string.sub( txn.emv.track2,1,37) end
    end
  end

  if txn.emv.track2 and #txn.emv.track2 < 37 or txn.track2 and #txn.track2 < 37 then
	local tr2 = txn.emv.track2 or txn.track2
	if string.sub(tr2,-1) == "F" then tr2 = string.sub(tr2,1,#tr2-1) end
	if txn.emv.track2 then txn.emv.track2 = tr2 else txn.track2 = tr2 end
   end

  local pan = txn.pan or txn.track2 or (txn.emv and txn.emv.track2) or (txn.emv and txn.emv.pan)
  if pan and #pan > 10 then 
	  get_trans_cv(pan)
	  if not txn.cardname then 
		local cardname_prefix= terminal.LocateCpat("CPAT_ALL",string.sub(pan,1,6))
	    txn.cardname = terminal.TextTable("CARD_NAME",string.sub(cardname_prefix,-2))
	  end
  end 
  return true
end

function get_trans_cv(trk2_pan)
	  txn.fullpan,txn.cv1,txn.cv2,txn.cv3,txn.cv4,txn.cv5 = get_trans_cv2(trk2_pan)
end

function get_trans_cv2(trk2_pan)
	  local pan = trk2_pan
	  local pan_etc = "XXXX0123456789ABCDEF"
	  if string.find (trk2_pan,"=") then _,_,pan,pan_etc = string.find(pan, "(%d*)=(%d*)") 
	  elseif string.find(trk2_pan,"D") then _,_,pan,pan_etc = string.find(pan, "(%d*)D(%d*)") 
	  end

	  local fullpan = string.match( pan,"%d+")
	  local cv1 = string.sub(pan,-16)
	  if #cv1 < 16 then cv1 = string.format("%016s", cv1) end
	  local cv5 = string.sub(pan_etc,5,20)
	  if #cv5 < 16 then cv5 = cv5 .. string.rep("0",16-#cv5) end 
	  local cv2 = string.sub(cv1,-8)..string.sub(cv1,1,8)
	  local cv3 = string.sub(cv1,1,8)..string.sub(cv5,1,8)
	  local cv4 = string.sub(cv1,-8)..string.sub(cv5,-8)
	  return fullpan,cv1,cv2,cv3,cv4,cv5
end

function do_obj_account()
  local acc4 = "CHQ"
  local acc5 = "SAV"
  local acc6 = "CR"
  local scrlines_nocr = "WIDELBL,,115,2,C;".. "BUTTONS_1,THIS,".. acc4 .. ",B,4;".. "BUTTONS_2,THIS,".. acc5 .. ",B,21;"
  local scrlines = scrlines_nocr .. "BUTTONS_3,THIS,".. acc6 .. ",B,38;"
  local scrkeys  = KEY.CNCL
  local screvents = EVT.TIMEOUT+EVT.SCT_OUT
  txn.account = ""
  local ok,desc = get_cardinfo()
 
  if not ok then
	return do_obj_txn_nok(desc)
  elseif txn.ctls and txn.CTEMVRS == "W30" then
	return do_obj_transdial()
  elseif txn.ctls or txn.cardname == "AMEX" or txn.cardname == "DINERS" or txn.cardname =="JCB" or txn.pan and #txn.pan > 10 then
		txn.account = "CREDIT" 
		scrlines = "WIDELBL,,119,2,C;".."WIDELBL,,26,3,C;"
		terminal.DisplayObject(scrlines,0,EVT.TIMEOUT,ScrnTimeoutHF)
		return do_obj_pin()
  else
	  if txn.cardname and string.sub(txn.cardname,1,5) == "DEBIT" then scrlines = scrlines_nocr end
	  local screvent = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)
	  if screvent == "TIME" then
		return do_obj_trantimeout()
	  elseif screvent == "BUTTONS_1" then
		txn.account = "CHEQUE"
		scrlines = "WIDELBL,,117,2,C;".."WIDELBL,,26,4,C;"
		terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
		return do_obj_pin()
	  elseif screvent == "BUTTONS_2" then
		txn.account = "SAVINGS"
		scrlines = "WIDELBL,,118,2,C;".."WIDELBL,,26,4,C;"
		terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
		return do_obj_pin()
	  elseif screvent == "BUTTONS_3" then
		txn.account = "CREDIT"
		scrlines = "WIDELBL,,119,2,C;".."WIDELBL,,26,4,C;"
		terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
		return do_obj_pin()
	  elseif screvent == "CHIP_CARD_OUT" then
		return do_obj_emv_error(101)
	elseif screvent == "KEY_CLR" then
		return do_obj_account()
	  else
		return do_obj_txn_finish()
	  end
	end
end

function do_obj_pin()

  if txn.chipcard and not txn.ctls and ( txn.account == "SAVINGS" or txn.account == "CHEQUE" ) then txn.earlyemv = true end
  if txn.pan then
	return do_obj_transdial()
  elseif txn.ctls and txn.chipcard and txn.ctlsPin ~= "2" and txn.ctlsPin ~= "3" then 
  	return do_obj_transdial()
  elseif txn.chipcard and not txn.earlyemv and not txn.emv.fallback and not txn.ctls then 
  	txn.pinblock_flag = "TODO";return do_obj_transdial()
  else
    local amtstr = string.format( "$%.2f", txn.totalamt/100.0 )
	amtstr = string.format( "%9s",amtstr)
    local scrlines = "WIDELBL,THIS,TOTAL:          " .. amtstr ..",2,3;"
	local pinbypass = false
	if txn.ctls and ( not txn.chipcard and txn.cardname ~="MASTERCARD" or txn.ctlsPin == "3") then pinbypass = true 
	elseif not txn.ctls and txn.account == "CREDIT" then pinbypass = true end
	scrlines = scrlines .. ( pinbypass and "PIN,,,P5,P11,0;" or scrlines .. "PIN,,,P5,P11,1;" ) 

    local scrkeys  = KEY.CNCL+KEY.NO_PIN+KEY.OK
    local screvents = EVT.TIMEOUT+EVT.SCT_OUT

    local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)
    if screvent == "KEY_OK" then
      txn.pinblock_flag = "TODO"
	  if txn.ctlsPin == "3" then txn.ctlsPin = "2" end
      return do_obj_transdial()
    elseif screvent =="KEY_NO_PIN" then
      txn.pinblock_flag = "NOPIN"
      return do_obj_transdial()
    elseif screvent == "TIME" then
      return do_obj_trantimeout()
	elseif screvent == "CHIP_CARD_OUT" then
	  return do_obj_emv_error(101)
    else
      return do_obj_txn_finish()
    end
  end
end

function do_obj_trantimeout()
  local scrlines = "WIDELBL,,120,2,C;" .. "WIDELBL,,122,4,C;"
  local scrkeys  = KEY.CNCL
  terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT+EVT.SCT_OUT,ScrnErrTimeout)
  return do_obj_txn_finish()
end

function do_obj_offline_check()
  if toomany_saf() then 
	txn.rc = "W30"
	txn.tcperror = true
	return do_obj_txn_nok("SAF LIMIT EXCEEDED")
  else
	local FAILED_TO_CONNECT = 3
	local ret = terminal.EmvUseHostData(FAILED_TO_CONNECT,"")
	if ret == 0 then 
		txn.rc = "Y3"
		--prepare 0220
		if txn.func ~= "AUTH" then
			local safmin,safnext = terminal.GetArrayRange("SAF")
			local saffile = "SAF"..safnext
			terminal.FileCopy("TXN_REQ", saffile)
			terminal.SetJsonValue(saffile,"0","220")
			terminal.SetJsonValue(saffile,"39",txn.rc)
			local mmddhhmmss = terminal.Time("MMDDhhmmss")
			terminal.SetJsonValue(saffile,"12",string.sub(mmddhhmmss,5,10))
			terminal.SetJsonValue(saffile,"13",string.sub(mmddhhmmss,1,4))
			
			if txn.cardname == "VISA" and txn.emv.tlv and #txn.emv.tlv > 0 then 
				terminal.EmvSetTagData(0x8A00,terminal.HexToString(txn.rc))
				local newtlv = txn.emv.tlv .. terminal.EmvPackTLV("8A009F5B")
				terminal.SetJsonValue(saffile,"55",newtlv)
			end
			terminal.SetJsonValue(saffile,"ROC",config.roc)
			terminal.SetArrayRange("SAF","",tostring(safnext+1))
			txn.saf_generated = true
		end
		return do_obj_txn_ok()
	else
		txn.rc = "Z3"
		return do_obj_txn_nok(txn.rc)
	end
  end
end

function do_obj_transdial()
  local emvok,emvret = true,0
  local tcpreturn = ""
  local nextstep = nil
  
  if not txn.ctls and txn.chipcard and not txn.emv.fallback then
    if not txn.earlyemv then
	  if terminal.EmvIsCardPresent() then
		local acc = (txn.account=="SAVINGS" and 0x10 or txn.account == "CHEQUE" and 0x20 or txn.account=="CREDIT" and 0x30)
		if emvret == 0 then
			emvret = terminal.EmvSetAccount(acc) end
		if emvret == 0 then
			emvret = terminal.EmvDataAuth() end
 		if emvret == 0 then
			emvret = terminal.EmvProcRestrict() end
 		if emvret == 0 then
			emvret = terminal.EmvCardholderVerify() end
 		if emvret == 0 then emvret = terminal.EmvProcess1stAC() end
 		if emvret == 137 then --ONLINE_REQUEST
		elseif emvret == 150 or emvret == 133  then -- TRANS_APPROVED or OFFLINE_APPROVED
		elseif emvret == 151 or emvret == 134  then -- TRANS_DECLINED or OFFLINE_DECLINED
		else emvok = false
		end
	  else emvret = 101
	  end
    end
  end
  if emvok then 
	prep_txnroc() 
  end

  if txn.chipcard and not txn.emv.fallback and not txn.earlyemv then txn.emvrcpt = get_emv_print_tags() end

  if txn.ctls == "CTLS_E" then
		if txn.CTEMVRS then
			if txn.CTEMVRS == "35" then -- Online 
				local scrlines = "WIDELBL,,21,4,C;"
				  terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
				  tcpreturn = tcpconnect()
				  if tcpreturn == "NOERROR" then 
					return do_obj_transstart()
				  else 
						txn.rc = "W21"
						return do_obj_txn_nok("CONNECT")
				  end
			elseif txn.CTEMVRS == "W30" or txn.CTEMVRS == " 0" and toomany_saf() then -- Ofline Auth
				txn.rc = "W30"
				txn.tcperror = true
				return do_obj_txn_nok("SAF LIMIT EXCEEDED")
			elseif txn.CTEMVRS == " 0" then -- Ofline Auth
				txn.rc = "Y1"
				local as2805msg = prepare_txn_req()
				if txn.func ~= "AUTH" then
					--prepare 0220
					local safmin,safnext = terminal.GetArrayRange("SAF")
					local saffile = "SAF"..safnext
					local ret = terminal.FileCopy( "TXN_REQ", saffile)
					terminal.SetJsonValue(saffile,"0","220")
					terminal.SetJsonValue(saffile,"39",txn.rc)
					terminal.SetArrayRange("SAF","",tostring(safnext+1))
					txn.saf_generated = true
				end
				return do_obj_txn_ok()
			elseif txn.CTEMVRS == "10" then -- Ofline Declined
				txn.rc = "Z1"
				return do_obj_txn_nok(txn.rc)
			else
				return do_obj_emv_error(txn.CTEMVRS)
			end
		else
			return do_obj_emv_error(101)
		end
  elseif  txn.chipcard and emvret == 137 or  emvret == 0 then --go online
      local scrlines = "WIDELBL,,21,4,C;"
      terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
      tcpreturn = tcpconnect()
      if tcpreturn == "NOERROR" then 
		return do_obj_transstart()
	  else 
		if  txn.chipcard and not txn.emv.fallback and not txn.earlyemv then
			txn.offline = true
			local as2805msg = prepare_txn_req()
			return do_obj_offline_check()
		else
	      	txn.rc = "W21"
			return do_obj_txn_nok("CONNECT")
		end
	  end
  elseif ( emvret == 150 or emvret == 133 ) and toomany_saf() then
	txn.rc = "W30"
	txn.tcperror = true
	return do_obj_txn_nok("SAF LIMIT EXCEEDED")
  elseif emvret == 150 or emvret == 133 then
    txn.rc = "Y1"
	local as2805msg = prepare_txn_req()
	if txn.func ~= "AUTH" then
		--prepare 0220
		local safmin,safnext = terminal.GetArrayRange("SAF")
		local saffile = "SAF"..safnext
		local ret = terminal.FileCopy( "TXN_REQ", saffile)
		terminal.SetJsonValue(saffile,"0","220")
		terminal.SetJsonValue(saffile,"39",txn.rc)
		if txn.cardname == "VISA" and txn.emv.tlv and #txn.emv.tlv > 0 then 
			terminal.EmvSetTagData(0x8A00,terminal.HexToString(txn.rc))
			local newtlv = txn.emv.tlv .. terminal.EmvPackTLV("8A009F5B")
			terminal.SetJsonValue(saffile,"55",newtlv)
		end
		terminal.SetArrayRange("SAF","",tostring(safnext+1))
		txn.saf_generated = true
	end
    return do_obj_txn_ok()
  elseif emvret == 151 or emvret == 134 then
    txn.rc = "Z1"
	return do_obj_txn_nok(txn.rc)
  elseif emvret ~= 0 then
    return do_obj_emv_error(emvret)
  end
end

function toomany_saf()
	local safmin,safmax= terminal.GetArrayRange("SAF")
	local cnt = safmax - safmin + 1
	local limit = config.saf_limit or 0
	if cnt > limit then return true else return false end
end

function trans_keys()
	local ok = true
	ok = ok and terminal.DesStore(txn.cv3..txn.cv4, "16", config.key_tmp)
    ok = ok and terminal.Owf("",config.key_card,config.key_tmp,0,txn.cv4..txn.cv3)
	ok = ok and terminal.Xor3Des( config.key_tmp, config.key_kt, "","28C028C028C028C0")
    ok = ok and terminal.Owf("",config.key_pin,config.key_tmp,0,txn.cv2..txn.cv2)
end

function do_obj_transstart()
  local scrlines = "WIDELBL,,27,2,C;" .."WIDELBL,,26,4,C;"
  terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
  local pan = txn.fullpan
  if txn.cv1 and txn.cv3 and txn.cv4 then
	trans_keys()
	local emvpin = txn.chipcard and not txn.ctls and not txn.earlyemv and not txn.emv.fallback
	txn.pinblock = terminal.PinBlockCba(config.key_card,config.key_pin,pan,"0")
  end
  return do_obj_txn_req()
end

function do_obj_saf_rev_start(nextstep,mode)
	saf_rev_check()
	local rev_exist = config.safsign and string.find(config.safsign,"+")
	local saf_exist = config.safsign and string.find(config.safsign,"*")
	local saf_sent,rev_sent = false,false
	local ok = true
	if (not mode or mode == "REVERSAL") and rev_exist then 
		rev_sent = do_obj_saf_rev_send("REVERSAL")
		if(not rev_sent) then ok = false end
	end
	if (not mode or mode == "SAF") and saf_exist and ok then saf_sent = do_obj_saf_rev_send("SAF") end
	if rev_sent or saf_sent then saf_rev_check() end
	if nextstep then return nextstep()
	else return 0 end
end

function saf_rev_check()
  local safmin,safmax= terminal.GetArrayRange("SAF")
  local revmin,revmax= terminal.GetArrayRange("REVERSAL")
  if safmax > safmin or revmax > revmin then
	config.safsign =( revmax>revmin and "+" or "" ) ..( safmax>safmin and "*" or "")
  else config.safsign = false
  end
end

function do_obj_saf_rev_send(fname)
  local safmin,safmax= terminal.GetArrayRange(fname)
  if safmin == safmax then return true
  else
    local txnbak = txn
    local msg_flds = {}
    local scrlines_saf = "WIDELBL,THIS,SENDING SAF,2,C,;" .."WIDELBL,,26,3,C,;"
	local scrlines_rev = "WIDELBL,THIS,SENDING REVERSAL,2,C,;" .."WIDELBL,,26,3,C,;"
    local retmsg = "NOERROR"
	local ok = false
    for i=safmin,safmax-1 do
      local saffile = fname .. i
      if terminal.FileExist(saffile) then
		ok = false
        local errmsg,fld0,fld2,fld3,fld4,fld11,fld12,fld13,fld14,fld15,fld22,fld23,fld24,fld25,fld32,fld35,fld37,fld38,fld41,fld39,fld42,fld44,fld47,fld54,fld55,fld48,fld64,fld90,roc
		local sent = false
        fld0,fld2,fld3,fld4,fld11,fld12,fld13,fld14,fld22,fld23,fld24,fld25,fld32,fld35,fld37,fld38,fld39,fld41,fld42,fld47,fld54,fld55,fld90,roc,sent =
          terminal.GetJsonValue(saffile,"0","2", "3", "4", "11","12","13", "14", "22", "23", "24", "25", "32", "35", "37","38","39","41", "42", "47", "54", "55","90","ROC","SENT")
		local msg_flds = {}
        if fname == "REVERSAL" then 
			if sent ~= "YES" then 
				fld90 = string.format("%04s",fld0)..string.format("%06s",fld11)..string.rep("0",32)
				fld11 = config.stan 
				terminal.SetJsonValue(saffile,"11",fld11)
				terminal.SetJsonValue(saffile,"90",fld90)
			end
			fld0 = "420"
			terminal.DisplayObject(scrlines_rev,0,0,ScrnTimeoutZO)
        	msg_flds = {"0:"..fld0,"2:"..fld2,"3:"..fld3,"4:"..fld4,"11:"..fld11,"14:"..fld14,"22:"..fld22,"23:"..fld23,"35:"..fld35,"41:"..fld41,"42:"..fld42,"47:"..fld47,"54:"..fld54,"55:"..fld55, "90:"..fld90, "128:KEY="..config.key_kmacs}
		else
			fld48 = terminal.HexToString("SAF")
			fld0 = "220"
			terminal.DisplayObject(scrlines_saf,0,0,ScrnTimeoutZO)
        	msg_flds = {"0:"..fld0,"2:"..fld2,"3:"..fld3,"4:"..fld4,"11:"..config.stan,"12:"..fld12,"13:"..fld13,"14:"..fld14,"22:"..fld22,"23:"..fld23,"25:"..fld25,"35:"..fld35,"38:"..fld38,"39:"..fld39,"41:"..fld41,"42:"..fld42,"47:"..fld47,"48:"..fld48,"54:"..fld54,"55:"..fld55, "64:KEY="..config.key_kmacs}
		end

		local cv1 = ""
		_,cv1 = get_trans_cv2(#fld2 >10 and fld2 or #fld35 > 10 and fld35 or "0123456789ABCDEF")
		terminal.DesStore(cv1,"8", config.key_tmp)
		terminal.Owf(config.key_tmp,config.key_kmacs,config.key_kt_x ,0)

        local as2805msg = terminal.As2805Make(msg_flds)
		if sent == "YES" then as2805msg = string.sub(as2805msg,1,3).."1"..string.sub(as2805msg,5) end 
		retmsg = tcpconnect() 
        if retmsg == "NOERROR" and as2805msg ~= "" then retmsg = tcpsend(as2805msg) end
		terminal.SetJsonValue(saffile,"SENT","YES")
        if retmsg ~= "NOERROR" then break end
        as2805msg = ""
        retmsg,as2805msg = tcprecv()
        if retmsg ~= "NOERROR" then break end
		if not as2805msg or as2805msg == "" then break end
        local msg_t = { "GET,12","GET,13", "GET,15","IGN,24","GETS,39","GETS,44","GETS,47","GETS,48","GETS,64" }
        if as2805msg ~= "" then
		  errmsg,fld12,fld13,fld15,fld39,fld44,fld47,fld48,fld55,fld64 = terminal.As2805Break( as2805msg, msg_t )
		  if fld39 == "98" then config.logok = false ; check_logon_ok() end	
          if fld39 ~= "00" and fld39 ~= "21" then break end
          terminal.FileRemove(fname..i)
          terminal.SetArrayRange(fname,tostring(i+1),"")
		  ok = true
		end
      end
    end
	if ok then saf_rev_check() end
	txn = txnbak
	return ok
  end
end

function prepare_txn_req()
    local msg_flds = {}
	local msgid = txn.rc and txn.rc == "Y1" and "220" or "200"
	txn.mti = msgid
    local proccode = ""

	local retmsg = nil
	local rev_exist = config.safsign and string.find(config.safsign,"+")
	if msgid == "200" and rev_exist then
		local rev_sent = do_obj_saf_rev_send("REVERSAL") 
		if not rev_sent then retmsg = "REVERSAL PENDING" end
  		local pan = txn.fullpan
		--get_trans_cv(pan)
		trans_keys()
		txn.pinblock = terminal.PinBlockCba(config.key_card,config.key_pin,pan,"0")
	end
	
    if txn.func == "PRCH" then  if txn.cashamt > 0 then proccode = "09" else proccode = "00" end
    elseif txn.func == "CASH" then  proccode = "01"
    elseif txn.func == "RFND" then  proccode = "20"
    elseif txn.func == "AUTH" then  proccode = "30" ; msgid = "100"
    elseif txn.func == "COMP" then  proccode = "00" ; msgid = "220"
    elseif txn.func == "VOID" then  proccode = "02"   end
    table.insert(msg_flds,"0:"..msgid)
    if txn.pan then table.insert(msg_flds,"2:"..txn.pan) end
    if txn.account == "SAVINGS" then proccode = proccode .. "1000"
    elseif txn.account == "CHEQUE" then proccode = proccode .. "2000"
    elseif txn.account == "CREDIT" then proccode = proccode .. "3000" end
    table.insert(msg_flds,"3:" .. proccode)
    table.insert(msg_flds,"4:" .. tostring(txn.totalamt))
    table.insert(msg_flds,"11:" .. config.stan)
    if msgid == "220" then
      local mmddhhmmss = terminal.Time( "MMDDhhmmss")
      table.insert(msg_flds,"13:"..string.sub(mmddhhmmss,1,4))
      table.insert(msg_flds,"12:"..string.sub(mmddhhmmss,5,10))
    end
    if txn.expiry then table.insert(msg_flds,"14:"..string.sub(txn.expiry,3,4)..string.sub(txn.expiry,1,2)) end
    local posentry = ""
    if txn.pan  then posentry = "01"
	elseif txn.ctls and not txn.chipcard then posentry = "81"
	elseif txn.chipcard and txn.emv.fallback then posentry = "62"
    elseif txn.chipcard and txn.ctls then posentry = "07"
	elseif txn.chipcard and txn.emv.pan then posentry = "05"
    elseif txn.track2  then posentry = "02"
    end

	local cvmr = txn.chipcard and not txn.earlyemv and not txn.emv.fallback and not txn.ctls and terminal.EmvGetTagData(0x9f34)
	cvmr = cvmr and string.sub(cvmr,2,2)
	if cvmr then
		if cvmr == "1" or cvmr == "3" or cvmr == "4" or cvmr == "5" then
			txn.offlinepin = true 
		end 
	end
	if txn.chipcard and txn.offlinepin then
	    posentry = posentry .. "9"
	else
		posentry = posentry .. "1"
	end
	
    table.insert(msg_flds,"22:" .. posentry)
    if txn.chipcard and txn.emv.panseqnum then table.insert(msg_flds,"23:" .. txn.emv.panseqnum) end
    if txn.poscc == nil then txn.poscc = "42" end
    table.insert(msg_flds,"25:" .. txn.poscc)
    if txn.track2 then table.insert(msg_flds,"35:" .. txn.track2)
    elseif txn.chipcard and txn.emv.track2 then table.insert(msg_flds,"35:" .. txn.emv.track2) end
    table.insert(msg_flds,"41:" ..config.tid)
    table.insert(msg_flds,"42:" ..config.mid)
    local fld47 = ""
    local tcc = "07"
	
    if txn.ccv then fld47 = fld47 ..txn.ccv  end
    fld47 = fld47 .. "TCC" ..tcc.."\\"
    table.insert(msg_flds,"47:" ..terminal.HexToString(fld47))
    
    if txn.pinblock and #txn.pinblock > 0 then 
		table.insert(msg_flds,"52:" ..txn.pinblock) 
	end
    if txn.chipcard and not txn.earlyemv and not txn.emv.fallback then
	  local t9f53 =""
	  local tlvs = ""
	  if txn.ctls == "CTLS_E" then
			local TxnTlvs = txn.TLVs
			local EMV5000 = ""
			local EMV9f02 = ""
			local EMV9f03 = ""
			local EMV9f26 = ""
			local EMV8200 = ""
			local EMV9f36 = ""
			local EMV9f34 = ""
			local EMV9f27 = ""
			local EMV9f1e = ""
			local EMV9f10 = ""
			local EMV9f33 = ""
			local EMV9f1a = ""
			local EMV9500 = ""
			local EMV5f2a = ""
			local EMV9a00 = ""
			local EMV9c00 = ""
			local EMV9f37 = ""
			local tagvalue = ""
			tagvalue = get_value_from_tlvs("5000")
			EMV5000 = "50".. string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("9F02")
			EMV9f02 = "9F02"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9F03")
			EMV9f03 = "9F03"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9F26")
			EMV9f26 = "9F26"..string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("8200")
			EMV8200 = "82".. string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("9F36")
			EMV9f36 = "9F36"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9F34")
			EMV9f34 = "9F34"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9F27")
			EMV9f27 = "9F27"..string.format("%02X",#tagvalue/2)  .. tagvalue
  			EMV9f1e = "9F1E08"..terminal.HexToString(string.sub(config.serialno,-8))
			tagvalue = get_value_from_tlvs("9F10")
			EMV9f10 = "9F10"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9F33")
			EMV9f33 = "9F33"..string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("9F1A")
			EMV9f1a = "9F1A"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9500")
			EMV9500 = "95".. string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("5F2A")
			EMV5f2a = "5F2A"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9A00")
			EMV9a00 = "9A".. string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("9C00")
			EMV9c00 = "9C".. string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("9F37")
			EMV9f37 = "9F37"..string.format("%02X",#tagvalue/2) .. tagvalue

			tlvs=tlvs..EMV9f02..EMV9f03..EMV9f26..EMV8200..EMV9f36..EMV9f34..EMV9f27..EMV9f1e..EMV9f10..EMV9f33..EMV9f1a..EMV9500..EMV5f2a..EMV9a00..EMV9c00..EMV9f37
	  else
      tlvs = terminal.EmvPackTLV("9F02".."9F03".."9F26".."8200".."9F36".."9F34".."9F27".."9F10".."9F33".."9F1A".."9500".."5F2A".."9A00".."9C00".."9F35".."9F37").."9F1E08"..terminal.HexToString(string.sub(config.serialno,-8))
	  end
      txn.emv.tlv = tlvs
      table.insert(msg_flds,"55:" ..tlvs)
    end
	
	
     terminal.DesStore(txn.cv1,"8", config.key_tmp) 
     terminal.Owf(config.key_tmp,config.key_kmacs,config.key_kt_x ,0)
	 
    table.insert(msg_flds,"64:KEY=" .. config.key_kmacs)
    local as2805msg = terminal.As2805Make( msg_flds)

    if as2805msg ~= "" then
      local txnstr = "{TYPE:DATA,NAME:TXN_REQ,GROUP:CBA,VERSION:1,ROC:"..config.roc.."," .. table.concat(msg_flds,",") .."}"
      terminal.NewObject("TXN_REQ",txnstr)
    end
    return as2805msg,retmsg
end

function do_obj_txn_req()
	local as2805msg,retmsg = prepare_txn_req()
	if retmsg then
		if  txn.chipcard and not txn.emv.fallback and not txn.earlyemv then
			txn.offline = true
			return do_obj_offline_check()
		else
			return do_obj_txn_nok(retmsg)
		end
	elseif as2805msg == "" then txn.tcperror = true 
		return do_obj_txn_nok(retmsg)
	else
		if terminal.FileExist("TXN_REQ") then
			local fld0 = terminal.GetJsonValue("TXN_REQ","0")
			if fld0 == "200" then
				local revfile = "REV_TODO"
				local ret = terminal.FileCopy( "TXN_REQ", revfile)
				if txn.cardname == "VISA" and txn.emv.tlv and #txn.emv.tlv > 0 then 
					local newtlv = txn.emv.tlv .. terminal.EmvPackTLV("9F5B")
					terminal.SetJsonValue(revfile,"55",newtlv)
				end
			end
		end

		retmsg = tcpsend(as2805msg)
		if retmsg ~= "NOERROR" then 
			if retmsg == "NO_RESPONSE" or retmsg == "TIMEOUT" then copy_txn_to_saf() end
			if  txn.chipcard and not txn.emv.fallback and not txn.earlyemv then
				txn.offline = true
				return do_obj_offline_check()
			else txn.tcperror = true 
				return do_obj_txn_nok(retmsg)
			end
		else return do_obj_txn_resp()
		end
	end
end

function do_obj_txn_resp()
  local scrlines = "WIDELBL,,27,2,C;" .. "WIDELBL,,26,4,C;"
  terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
  local rcvmsg,errmsg,fld12,fld13,fld15,fld37,fld38,fld39,fld44,fld47,fld48,fld55,fld64
  errmsg, rcvmsg = tcprecv()
  if errmsg == "MAC" or errmsg == "NO_RESPONSE" or errmsg == "TIMEOUT" then copy_txn_to_saf() end

  if errmsg == "MAC" then 
	 txn.tcperror = true
	 return do_obj_txn_nok("MAC") -- mac error
  elseif errmsg ~= "NOERROR" or not rcvmsg or rcvmsg == "" then 
	if errmsg == "NOERROR" then errmsg = "NO_RESPONSE" end
	if  txn.chipcard and not txn.emv.fallback and not txn.earlyemv then
		txn.offline = true
		return do_obj_offline_check()
	else txn.tcperror = true
		return do_obj_txn_nok(errmsg)
	end
  else
    txn.host_response = true
    local msg_t = {"GET,12","GET,13","GET,15","GETS,37","GETS,38","GETS,39","GETS,48","GETS,55","GETS,64" }
    errmsg,fld12,fld13,fld15,fld37,fld38,fld39,fld48,fld55,fld64 = terminal.As2805Break( rcvmsg, msg_t )
    if fld12 and fld13 then txn.time = fld13..fld12 end
    if fld38 and #fld38>0 then txn.authid = fld38 end
    if fld39 and #fld39>0 then txn.rc = fld39 end

    if errmsg ~= "NOERROR" then return do_obj_txn_nok(errmsg)  -- as2805 error
    elseif fld39 ~= "00" and fld39 ~= "08" then 
      local HOST_DECLINED = 2
      if not txn.ctls and txn.chipcard and not txn.emv.fallback and not txn.earlyemv then terminal.EmvUseHostData(HOST_DECLINED,fld55) end
      return do_obj_txn_nok(errmsg)
    else 
      if txn.time and string.len(txn.time)  == 10 then
        local yyyymm = terminal.Time( "YYYYMM")
        local yyyy,mm = string.sub(yyyymm,1,4),string.sub(yyyymm,5,6)
        if mm == "01" and string.sub(txn.time,1,2) == "12" then yyyy = tonumber(yyyy) -1 end
        if mm == "12" and string.sub(txn.time,1,2) == "01" then yyyy = tonumber(yyyy) +1 end
		txn.time = yyyy..txn.time
        terminal.TimeSet(txn.time,config.timeadjust)
      end
      local HOST_AUTHORISED,emvok = 1,0

      if not txn.ctls and txn.chipcard and not txn.emv.fallback and not txn.earlyemv then
		local rc = terminal.HexToString(txn.rc)
		terminal.EmvSetTagData(0x8A00,rc)
		emvok = terminal.EmvUseHostData(HOST_AUTHORISED,fld55) 
		if txn.emvrcpt then
			local tsi = terminal.EmvGetTagData(0x9B00)
			local tsi_s = "TSI:\\R".. tsi.."\\n"
			txn.emvrcpt = string.gsub(txn.emvrcpt, "TSI:\\R....\\n",tsi_s )
		end
	  end
      if emvok ~= 0--[[TRANS_DECLINE]] then 
        local safmin,safnext = terminal.GetArrayRange("REVERSAL")
        local saffile = "REVERSAL"..safnext
        local ret = terminal.FileCopy( "TXN_REQ", saffile)
		txn.rc = "Z4"
		if txn.cardname == "VISA" and txn.emv.tlv and #txn.emv.tlv > 0 then 
			terminal.EmvSetTagData(0x8A00,terminal.HexToString(txn.rc))
			local newtlv = txn.emv.tlv .. terminal.EmvPackTLV("9F5B")
			terminal.SetJsonValue(saffile,"55",newtlv)
		end
        terminal.SetArrayRange("REVERSAL","",tostring(safnext+1))
        return do_obj_txn_nok(txn.rc) 
      else
		return do_obj_txn_ok() 
	  end
    end
  end
end

function do_obj_txn_ok()
    local signflag = ( not ( txn.ctls and txn.chipcard) and txn.pinblock_flag == "NOPIN" or txn.ctlsPin == "1" or txn.ctlsPin == "3" or ( txn.rc == "08" or (txn.chipcard and terminal.EmvGlobal("GET","SIGN")) or txn.pan))
	local scrlines,resultstr = "",""
	scrlines =  "WIDELBL,,30,2,C;" .."WIDELBL,,147,4,C;" 
	if signflag and txn.rc == "00" then txn.rc = "08" elseif not signflag and txn.rc == "08" then txn.rc = "00" end
	local resultstr_nosign = "APPROVED\\R" .. txn.rc.."\\n" 
	resultstr = resultstr_nosign
	
	if signflag then 
		scrlines = "WIDELBL,,31,2,C;" .."WIDELBL,,32,4,C;" ;
		resultstr = "APPROVED\\R" .. txn.rc.."\\n" .. "CARDHOLDER SIGN HERE:\\n\\n\\n\\n\\nX______________________\\n"
	end
    terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
    local who = "MERCHANT COPY\\n"
	txn.mreceipt= get_ipay_print( who, true, resultstr)
	local who1 = "CUSTOMER COPY\\n"
	txn.creceipt= get_ipay_print( who1, true, resultstr_nosign)

	if not txn.emvrcpt then txn.emvrcpt = get_emv_print_tags() end

    local prtvalue = (ecrd.HEADER or "") ..(ecrd.HEADER_OK or "") .. txn.mreceipt ..(ecrd.MTRAILER or "")
		  
    terminal.Print(prtvalue,true)
	checkPrint(prtvalue)
	terminal.FileRemove("REV_TODO")
	do_obj_iecr_end(0);

    local prt_keep = (ecrd.HEADER or "") .. (ecrd.HEADER_OK or "") ..prtvalue.. (ecrd.MTRAILER or "") .."\\n"
	local signok = true
	if signflag then signok = do_obj_txn_sig() end
	if signok then
      terminal.SetJsonValue("DUPLICATE","RECEIPT",prt_keep)
      return do_obj_txn_second_copy()
	else
	  itaxi_pay_revert(0)
	  if txn.rc == "Y1" or txn.rc == "Y3" then return do_obj_txn_finish() else
	  return do_obj_saf_rev_start(do_obj_txn_finish,"REVERSAL") end
	end
end

function update_total()
	local cardname = txn.cardname
	if txn.account ~= "CREDIT" then cardname = "DEBIT" end
    local prchnum,prchamt=terminal.GetJsonValueInt("SHFT","PRCHNUM","PRCHAMT")
    local cr_s_num,cr_s_amt,cr_r_num,cr_r_amt,dr_s_num,dr_s_amt,dr_r_num,dr_r_amt,auth_s_num,auth_s_amt,auth_r_num,auth_r_amt,card_prch_num,card_prch_amt,card_rfnd_num,card_rfnd_amt=
	terminal.GetJsonValueInt("SHFTSTTL","CR_PRCHNUM","CR_PRCHAMT","CR_RFNDNUM","CR_RFNDAMT","DR_PRCHNUM","DR_PRCHAMT","DR_RFNDNUM","DR_RFNDAMT","AUTH_PRCHNUM","AUTH_PRCHAMT","AUTH_RFNDNUM","AUTH_RFNDAMT",cardname.."_PRCHNUM",cardname.."_PRCHAMT",cardname.."_RFNDNUM",cardname.."_RFNDAMT")
    if txn.prchamt>0 and (txn.func == "PRCH" or txn.func == "COMP") then
      terminal.SetJsonValue("SHFT","PRCHAMT",prchamt+txn.prchamt)
      terminal.SetJsonValue("SHFT","PRCHNUM",prchnum+1)
	end
	
	if txn.totalamt>0 and (txn.func == "PRCH" ) then
      terminal.SetJsonValue("SHFTSTTL",cardname.."_PRCHAMT",card_prch_amt+txn.totalamt)
      terminal.SetJsonValue("SHFTSTTL",cardname.."_PRCHNUM",card_prch_num+1)
      if txn.account == "CREDIT" then
        terminal.SetJsonValue("SHFTSTTL","CR_PRCHAMT",cr_s_amt+txn.totalamt)
        terminal.SetJsonValue("SHFTSTTL","CR_PRCHNUM",cr_s_num+1)
      else
        terminal.SetJsonValue("SHFTSTTL","DR_PRCHAMT",dr_s_amt+txn.totalamt)
        terminal.SetJsonValue("SHFTSTTL","DR_PRCHNUM",dr_s_num+1)
      end
   end
end

function do_obj_txn_sig()
  local scrlines = "WIDELBL,,33,3,C;" .."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
  if txn.chipcard and terminal.EmvIsCardPresent() then
  	local scrlines_card = "WIDELBL,THIS,REMOVE CARD,2,C;".."WIDELBL,THIS,CHECK SIGNATURE,3,C;"
	terminal.DisplayObject(scrlines_card,0,EVT.SCT_OUT+EVT.TIMEOUT,15000)
  end
  local screvent,_ = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,120000)
  if screvent =="BUTTONS_1" or screvent =="KEY_OK" or screvent =="TIME" then
  	terminal.DisplayObject("WIDELBL,THIS,SIGNATURE APPROVED,3,C;",KEY.OK,EVT.TIMEOUT,2000)
	if screvent == "TIME" then terminal.ErrorBeep() end
    return true
  elseif screvent =="BUTTONS_2" or screvent =="CANCEL" then
	  local scrlines = "WIDELBL,THIS,WARNING,2,C;" .."TEXT,THIS,YOU ARE ABOUT TO,4,C;"..
	  "TEXT,THIS,DECLINE THIS FARE.,5,C;".."TEXT,THIS,DO YOU WANT TO,6,C;".."TEXT,THIS,CANCEL PAYMENT,7,C;".."BUTTONS_1,THIS,YES,10,10;".. "BUTTONS_2,THIS,NO,10,33;"
	  local screvent,_ = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,300000)
	  if screvent == "BUTTONS_1" or screvent == "KEY_OK" or screvent == "TIME" then
		if txn.tcpsent then  --not completion offline
			local safmin,safnext = terminal.GetArrayRange("REVERSAL")
			local saffile = "REVERSAL"..safnext
			local ret = terminal.FileCopy( "TXN_REQ", saffile)
			if txn.cardname == "VISA" and  txn.emv.tlv and #txn.emv.tlv > 0 then 
				local newtlv = txn.emv.tlv .. terminal.EmvPackTLV("8A009F5B")
				terminal.SetJsonValue(saffile,"55",newtlv)
			end
			terminal.SetArrayRange("REVERSAL","",safnext+1)
		end
		if txn.saf_generated then
			local safmin,safnext = terminal.GetArrayRange("SAF")
			terminal.FileRemove("SAF"..(safnext-1))
			terminal.SetArrayRange("SAF","",safnext-1)
		end
				
		txn.rc = "T8"
		local resultstr= "DECLINED\\RT5\\nSIGNATURE MISMATCH\\n"
		local who = "MERCHANT COPY\\n"
		local prtvalue = (ecrd.HEADER or "") .. get_ipay_print( who, false, resultstr)..(ecrd.MTRAILER or "") 
		terminal.Print(prtvalue,true)
		checkPrint(prtvalue)
		local prtvalue2 = ""
		local scrlines = "WIDELBL,,36,4,C;" .."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
		local screvent,_ = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,ScrnTimeout)
		who = "CUSTOMER COPY\\n"
		prtvalue2 = (ecrd.HEADER or "") .. get_ipay_print( who, false, resultstr)..(ecrd.MTRAILER or "") .."\\n"
		if screvent == "BUTTONS_1" or screvent == "TIME" or screvent == "KEY_OK" then
			terminal.Print(prtvalue2,true)
			checkPrint(prtvalue2)
		end

		local rcptfile = "TAXI_Dclnd"
		local data = "{TYPE:DATA,NAME:"..rcptfile..",GROUP:CBA,VERSION:2.0,HEADER:".. ecrd.HEADER..",CRCPT:"..prtvalue2..",MRECEIPT:"..prtvalue..",TRAILER:"..ecrd.MTRAILER..",EMVRCPT:"..txn.emvrcpt.."}"
		terminal.NewObject(rcptfile,data)
		return false 
	  elseif screvent == "BUTTONS_2" or screvent == "CANCEL" then
		return do_obj_txn_sig()
	  end
  end
end

function do_obj_txn_second_copy()
  local scrlines = "WIDELBL,,36,4,C;" .."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
  local screvent,_ = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,ScrnTimeout)

  if screvent == "BUTTONS_1" or screvent == "TIME" or screvent == "KEY_OK" then
    scrlines = "WIDELBL,,37,2,C;" .."WIDELBL,,26,4,C;"
    terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)

    local resultstr= (txn.rc ~= "Y1" and txn.rc ~= "Y3" and ( "APPROVED\\R") or "OFFLINE APPROVED\\R") .. txn.rc.."\\n"
    local who = "CUSTOMER\ COPY\\n"
	local prtvalue = (ecrd.HEADER or "") .. (ecrd.HEADER_OK or "") .. get_ipay_print( who, true, resultstr) 
	.. (ecrd.CTRAILER or "") 
	
    terminal.Print(prtvalue,true)
	checkPrint(prtvalue)
    terminal.SetJsonValue("DUPLICATE","RECEIPT",prtvalue)
  end
  update_total()
  return do_obj_txn_finish()
end

function copy_txn_to_saf()
	if terminal.FileExist("TXN_REQ") then
		local fld0 = terminal.GetJsonValue("TXN_REQ","0")
		if fld0 == "200" then
			local safmin,safnext = terminal.GetArrayRange("REVERSAL")
			local saffile = "REVERSAL"..safnext
			local ret = terminal.FileCopy( "TXN_REQ", saffile)
			if txn.cardname == "VISA" and txn.emv.tlv and #txn.emv.tlv > 0 then 
				local newtlv = txn.emv.tlv .. terminal.EmvPackTLV("9F5B")
				terminal.SetJsonValue(saffile,"55",newtlv)
			end
			terminal.SetArrayRange("REVERSAL","",safnext+1)
		end
	end
end

function do_obj_txn_nok(tcperrmsg)
  local errcode,errmsg,errline2 = "","",""
  if not txn.rc then txn.rc = "W21" end
  if txn.tcperror then errcode,errmsg = tcperrorcode(tcperrmsg),tcperrmsg 
  else errcode,errmsg = txn.rc, ""
    local rc = txn.rc
	if string.sub(txn.rc,1,1)~="Z" then rc = "H"..rc end
    errmsg = cba_errorcode(rc)
  end
  local evt,itimeout = EVT.TIMEOUT, ScrnTimeoutHF
  if txn.ctls and txn.rc == "65" then 
	errline2 = "WIDELBL,THIS,PLEASE INSERT CARD,4,C;"
	evt = EVT.SCT_IN+EVT.TIMEOUT
	itimeout = 15000
  end
  
  local scrlines = "WIDELBL,,120,2,C;"
  scrlines = scrlines.. "WIDELBL,THIS," .. (errmsg or "") ..",4,C;"..errline2
  terminal.ErrorBeep()
  local screvent =terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL+KEY.OK,evt,itimeout)
  if txn.rc and txn.rc == "98" then config.logok = false
	do_obj_txn_nok_print(errcode,errmsg,1)  
	check_logon_ok() 
	return do_obj_txn_finish()
  elseif screvent == "CHIP_CARD_IN" then 
  	do_obj_txn_nok_print(errcode,errmsg,1)
	terminal.FileRemove("TXN_REQ")
	terminal.FileRemove("REV_TODO")
    return do_obj_idle()
  else return do_obj_txn_nok_print(errcode,errmsg)
  end
end

function do_obj_txn_nok_print(errcode,errmsg,ret)
	local result_str = "DECLINED\\R"..(errcode or "").."\\n" .. (errmsg or "") .."\\n"
	local amttrans = txn.totalamt and txn.totalamt > 0
	local who = amttrans and "MERCHANT COPY\\n" or ""
	local print_info1 = get_ipay_print_nok(who,result_str)
	local prtvalue = (ecrd.HEADER or "") ..print_info1.. (ecrd.MTRAILER or "") .."\\n"
    terminal.Print(prtvalue,true)
	checkPrint(prtvalue)
	if amttrans then
		local scrlines = "WIDELBL,,36,4,C;" .."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
		local screvent,_ = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,ScrnTimeout)
		who = "CUSTOMER COPY\\n"
		local print_info2 = get_ipay_print_nok(who,result_str)
		prtvalue = (ecrd.HEADER or "") ..print_info2.. (ecrd.MTRAILER or "") 
		if screvent == "BUTTONS_1" or screvent == "TIME" or screvent == "KEY_OK" then
			scrlines = "WIDELBL,,37,4,C;" .."WIDELBL,,26,6,C;"
			terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
			terminal.Print(prtvalue,true)
			checkPrint(prtvalue)
		end
		local rcptfile = "TAXI_Dclnd"
		if not txn.emvrcpt then txn.emvrcpt = get_emv_print_tags() end
		local data = "{TYPE:DATA,NAME:"..rcptfile..",GROUP:CBA,VERSION:2.0,HEADER:".. ecrd.HEADER..",CRCPT:"..print_info2..",MRECEIPT:"..print_info1..",TRAILER:"..ecrd.MTRAILER..",EMVRCPT:"..txn.emvrcpt.."}"
		terminal.NewObject(rcptfile,data)
		if txn.emvrcpt ~= "" then terminal.NewObject("LASTEMV_RCPT",data) end
	end
	if ret then return ret else return do_obj_txn_finish() end
end

function do_obj_logon_init()
  local scrlines = ",,78,4,C;" .. "BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
  local scrkeys  = KEY.CLR+KEY.CNCL+KEY.OK
  local screvents = EVT.TIMEOUT
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)

  if screvent == "KEY_OK" or screvent == "BUTTONS_1" then
    scrlines = "WIDELBL,,21,4,C;"
	screvent,scrinput = terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
	txn.manuallogon = true
	txn.func = "LGON"
    return do_obj_logon_start()
  else
    return do_obj_txn_finish()
  end
end

function do_obj_logon_start()
  local rc = ""
  local tcpreturn = tcpconnect()
  if tcpreturn == "NOERROR" then
    return do_obj_logon_req()
  else
    return do_obj_logon_nok(tcpreturn)
  end
end

function do_obj_logon_req()
  if config.logonstatus == ""  or config.logonstatus == "191" then
	config.logonstatus = "191"
	terminal.SetJsonValue("CONFIG","LOGON_STATUS",config.logonstatus)
  end

   local fld48 = ""
   local msg_flds = {}
   if config.logonstatus == "191" then
	  local SKmanPKtcuMOD, SKmanPKtcuEXP = terminal.GetJsonValue("CONFIG","SKmanPKtcuMOD","SKmanPKtcuEXP")
      fld48 = SKmanPKtcuMOD .. SKmanPKtcuEXP .. config.ppid
	  msg_flds = {"0:9820","11:"..config.stan, "41:"..config.tid, "42:"..config.mid, "48:"..fld48, "63:".."33","70:".. config.logonstatus}
   elseif config.logonstatus == "192" then
      local ok,kivalue = terminal.DesRandom("16",config.key_ki)
	  local randomnumber = ""
	  if config.randomnumber then randomnumber = config.randomnumber else terminal.GetJsonValue ("CONFIG","RANDOMNUM", randomnumber ) end
  	  local timestr = terminal.Time( "YYDDMMhhmmss" ) 
	  local block = kivalue .. config.ppid .. timestr .. randomnumber

	  --sSKTCU (ePKSP (KI, PPID, DTS, RN))
	  local key_PKsp, key_SKtcu = terminal.GetJsonValue("IRIS_CFG","PKSP","SKTCU")
      local block1 = terminal.RsaEncrypt( block, key_PKsp, 112 )
	  if not config.SKtcu then
	  	local sktcu = terminal.GetJsonValue("CONFIG","SKtcu" )
	  	if sktcu ~= "" then terminal.RsaStore( sktcu,key_SKtcu ) end
		config.SKtcu = sktcu
	  end
      fld48 = terminal.RsaEncrypt( block1, key_SKtcu, 120 ) .. config.ppid -- SKtcu stored in slot 4
	  msg_flds = {"0:9820","11:"..config.stan, "41:"..config.tid, "42:"..config.mid, "48:"..fld48, "63:".."33","70:".. config.logonstatus}
   elseif config.logonstatus == "001" then
	  
	  local ok = terminal.Xor3Des( config.key_kt_x, config.key_kt, "","24C024C024C024C0")
	  terminal.DesStore("0123456789ABCDEF","8", config.key_tmp)
	  ok = terminal.Owf(config.key_tmp,config.key_kmacs,config.key_kt_x,0)

      fld48 = config.ppid .. string.sub(terminal.Enc (config.ppid,"","16",config.key_kia),1,8)
	  local fld47 = terminal.HexToString("TCC07\\");
	  msg_flds = {"0:0800","11:"..config.stan, "33:"..config.aiic,"41:"..config.tid, "42:"..config.mid, "47:".. fld47, "48:"..fld48, "70:".. config.logonstatus,"128:KEY="..config.key_kmacs}
   elseif config.logonstatus == "194" then
	  fld48 = string.sub( terminal.Enc (config.ppid,"","16",config.key_kia),1,8)
	  msg_flds = {"0:9820","11:"..config.stan, "41:"..config.tid, "42:"..config.mid, "48:"..fld48, "70:".. config.logonstatus}
   end

    local as2805msg = terminal.As2805Make( msg_flds)
    local retmsg = ""
    if as2805msg ~= "" then retmsg = tcpsend(as2805msg) end
    if retmsg ~= "NOERROR" then txn.tcperror = true; return do_obj_logon_nok(retmsg)
    else return do_obj_logon_resp() end
end

function do_obj_logon_resp()
  local errmsg, rcvmsg = tcprecv()
  if errmsg ~= "NOERROR" then
    txn.tcperror = true
    return do_obj_logon_nok(errmsg)
  elseif not rcvmsg or rcvmsg == "" then
    txn.tcperror = true
	return do_obj_logon_nok("NO_RESPONSE")
  else
    local msg_t = {"GET,11","GET,12","GET,13","GETS,33","GETS,39","GETS,44","GETS,47","GET,48","GET,70" }
    local errmsg,fld11,fld12,fld13,fld33,fld39,fld44,fld47,fld48,fld70 = terminal.As2805Break( rcvmsg, msg_t )
    if fld39 and #fld39>0 then txn.rc = fld39 end


    if errmsg ~= "NOERROR" then return do_obj_logon_nok(errmsg)
    elseif fld39 ~= "00" then return do_obj_logon_nok(fld39)
    elseif tonumber(fld70) == 191 then
	  if #fld48 == 448 +16 then
        config.PKspMod = string.sub(fld48, 1,  224 )
        config.PKspExp = string.sub(fld48, 225,448 )
		config.randomnumber = string.sub(fld48, -16)
		terminal.SetJsonValue( "CONFIG","PKspMod", config.PKspMod) 
		terminal.SetJsonValue( "CONFIG","PKspExp", config.PKspExp)
		terminal.SetJsonValue( "CONFIG","RANDOMNUM", config.randomnumber)
		local key_PKsp = "5"
		local ok = terminal.RsaStore( "70".."70"..config.PKspMod..config.PKspExp , key_PKsp )
	  end
      config.logonstatus = "192"
	  terminal.SetJsonValue("CONFIG","LOGON_STATUS",config.logonstatus)
      return do_obj_logon_req()
    elseif tonumber(fld70) == 192 then
	  local ekca = string.sub(fld48,1,32)
	  local eppasn = string.sub(fld48,33,64)
	  local aiic_len = string.sub(fld48,65,66)
	  local aiic = string.sub(fld48,67,67 + tonumber(aiic_len)-1)
	  config.aiic = aiic

	  local ok = terminal.Derive3Des( ekca, "", config.key_kca,config.key_ki)
	  terminal.Derive3Des( eppasn, "", config.key_tmp,config.key_ki)
	  local stmp = string.format("%032s",aiic)
      ok = ok and terminal.Owf("",config.key_kia,config.key_kca,0,stmp)
      stmp = terminal.HexToString( config.tid ).. terminal.HexToString( config.tid )
      ok = ok and terminal.Owf("",config.key_kt,config.key_kia,0,stmp)

      config.logonstatus = "001"
	  terminal.SetJsonValue("CONFIG","LOGON_STATUS",config.logonstatus)
      return do_obj_logon_req()

    elseif tonumber(fld70) == 1  then
	  
	  local data_nomac = string.sub(rcvmsg,1,#rcvmsg-16)
	  local data_mac = string.sub(rcvmsg,-16)

	  local fld48_kvc,fld48_passcode,fld48_year, fld48_advertising,fld48_stan,fld48_time,fld48_date = 
	    string.sub(fld48,1,6),
	    string.sub(fld48,7,18),
	    string.sub(fld48,19,22),
	    string.sub(fld48,23,62),
	    string.sub(fld48,63,68),
	    string.sub(fld48,69,74),
	    string.sub(fld48,75,78)
		local ktkvc= terminal.Kvc("",config.key_kt)
	  config.stan = fld48_stan 
	terminal.SetJsonValue("CONFIG","STAN",config.stan)

      config.logok = true; return do_obj_logon_ok()
    elseif tonumber(fld70) == 194  then
		local ktkvc= terminal.Kvc("",config.key_kt)
		return do_obj_txn_finish()
    else
      if config.logonstatus ~= "191" then config.logonstatus = "192" end
      return do_obj_logon_req()
    end
  end
end

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

function do_obj_emv_error(emvstat)
  local scrlines,linestr="",""
  local gemv_techfallback = terminal.EmvGlobal("GET","TECHFALLBACK")
  local screvents = EVT.TIMEOUT
  local scrkeys = KEY.OK+KEY.CNCL

  if terminal.EmvIsCardPresent() then
	linestr = "WIDELBL,THIS,REMOVE CARD,4,C;"
	screvents = EVT.SCT_OUT 
	scrkeys = 0
  end
  if gemv_techfallback and not txn.emv_retry then txn.emv_retry = true
    linestr = "WIDELBL,THIS,PLEASE RETRY,4,C;"; txn.emv.fallback = false
  elseif gemv_techfallback then 
	  txn.emv.fallback = true;linestr = "WIDELBL,THIS,USE FALLBACK,4,C;" 
  end

  if emvstat == 157 then scrlines = "WIDELBL,THIS,NO ATR,2,C;" ..linestr
  elseif emvstat==101 then scrlines="WIDELBL,,277,2,C;"..linestr
  elseif emvstat==103 then scrlines="WIDELBL,,283,2,C;"..linestr
  elseif emvstat==106 then scrlines="WIDELBL,,282,2,C;"..linestr
  elseif emvstat==107 then scrlines="WIDELBL,,276,2,C;"..linestr
  elseif emvstat==108 then scrlines="WIDELBL,,281,2,C;"..linestr
  elseif emvstat==112 then scrlines="WIDELBL,,273,2,C;".."WIDELBL,,274,4,C;"..linestr
  elseif emvstat==113 then scrlines="WIDELBL,,276,2,C;".."WIDELBL,,274,4,C;"..linestr
  elseif emvstat==114 or emvstat==119 then scrlines="WIDELBL,,276,2,C;".."WIDELBL,,272,4,C;"..linestr
  elseif emvstat==116 then scrlines="WIDELBL,,120,2,C;"..linestr
  elseif emvstat==118 then scrlines="WIDELBL,,275,2,C;".."WIDELBL,,274,4,C;"..linestr
  elseif emvstat==125 then scrlines="WIDELBL,,285,2,C;"..linestr
  else scrlines="WIDELBL,,276,2,C;"..linestr
  end
  terminal.ErrorBeep()
  terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnErrTimeout)
  if gemv_techfallback then return do_obj_swipecard()
  else return do_obj_txn_finish() end 
end

function tcpconnect()
  local tcperrmsg = terminal.TcpConnect( "1",config.apn,"B1","0","",config.hip,config.port,"10","4096","10000")
  return(tcperrmsg)
end

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

function tcprecv()
  local rcvmsg,tcperrmsg ="",""
  local chartimeout,timeout = "2000",config.tcptimeout
  if config.tcptimeout == "" then timeout = 30 end
  local mac_ok = true
  tcperrmsg,rcvmsg = terminal.TcpRecv(chartimeout,timeout)
  
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

function mac_check(rcvmsg)
	local data_nomac = string.sub(rcvmsg,1,#rcvmsg-16)
	local data_mac = string.sub(rcvmsg,-16)
	debugPrint(data_nomac)
	debugPrint(data_mac)
	local macr_x = string.sub(config.mab_send,-16)
	local macr_y = string.sub(config.mab_recv,-16)
	local mti2,mti3 = string.sub(rcvmsg,1,2),string.sub(rcvmsg,1,3)

    local msg_t = { "GET,39"}
	local errmsg,fld39 = terminal.As2805Break( rcvmsg, msg_t )

	local ok = true
	local ap = ""
	if mti2 ~= "04" and mti3 ~="023" and txn.cv3 and txn.cv4 and txn.cv5 and ( fld39=="00" or fld39=="08") then
	  local cv3 = txn.cv3 or "0123456701234567"
	  local cv4 = txn.cv4 or "89ABCDEF89ABCDEF"
	  local cv5 = txn.cv5 or "0123456789ABCDEF"
	  ok = ok and terminal.DesStore(cv3..cv4, "16", config.key_tmp)
	  ok = ok and terminal.Owf("",config.key_card,config.key_tmp,0,cv4..cv3)
	  ok = ok and terminal.Owf("",config.key_dp,config.key_card,0,cv5..cv5)
	  local stan = string.format("%06d",tonumber(txn.stan)) .. string.rep("0",10)
	  local tid = terminal.HexToString(config.tid)
	  local amt = txn.totalamt and string.format("%016d",txn.totalamt) or "0000000000000000"
	  local dv7 = terminal.XorData(stan,tid,16)
	  dv7 = txn.totalamt and terminal.XorData(dv7,amt,16) or dv7
	  terminal.SetIvMode("0")
      local ap0 = terminal.Dec(dv7,"","16",config.key_dp)
	  ap = terminal.XorData(dv7,ap0,16)
	end
	
	local chkmac = terminal.Mac(macr_x..data_nomac..ap,"",config.key_kmacs)
	if data_mac ~= chkmac and ap~= "" then
		chkmac = terminal.Mac(macr_x..data_nomac,"",config.key_kmacs)
	end
	if data_mac == chkmac then
		terminal.Owf("",config.key_kt,config.key_kt,0,macr_x..macr_y)
	    terminal.Xor3Des( config.key_kt_x, config.key_kt, "","24C024C024C024C0")
	    terminal.DesStore("0123456789ABCDEF","8", config.key_tmp)
	    terminal.Owf(config.key_tmp,config.key_kmacs,config.key_kt_x,0)
		return true
	else
		--return false
		terminal.DebugDisp("boyang...mac error ["..data_mac.."] != "..chkmac)
		return true --workaround
	end
end

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

function cba_errorcode(errcode)
  local cbaerr_t = { 
		Q5="Settlement msg. already ack.",
		R1="Incorrect PIN block format",
		S1="Amt greater than SAF cr/db lim.",
		Z1="Offline Declined",
		Z3="Unable to go Online",
		Z4="Offine Decline",
		Z7="Transaction amount to large",
		Z8="Txn amt > than authorised amt",
		Z6="Card insertion only",
		H01="Refer to card issuer",
		H02="Rfr to crd issuer's spc. cond.",
		H03="Invalid merchant",
		H05="Do not honour",
		H06="Error",
		H09="Request in progress",
		H12="Invalid transaction",
		H13="Invalid amount",
		H14="Invalid card number ",
		H15="No such issuer",
		H17="Customer cancellation",
		H18="Customer dispute",
		H19="Re-enter transaction",
		H20="Invalid response",
		H21="No action taken",
		H22="Suspected malfunction",
		H23="Unacceptable transaction fee",
		H24="File update unsupported by rcvr",
		H25="Unable to locate record on file",
		H26="Dup. file update, old rec. replaced",
		H27="File update field edit error",
		H28="File update file locked out",
		H29="File update unsuccess,cont. acq",
		H30="Format error",
		H31="Bank not supported by switch",
		H32="Completed partially",
		H39="No credit account",
		H40="Request function not supported",
		H42="No universal account",
		H44="No investment account",
		H51="Not sufficient funds",
		H52="No cheque account",
		H53="No savings account",
		H54="Expired card",
		H55="Incorrect PIN",
		H56="No card record",
		H57="Txn not permitted to cardholder",
		H58="Txn not permitted to terminal",
		H59="Suspected fraud",
		H60="Card acceptor contact acquirer",
		H61="Exceeds withdrawal amount limit",
		H62="Restricted card",
		H63="Security violation",
		H64="Original amount incorrect",
		H65="Exceeds w/drawal freq. lim.",
		H66="Card acceptor call acquirer's security department",
		H67="Hard capture",
		H68="Response received too late",
		H75="PIN tries exceeded",
		H90="Cut off is in process",
		H91="Issuer or switch is inoperative",
		H92="Fin. insti. or intermed. n/w fac. cannot be found for routing",
		H93="Txn completed. Violation of law",
		H94="Duplicate transmission",
		H95="Reconcile error",
		H96="System malfunction",
		H97="Reconciliation totals reset",
		H98="MAC error",
		H99="Reserved for National Use"
  }
  local msg = cbaerr_t[errcode]
  return(msg)
end

function jsontable2string( jtable_t)
  local jsontag, jsonvalue, jtable_s = "","",""
  for jsontag,jsonvalue in pairs(jtable_t) do
    if jtable_s == "" then jtable_s = "{" .. jsontag .. ":" .. jsonvalue
    else jtable_s = jtable_s .. "," .. jsontag .. ":" .. jsonvalue end
  end
  if #jtable_s > 0 then jtable_s = jtable_s .."}" end
  return jtable_s
end

function do_obj_shft_reset()
  local scrlines = "WIDELBL,,37,4,C,;" .. "WIDELBL,,26,6,C,;"
  local screvent,scrinput = terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
  local doubleh=""
  local prtvalue=""
  if ecrd.HEADER then prtvalue = ecrd.HEADER else doubleh = "\\h" end
  local mytime2=terminal.Time("DD/MM/YY  hh:mm")
  local prchamt,cashamt,tipsamt,rfndamt,prchnum,cashnum,tipsnum,rfndnum= terminal.GetJsonValueInt("SHFT","PRCHAMT","CASHAMT","TIPSAMT","RFNDAMT","PRCHNUM","CASHNUM","TIPSNUM","RFNDNUM")
  prchamt=prchamt/100
  cashamt=cashamt/100
  tipsamt=tipsamt/100
  rfndamt=rfndamt/100
  local value="\\C\\f"..doubleh.."------------------------\\n\\C" ..config.servicename.."\\n"..
    "\\C" .. config.merch_loc0 .."\\n" ..
    "\\C" .. config.merch_loc1 .."\\n\\n" ..
    "MERCHANT ID:\\R"..string.sub(config.mid,-8).."\\n" ..
    "TERMINAL ID:\\R"..config.tid.."\\n\\n"..
	"DATE:\\R"..mytime2.."\\n\\n"..
    "SHIFT TOTALS\\R\\n"..
    "------------------------\\n"..
    "PURCHASE ".. string.format("%03s",prchnum) .."\\R".. string.format("$%.2f",prchamt).."\\n"..
    "------------------------\\n"
    ecrd.BODY = value
	prtvalue = prtvalue .. value ..(ecrd.TRAILER or "") .."\\n"
	terminal.Print(prtvalue,true);
	checkPrint(prtvalue)
    terminal.FileRemove("SHFT")
  return do_obj_txn_finish(true)
end

function do_obj_txn_finish(nosaf)
  terminal.FileRemove("TXN_REQ")
  terminal.FileRemove("REV_TODO")
  if txn.finishreturn then return txn.finishreturn
  else
    terminal.TcpDisconnect()
    terminal.EmvResetGlobal()
    if txn.chipcard and terminal.EmvIsCardPresent() and not (ecrd and ecrd.RETURN) then
      terminal.EmvPowerOff()
	  	terminal.ErrorBeep()
      local scrlines = "WIDELBL,,286,2,C;"
      terminal.DisplayObject(scrlines,0,EVT.SCT_OUT,ScrnTimeoutZO)
	end
	local nextstep = ( ecrd.RETURN or do_obj_idle )
	saf_rev_check()
	if nosaf or txn.rc == "Y3" then 
		return nextstep()
	elseif txn.rc == "Y1" then
		return do_obj_saf_rev_start(nextstep)
    elseif txn.rc=="00" or txn.rc == "08" or txn.rc =="Z4" then
		return do_obj_saf_rev_start(nextstep,"SAF")
	else 
		return nextstep()
	end
  end
end

function do_obj_reprint()
  local scrlines = "WIDELBL,,37,4,C;" .. "WIDELBL,,26,6,C;"
  local prt_keep = "**DUPLICATE**\\n\\n"..terminal.GetJsonValue("DUPLICATE","RECEIPT").."\\n"
  terminal.Print(prt_keep,true)
  checkPrint(prt_keep)
  return do_obj_txn_finish()
end

function get_emv_print_tags(debugprint)
	if txn.ctls then if not txn.chipcard then return "" end
	else
		if not ( txn.chipcard and terminal.EmvIsCardPresent()) then return "" end
	end
	local prttags = "\\n\\3"
	local tac_default,tac_denial,tac_online, iac_default,iac_denial,iac_online ="","","","","",""
	local f9f27,f9f10,f9f37,f9f02,f5f2a,f8200,f9f1a,f9f34,f9b00
	if txn.ctls and txn.chipcard then
			local f9f06 = get_value_from_tlvs("9F06")
			if f9f06 == "" then f9f06 = get_value_from_tlvs("8400") end
			f9f27 = get_value_from_tlvs("9F27")
			f9f10 = get_value_from_tlvs("9F10")
			f9f37 = get_value_from_tlvs("9F37")
			f9f02 = get_value_from_tlvs("9F02")
			f5f2a = get_value_from_tlvs("5F2A")
			f8200 = get_value_from_tlvs("8200")
			f9f1a = get_value_from_tlvs("9F1A")
			f9f34 = get_value_from_tlvs("9F34")
			f9b00 = get_value_from_tlvs("9B00")
			tac_default,tac_denial,tac_online= terminal.CTLSEmvGetTac(f9f06)
			iac_default = get_value_from_tlvs("9F0D")
			iac_denial = get_value_from_tlvs("9F0E")
			iac_online = get_value_from_tlvs("9F0F")
	else
		f9f27,f9f10,f9f37,f9f02,f5f2a,f8200,f9f1a,f9f34,f9b00 =
     	terminal.EmvGetTagData(0x9F27,0x9F10,0x9F37,0x9F02,0x5F2A,0x8200,0x9F1A,0x9F34,0x9B00) 
			
		tac_default,tac_denial,tac_online, iac_default,iac_denial,iac_online = terminal.EmvGetTacIac()
	end
	local i9f03 = 0
	prttags = prttags.."TAC Denial:\\R "..tac_denial.."\\n"
	prttags = prttags.."TAC Online:\\R "..tac_online.."\\n"
	prttags = prttags.."TAC Default:\\R"..tac_default.."\\n"
	prttags = prttags.."IAC Denial:\\R "..iac_denial.."\\n"
	prttags = prttags.."IAC Online:\\R "..iac_online.."\\n"
	prttags = prttags.."IAC Default:\\R"..iac_default.."\\n"
	prttags = prttags.."AIP:\\R".. f8200.."\\n"
	prttags = prttags.."CVM Result:\\R".. f9f34.."\\n"
	prttags = prttags.."UNPRED NO:\\R".. f9f37.."\\n"
	prttags = prttags.."TSI:\\R".. f9b00.."\\n"
	prttags = prttags.."IAD:\\R".. f9f10.."\\n"
	prttags = prttags.."CID:\\R".. f9f27.."\\n"
	prttags = prttags.."TRAN CURRENCY:\\R".. f5f2a.."\\n"
	prttags = prttags.."TERM COUNTRY:\\R".. f9f1a.."\\n"
	prttags = prttags.."AMOUNT OTHER:\\R".. string.format("$%.2f",i9f03/100).."\\n"

	return(prttags)
end

function get_ipay_print_nok(who,result_str)
  local cardinfo1,cardinfo2 = "",""
  local cname = nil
  local s_pan = ""
  local fullpan = txn.pan 
  if fullpan then
	s_pan = txn.fullpan or nil
  else
	s_pan = txn.fullpan and ( string.rep(".",10) .. string.sub(txn.fullpan,-4)) or nil
  end
  local cardentry = ""
  local AvlOfSpdAmt = ""
  if txn.ctls then cardentry = "(c)"
  elseif txn.pan then cardentry = "(m)"
  elseif txn.chipcard and txn.emv.fallback then cardentry = "(f)"
  elseif txn.chipcard then cardentry = "(i)"
  elseif txn.track2 then cardentry = "(s)"
  end
	local prttags = ""
	if txn.ctls then
		if txn.chipcard then
			local TxnTlvs = txn.TLVs
			local EMV9f26 = get_value_from_tlvs("9F26")
			local EMV9f5d = get_value_from_tlvs("9F5D")
			local EMV9f06 = get_value_from_tlvs("9F06")
			if EMV9f06 == "" then EMV9f06 = get_value_from_tlvs("8400") end
			local EMV9f36 = get_value_from_tlvs("9F36")
			local EMV9500 = get_value_from_tlvs("9500")
			local EMV5f34 = get_value_from_tlvs("5F34")
			local EMV9f5d = get_value_from_tlvs("9F5d")
			local pds50 = get_value_from_tlvs("5000")
			local pds9f12 = get_value_from_tlvs("9F12")
			cname = ( pds9f12 ~= "" ) and pds9f12 or pds50 
			cname = terminal.StringToHex(cname,#cname)
			cname = string.gsub( cname, "%s+$", "")
			prttags = "AID:\\R"..EMV9f06.."\\n".."ATC:" ..EMV9f36.."\\R TVR:"..EMV9500.."\n".."CSN:"..EMV5f34.."\\R AAC:" ..EMV9f26.."\\n"
		end
	elseif txn.chipcard and not txn.emv.fallback --[[and not txn.earlyemv]] then
		local pds4f,pds50,pds9f26,pds9f11,pds9f12,pds9f36,pds9500,pds5f34 = terminal.EmvGetTagData(0x4F00,0x5000,0x9F26,0x9f11,0x9f12,0x9f36,0x9500,0x5f34)
		local cname1 = (pds9f12~="" and tonumber("0x"..string.sub(pds9f12,1,2))) or ""
		cname =  (pds9f12 ~= "" and (cname1>= 48 and cname1<=57 or cname1>=65 and cname1<=90 or cname1>=97 and cname1<=122 ) and pds9f12) or pds50 
		cname = terminal.StringToHex(cname,#cname)
		cname = string.gsub( cname, "%s+$", "")
		if not txn.earlyemv then prttags = "AID:\\R"..pds4f.."\\n".."ATC:" ..pds9f36.."\\R TVR:"..pds9500.."\n".."CSN:"..pds5f34.."\\R AAC:" ..pds9f26.."\\n" end
	end
  cardinfo1 = s_pan and ("\\C"..( cname or txn.cardname or "") .. "\\n\\C" .. s_pan .. " " .. cardentry .."\\n" ) or ""
  cardinfo2 = prttags

  local func,s_amt = "",""
  local amt = txn.prchamt or 0
  if txn.func =="PRCH" then func =  "PURCHASE"
  else func = txn.func
  end

  local cashstr = ""
  local tipstr = ""
  if txn.prchamt and txn.prchamt>0 then
	s_amt = "AMOUNT\\R"..string.format("$%.2f",amt/100) .."\\n"
  end
  if txn.totalamt then
	s_amt = s_amt .. cashstr .. tipstr 
	s_amt = s_amt .. " \\R---------\\n".. "\\fTOTAL AUD \\R" .. string.format("$%.2f",txn.totalamt/100).. "\\n" 
  end

  local acc = txn.account and ( "ACCT TYPE:\\R" .. txn.account.. "\\n" ) or ""
  local stan = txn.tcpsent and ( "BANK REF:\\R"..string.format("%06d",txn.stan).."\\n") or ""
  local prtvalue = "\\4------------------------------------------\\n" ..
    "\\C\\F" ..( ecrd.HEADER and "" or "\\H") .. who ..
    "\\C\\f" ..( ecrd.HEADER and "" or "\\H") .. config.servicename .."\\n" ..
    "\\C" .. config.merch_loc0 .."\\n" ..
    "\\C" .. config.merch_loc1 .."\\n" ..
    cardinfo1 ..
	"\\3" ..acc..
	"TRANS TYPE:\\R" .. func.. "\\n"..
	"MERCHANT ID:\\R" .. string.sub(config.mid,-8) .. "\\n" ..
    "TERMINAL ID:\\R" .. config.tid .. "\\n" ..
	(txn.totalamt and ("INV/ROC NO:\\R"..config.roc .."\\n") or "" )..
	stan..
	"DATE/TIME:\\R".. terminal.Time( "DD/MM/YY hh:mm" ) .."\\n"..
	cardinfo2 .. 
	s_amt ..
	AvlOfSpdAmt..
    "\\H".. result_str ..
    "\\4------------------------------------------\\n"  
  return prtvalue
end

function get_ipay_print(who,result_ok,result_str)
  local is_merch = ( #who > 8 and (string.sub( who,1,8) == "MERCHANT"))
  local card_exp = ""
  local AvlOfSpdAmt = ""
  local cardinfo1,cardinfo2 = "",""
  local cname = nil

  if true then
	local fullpan =  txn.pan
	local s_pan = txn.fullpan and ( fullpan and txn.fullpan or string.rep(".",10) .. string.sub(txn.fullpan,-4)) or ""
	local cardentry = ""
	if txn.ctls then cardentry = "(c)"
	elseif txn.pan then cardentry = "(m)"
	elseif txn.chipcard and txn.emv.fallback then cardentry = "(f)"
	elseif txn.chipcard then cardentry = "(i)"
	elseif txn.track2 then cardentry = "(s)"
	end

	if fullpan then
		local expirydate = ""
		if txn.expiry then expirydate = string.sub(txn.expiry,1,2) .."/" .. string.sub(txn.expiry,3,4) end
		card_exp = ( #expirydate >=4 and "EXPIRY DATE(MM/YY):\\R"..expirydate .."\\n" or "")
	end
	local prt_emv = ""
	if txn.ctls then
		if txn.chipcard then
			local TxnTlvs = txn.TLVs
			local EMV9f26 = get_value_from_tlvs("9F26")
			local EMV9f5d = get_value_from_tlvs("9F5D")
			local EMV9f06 = get_value_from_tlvs("9F06")
			if EMV9f06 == "" then EMV9f06 = get_value_from_tlvs("8400") end
			local EMV9f36 = get_value_from_tlvs("9F36")
			local EMV9500 = get_value_from_tlvs("9500")
			local EMV5f34 = get_value_from_tlvs("5F34")
			local pds50 = get_value_from_tlvs("5000")
			local pds9f12 = get_value_from_tlvs("9F12")
			cname = ( pds9f12 ~= "" ) and pds9f12 or pds50 
			cname = terminal.StringToHex(cname,#cname)
			cname = string.gsub( cname, "%s+$", "")
			prt_emv = "AID:\\R"..EMV9f06.."\\n".."ATC:" ..EMV9f36.."\\R TVR:"..EMV9500.."\n".."CSN:"..EMV5f34.."\\R AAC:" ..EMV9f26.."\\n"
		else
			local EMV5000 = get_value_from_tlvs("5000")
			if EMV5000~="" then cname = terminal.StringToHex(EMV5000,#EMV5000) end
		end
	else
		if txn.chipcard and not txn.emv.fallback --[[and not txn.earlyemv]] then
			local pds4f,pds50,pds9f26,pds9f11,pds9f12,pds9f36,pds9500,pds9f26,pds5f34 = terminal.EmvGetTagData(0x4F00,0x5000,0x9F26,0x9f11,0x9f12,0x9f36,0x9500,0x9f26,0x5f34)
		local cname1 = (pds9f12~="" and tonumber("0x"..string.sub(pds9f12,1,2))) or ""
		cname =  (pds9f12 ~= "" and (cname1>= 48 and cname1<=57 or cname1>=65 and cname1<=90 or cname1>=97 and cname1<=122 ) and pds9f12) or pds50 
		cname = terminal.StringToHex(cname,#cname)
		cname = string.gsub( cname, "%s+$", "")
		if not txn.earlyemv then prt_emv = "AID:\\R"..pds4f.."\\n".."ATC:" ..pds9f36.."\\R TVR:"..pds9500.."\n".."CSN:"..pds5f34.."\\R AAC:" ..pds9f26.."\\n" end
		end
	end
	
	cardinfo1 = "\\C"..(cname or txn.cardname) .. "\\n\\C" .. s_pan .. " " .. cardentry .."\\n" 
	local keep_cardinfo1 = "\\C"..txn.cardname .. "\\n\\C" .. string.rep(".",10) .. string.sub(s_pan,-4) .. " " .. cardentry .."\\n\\n" 
	terminal.SetJsonValue("TXN_REQ","CARDINFO1",keep_cardinfo1)
	terminal.SetJsonValue("TXN_REQ","CARDNAME",txn.cardname)
	cardinfo2 = prt_emv
	terminal.SetJsonValue("TXN_REQ","CARDINFO2",cardinfo2)
  end

  local func,s_amt,amt = "","",txn.prchamt
  if txn.func =="PRCH" then func = (txn.cashamt and txn.cashamt>0 and "PUR/CASH" or "PURCHASE")
  else func = txn.func
  end
  local authstr = (true or txn.rc == "Y1" or txn.rc == "Y3" ) and "" or ("\\fAUTH NO:\\R"..(txn.authid or "").."\\n" ) --TESTING
  local cashstr = ""

  local tipstr = ""; local totalstr = false
  if txn.prchamt and txn.prchamt>0 then
	if txn.cashamt and txn.cashamt>0 then s_amt = "PURCHASE\\R"..string.format("$%.2f",amt/100) .."\\n"
	else s_amt = "AMOUNT\\R"..string.format("$%.2f",amt/100) .."\\n" end
  end
  s_amt = s_amt .. cashstr .. tipstr 
  s_amt = s_amt .. " \\R---------\\n".. ( totalstr or ("\\fTOTAL AUD \\R" .. string.format("$%.2f",txn.totalamt/100))).. "\\n" 
  local stan = txn.tcpsent and ( "BANK REF:\\R"..string.format("%06d",txn.stan).."\\n") or ""
  
  local banktime = txn.time and string.len(txn.time)==14 and ( "\\3BANK TIME:\\R"..string.sub(txn.time,7,8).."/"..string.sub(txn.time,5,6).."/"..string.sub(txn.time,3,4).." "..string.sub(txn.time,9,10)..":"..string.sub(txn.time,11,12).."\\n") or "\\n"
  local prtvalue = "\\4------------------------------------------\\n" ..
    "\\C\\F" ..( ecrd.HEADER and "" or "\\H") .. who ..
    "\\C\\f" ..( ecrd.HEADER and "" or "\\H") .. config.servicename .."\\n" ..
    "\\C" .. config.merch_loc0 .."\\n" ..
    "\\C" .. config.merch_loc1 .."\\n" ..
    cardinfo1 ..
	"\\3ACCT TYPE:\\R" .. txn.account.. "\\n"..
	"TRANS TYPE:\\R" .. func.. "\\n"..
	"MERCHANT ID:\\R" .. string.sub(config.mid,-8) .. "\\n" ..
    "TERMINAL ID:\\R" .. config.tid .. "\\n" ..
	"INV/ROC NO:\\R"..config.roc.."\\n"..
	stan ..
	"DATE/TIME:\\R".. terminal.Time( "DD/MM/YY hh:mm" ) .."\\n"..
    card_exp .. 
	cardinfo2 .. 
	s_amt ..
    authstr..
	AvlOfSpdAmt..
    "\\H".. result_str .. 
	banktime..
    "\\4------------------------------------------\\n" 

  return prtvalue
end

function get_value_from_tlvs(tag,tlvs_s)
	local value = ""
	if not txn.TLVs and not tlvs_s then return "" end
	local tlvs = tlvs_s or txn.TLVs
	if not txn.TLVs_table then
		txn.TLVs_table = {}
		local idx = 1
		local tlen = 0
		while idx < #tlvs do
			local chktag = string.sub(tlvs,idx,idx+3)
			idx = idx + 4
			if chktag == "LEN6" then
				chktag = string.sub(tlvs,idx,idx+5)
				idx = idx + 6
			end
			tlen = tonumber( "0x"..( string.sub(tlvs,idx,idx+1) or "00"))
			idx = idx + 2
			value = string.sub(tlvs,idx,idx+tlen*2-1)
			idx = idx + tlen*2
			txn.TLVs_table[ chktag ] = value
		end
	end
	
	value = txn.TLVs_table [ tag ]
	if not value then value = "" end
	return value
end

function prep_txnroc()
  if config.roc == nil or config.roc == "" or tonumber(config.roc) >= 999999 then config.roc = "000001"
  else config.roc = string.format("%06d",tonumber(config.roc) + 1) end
  terminal.SetJsonValue("CONFIG","ROC",config.roc)
  return 0
end

function funckeymenu()
  require ("CBACONFIG")
  local scrlines = ",,40,2,C;" .. "LHIDDEN,,0,5,17,8;"					   
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,ScrnTimeout)

  if screvent == "KEY_CLR" or screvent == "CANCEL" or screvent=="TIME" then
    return do_obj_txn_finish()
  elseif screvent == "KEY_OK" then
    if scrinput == "7410" then
      return do_obj_termconfig()
    elseif scrinput == "3824" then
      return do_obj_termconfig_maintain()
    elseif scrinput == "5295" then
	  if config.tid == "" or config.mid == "" then
			local scrlines = "WIDELBL,,51,2,C;" .. "WIDELBL,,53,4,C;"
			terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
			return do_obj_txn_finish()
      else 
		return do_obj_logon_init() 
	  end
    elseif scrinput == "5296" then
	  config.logonstatus = "191"
      return do_obj_logon_init()
    elseif scrinput == "00100100" then
       return do_obj_swdownload()
	elseif scrinput == "5620" then
	  return do_obj_clear_saf()
	elseif scrinput == "5628" then
	  return do_obj_upload_saf()
    elseif scrinput == "5629" then
	  return do_obj_print_saf()
    elseif scrinput == "00200200" then
	  return do_obj_txn_reset_memory()
	elseif scrinput == "3701" then
	  terminal.CTLSEmvGetCfg()
	  return do_obj_txn_finish()
    else return do_obj_txn_finish()
    end
  end
end

function do_obj_swdownload()
  local scrlines = "WIDELBL,,84,2,C;" .. "WIDELBL,,26,3,C;"
  terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
  terminal.UploadObj("iPAY_CFG")
  local ok = terminal.Remote()
  if not ok then terminal.ErrorBeep() end 
  scrlines = "WIDELBL,,84,2,C;" .. "WIDELBL,THIS,"..(ok and "SUCCESS" or "FAILED!")..",3,C;"
  terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,ScrnTimeoutTHR)
  return do_obj_gprs_register(do_obj_txn_finish)
end

function do_obj_clear_saf()
	local screvent=""
	local revmin,revmax= terminal.GetArrayRange("REVERSAL")
	local safmin,safmax= terminal.GetArrayRange("SAF")
	if revmax == revmin and safmax == safmin then 
		local scrlines = "WIDELBL,THIS,REVERSAL/SAF,2,C;" .. "WIDELBL,THIS,EMPTY,3,C;"
		screvent,_ = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,30000)
		return do_obj_txn_finish(true)
	else
		local fname = "REVERSAL"
		for i=revmin,revmax-1 do
		  if terminal.FileExist(fname..i) then
			local roc = terminal.GetJsonValue(fname..i,"62")
			roc = terminal.StringToHex(roc,#roc)
			local scrlines = "WIDELBL,THIS,DELETE REVERSAL?,2,C;" .. "WIDELBL,THIS,ROC/INV:"..roc..",3,C;".."BUTTONS_YES,THIS,YES,B,10;" .."BUTTONS_NO,THIS,NO,B,33;" 
			screvent,_ = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,30000)
			if screvent == "BUTTONS_YES" or screvent == "KEY_OK" then terminal.FileRemove(fname .. i); terminal.SetArrayRange(fname, i+1, "") end 
			break
		  end
		end

		if screvent == "" then
		  local fname = "SAF"
		  for i=safmin,safmax-1 do
			if terminal.FileExist(fname..i) then
				local roc = terminal.GetJsonValue(fname..i,"62")
				roc = terminal.StringToHex(roc,#roc)
				local scrlines = "WIDELBL,THIS,DELETE SAF?,2,C;" .. "WIDELBL,THIS,ROC/INV:"..roc..",3,C;".."BUTTONS_YES,THIS,YES,B,10;" .."BUTTONS_NO,THIS,NO,B,33;"
				screvent,_ = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,30000)
				if screvent == "BUTTONS_YES" or screvent == "KEY_OK" then terminal.FileRemove(fname .. i); terminal.SetArrayRange(fname, i+1, "") end 
				break
			end
		  end
		end
		saf_rev_check()
		return do_obj_txn_finish(true)
	end
end

function do_obj_upload_saf()
  local scrlines = "WIDELBL,THIS,UPLOAD ,2,C;" .. "WIDELBL,THIS,REVERSAL/SAF,3,C;".."BUTTONS_YES,THIS,YES,B,10;"  .."BUTTONS_NO,THIS,NO,B,33;" 
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "BUTTONS_YES" or screvent == "KEY_OK" then check_logon_ok()
		  return do_obj_txn_finish()
  else return do_obj_txn_finish(true) end
end

function do_obj_print_saf()
  local scrlines = "WIDELBL,THIS,PRINT ,2,C;" .. "WIDELBL,THIS,REVERSAL/SAF,3,C;".."BUTTONS_YES,THIS,YES,B,10;"  .."BUTTONS_NO,THIS,NO,B,33;" 
  local screvent = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "BUTTONS_YES" or screvent == "KEY_OK" then
	local screvent=""
	local revmin,revmax= terminal.GetArrayRange("REVERSAL")
	local safmin,safmax= terminal.GetArrayRange("SAF")
	if revmax == revmin and safmax == safmin then 
		local scrlines = "WIDELBL,THIS,REVERSAL/SAF,5,C;" .. "WIDELBL,THIS,EMPTY,7,C;"
		terminal.DisplayObject(scrlines,KEY.CNCL,EVT.TIMEOUT,ScrnTimeout)
	else
		local prtvalue= "\\C\\HSAF/REVERSAL LIST\\n" ..
			"\\4\\w------------------------------------------\\n" ..
			"\\fMERCHANT ID:\\R" .. string.sub(config.mid,-8) .. "\\n" ..
			"\\fTERMINAL ID:\\R" .. config.tid .. "\\n\\n" ..
			"\\fTYPE\\RROC/INV\\n"

		local fname = "REVERSAL"
		if terminal.FileExist(fname..revmin) then
			local roc = terminal.GetJsonValue(fname..revmin,"ROC")
			prtvalue = prtvalue .."\\3REVERSAL".."\\R"..roc.."\\n"
		end

		fname = "SAF"
		for i=safmin,safmax-1 do
			if terminal.FileExist(fname..i) then
				local roc = terminal.GetJsonValue(fname..i,"ROC")
				prtvalue = prtvalue .."\\fSAF".."\\R"..roc.."\\n"
			end
		end
		terminal.Print(prtvalue,true)
	end
  end
  return do_obj_txn_finish(true)
end

function do_obj_txn_reset_memory()
  local scrlines = "WIDELBL,THIS,RESET MEMORY?,2,C;".."WIDELBL,,73,3,C;"
  local screvent,_=terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" then 
	local fmax,fmin = 0,0
	local scrlines = "WIDELBL,,27,2,C;" .."WIDELBL,,26,4,C;"
	terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
	terminal.SetJsonValue("CONFIG","BATCHNO", "000000")
	config.logonstatus = "191"
	terminal.SetJsonValue("CONFIG","LOGON_STATUS",config.logonstatus)
	config.stan = "000001"
	terminal.SetJsonValue("CONFIG","STAN",config.stan)
	config.roc = "000000"
	terminal.SetJsonValue("CONFIG","ROC",config.roc)
	config.tid = ""
	terminal.SetJsonValue("CONFIG","TID","")
	config.mid = ""
	terminal.SetJsonValue("CONFIG","MID","")
	terminal.SetJsonValue("iPAY_CFG","TID","")
	terminal.SetJsonValue("iPAY_CFG","MID","")
	terminal.SetJsonValue("DUPLICATE","RECEIPT","")
	fmin,fmax = terminal.GetArrayRange("TAXI")
	for i=fmin,fmax-1 do terminal.FileRemove("TAXI"..i) end
	terminal.SetArrayRange("TAXI","0","0")
	fmin,fmax = terminal.GetArrayRange("SAF")
	for i=fmin,fmax-1 do terminal.FileRemove("SAF"..i) end
	terminal.SetArrayRange("SAF","0","0")
	fmin,fmax = terminal.GetArrayRange("REVERSAL")
	for i=fmin,fmax-1 do terminal.FileRemove("REVERSAL"..i) end
	terminal.SetArrayRange("REVERSAL","0","0")
	terminal.FileRemove("SHFTSTTL")
	scrlines = "LARGE,THIS,RESET MEMORY,2,C,;".."LARGE,THIS,SUCCESS,3,C,;"
	terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,ScrnErrTimeout)--AR Timeout
	config.logok = false
  end
  return do_obj_txn_finish()
end

function checkPrint(prtvalue)
  while true do
	local prtok = terminal.PrinterStatus()
	if prtok == "OK" then return 
	else
		local scrlines = "WIDELBL,THIS,PRINTER ERROR,2,C;" .. "WIDELBL,THIS,"..prtok..",3,C;" .."BUTTONS_Y,THIS,RETRY ,B,4;".."BUTTONS_N,THIS,CANCEL,B,33;"
		local screvent,_ = terminal.DisplayObject(scrlines,KEY.FUNC,0,0)
		if screvent == "BUTTONS_Y" then terminal.Print(prtvalue,true)
		elseif screvent == "KEY_FUNC" then
			local slen = 1
			prtvalue = string.gsub(prtvalue,"\\n","\n")
			prtvalue = string.gsub(prtvalue,"\n+","\n")
			prtvalue = string.gsub(prtvalue,"\\.","")
			prtvalue = string.gsub(prtvalue,"-----------","")
			while slen <=#prtvalue do terminal.DebugDisp(string.sub(prtvalue,slen,slen+240)); slen=slen+241 end
			return
		else return end
	end
  end
end

function bit(p)
  return 2 ^ (p - 1)
end
function hasbit(x, p)
  return x % (p + p) >= p       
end

function do_obj_gprs_register(nextfunc)
  local scrlines = "WIDELBL,,228,4,C;" .. "WIDELBL,THIS,"..config.apn..",6,C;"
  local screvent,scrinput = terminal.DisplayObject(scrlines,0,0,0)
  local retmsg = tcpconnect()
  scrlines = "WIDELBL,,228,3,C;" .. "WIDELBL,THIS,"..config.apn..",4,C;"
  if retmsg == "NOERROR" then
    scrlines = scrlines .. "WIDELBL,THIS,SUCCESS!!,6,C;"
  else
    terminal.ErrorBeep()
    scrlines = scrlines .. "WIDELBL,THIS,FAILED!!,6,C;"
	scrlines = scrlines .. "WIDELBL,THIS,"..retmsg..",8,C;"
  end
  terminal.DisplayObject(scrlines,0,EVT.TIMEOUT,ScrnTimeoutHF)
  if nextfunc then return nextfunc() else return 0 end
end

function swipecheck(track2)
  if track2 == nil or #track2 < 11 or callback.mcr_func == nil then terminal.ErrorBeep(); return -1 end

  local _,_,pan,panetc = string.find(track2, "(%d*)=(%d*)")
  if not (pan and #pan > 11) then 
		terminal.ErrorBeep()
  		local scrlines1 = "WIDELBL,THIS,TRAN CANCELLED,2,C;" .. "WIDELBL,THIS,CARD NOT SUPPORTED,4,C;"
		terminal.DisplayObject(scrlines1,KEY.CNCL,EVT.TIMEOUT,ScrnErrTimeout)
		return -1
  end

  local expirydate = (panetc and string.sub(panetc,1,4) or "")
  local currmonth = terminal.Time( "YYMM") 
  if expirydate ~= "" and tonumber(currmonth) > tonumber(expirydate) then
		terminal.ErrorBeep()
		local scrlines1 = "WIDELBL,THIS,TRAN CANCELLED,2,C;" .. "WIDELBL,THIS,CARD EXPIRED,4,C;"
		terminal.DisplayObject(scrlines1,KEY.CNCL,EVT.TIMEOUT,ScrnErrTimeout)
		return -1
  end

  local cardname_prefix,_,_ = terminal.LocateCpat("CPAT_ALL",string.sub(pan,1,6))
  if #cardname_prefix < 2 then 
		terminal.ErrorBeep()
  		local scrlines1 = "WIDELBL,THIS,TRAN CANCELLED,2,C;" .. "WIDELBL,THIS,CARD NOT SUPPORTED,4,C;"
		terminal.DisplayObject(scrlines1,KEY.CNCL,EVT.TIMEOUT,ScrnErrTimeout)
		return -1
  end

  if #cardname_prefix > 2 then cardname_prefix = string.sub(cardname_prefix,-2) end
  local cardname = terminal.TextTable("CARD_NAME",cardname_prefix)

  local chipflag = (panetc and string.sub(panetc,5,5) or "")
  if chipflag == "2" or chipflag == "6" then
    terminal.ErrorBeep(); return 0
  end

  return 1,cardname
end


function debugPrint(msg)
	local maxlen = #msg
	local idx = 0
	while true do
		terminal.Print("\\4"..string.sub(msg, idx, idx+199).."\\n", false)
		idx = idx + 200
		if idx > maxlen then break end
	end
	terminal.Print("\\n", true)
end

terminal.As2805SetBcdLength("0")
callback.func_func = funckeymenu
if not callback.chip_func then callback.chip_func = do_obj_cba_mcr_chip end
if not callback.mcr_func then callback.mcr_func = do_obj_cba_mcr_chip end
if terminal.FileExist("REV_TODO") then
  local safmin,safnext = terminal.GetArrayRange("REVERSAL")
  local saffile = "REVERSAL"..safnext
  terminal.FileCopy( "REV_TODO", saffile)
  terminal.SetArrayRange("REVERSAL","",safnext+1)
  terminal.FileRemove("REV_TODO")
end
saf_rev_check()
