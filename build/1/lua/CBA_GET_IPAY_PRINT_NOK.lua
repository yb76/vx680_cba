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
  if txn.efb then cardentry = "(efb)"
  elseif txn.ctls then cardentry = "(c)"
  elseif txn.pan then cardentry = "(m)"
  elseif txn.chipcard and txn.emv.fallback then cardentry = "(f)"
  elseif txn.chipcard then cardentry = "(i)"
  elseif txn.track2 then cardentry = "(s)"
  end
	local prttags = ""
	if txn.ctls then
		if txn.chipcard then
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
