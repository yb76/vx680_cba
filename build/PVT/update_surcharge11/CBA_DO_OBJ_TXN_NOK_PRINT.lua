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
