function update_total()
	local cardname = txn.cardname
	if txn.account ~= "CREDIT" then cardname = "DEBIT" end
    local prchnum,prchamt=terminal.GetJsonValueInt("SHFT","PRCHNUM","PRCHAMT")
    local cr_s_num,cr_s_amt,dr_s_num,dr_s_amt,card_prch_num,card_prch_amt=
	terminal.GetJsonValueInt("SHFTSTTL","CR_PRCHNUM","CR_PRCHAMT","DR_PRCHNUM","DR_PRCHAMT",cardname.."_PRCHNUM",cardname.."_PRCHAMT")
    if txn.prchamt>0 and txn.func == "PRCH" then
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
