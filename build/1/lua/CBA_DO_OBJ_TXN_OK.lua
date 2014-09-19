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
