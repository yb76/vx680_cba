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
