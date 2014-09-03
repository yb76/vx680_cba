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
  if txn.moto and txn.poscc == "08" then func = "MAIL/PHONE"
  elseif txn.moto and txn.poscc == "59" then func = "E-COMMERCE"
  elseif txn.func =="PRCH" then func = (txn.cashamt and txn.cashamt>0 and "PUR/CASH" or "PURCHASE")
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
