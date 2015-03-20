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
require("CBA_DO_OBJ_CBA_MCR_CHIP")
require("CBA_DO_OBJ_CBA_SWIPE_INSERT")
require("CBA_EMV_INIT")
require("CBA_CHECK_LOGON_OK")
require("CBA_CHECK_REV_OK")
require("CBA_TXN_ALLOWED")
require("CBA_DO_OBJ_ADVICE_START")
require("CBA_DO_OBJ_ADVICE_REQ")
require("CBA_DO_OBJ_PRCHAMOUNT")
require("CBA_DO_OBJ_SWIPECARD")
require("CBA_GET_CARDINFO")
require("CBA_GET_TRANS_CV")
require("CBA_GET_TRANS_CV2")
require("CBA_DO_OBJ_ACCOUNT")
require("CBA_DO_OBJ_PIN")
require("CBA_DO_OBJ_TRANTIMEOUT")
require("CBA_GENERATE_SAF")
require("CBA_DO_OBJ_OFFLINE_CHECK")
require("CBA_DO_OBJ_TRANSDIAL")
require("CBA_TOOMANY_SAF")
require("CBA_TRANS_KEYS")
require("CBA_DO_OBJ_TRANSSTART")
require("CBA_DO_OBJ_SAF_REV_START")
require("CBA_SAF_REV_CHECK")
require("CBA_DO_OBJ_SAF_REV_SEND")
require("CBA_PREPARE_TXN_REQ")
require("CBA_DO_OBJ_TXN_REQ")
require("CBA_DO_OBJ_TXN_RESP")
require("CBA_DO_OBJ_TXN_OK")
require("CBA_UPDATE_TOTAL")
require("CBA_DO_OBJ_TXN_SIG")
require("CBA_DO_OBJ_TXN_SECOND_COPY")
require("CBA_COPY_TXN_TO_SAF")
require("CBA_CHECK_EFB")
require("CBA_DO_OBJ_TXN_NOK")
require("CBA_DO_OBJ_TXN_NOK_PRINT")
require("CBA_DO_OBJ_LOGON_INIT")
require("CBA_DO_OBJ_LOGON_START")
require("CBA_DO_OBJ_LOGON_REQ")
require("CBA_DO_OBJ_LOGON_RESP")
require("CBA_DO_OBJ_LOGON_OK")
require("CBA_DO_OBJ_LOGON_NOK")
require("CBA_DO_OBJ_EMV_ERROR")
require("CBA_TCPCONNECT")
require("CBA_TCPSEND")
require("CBA_TCPRECV")
require("CBA_MAC_CHECK")
require("CBA_TCPERRORCODE")
require("CBA_CBA_ERRORCODE")
require("CBA_JSONTABLE2STRING")
require("CBA_DO_OBJ_SHFT_RESET")
require("CBA_DO_OBJ_TXN_FINISH")
require("CBA_DO_OBJ_REPRINT")
require("CBA_GET_EMV_PRINT_TAGS")
require("CBA_GET_IPAY_PRINT_NOK")
require("CBA_GET_IPAY_PRINT")
require("CBA_GET_VALUE_FROM_TLVS")
require("CBA_PREP_TXNROC")
require("CBA_FUNCKEYMENU")
require("CBA_DO_OBJ_SWDOWNLOAD")
require("CBA_DO_OBJ_CLEAR_SAF")
require("CBA_DO_OBJ_UPLOAD_SAF")
require("CBA_DO_OBJ_PRINT_SAF")
require("CBA_DO_OBJ_TXN_RESET_MEMORY")
require("CBA_CHECKPRINT")
require("CBA_BIT")
require("CBA_HASBIT")
require("CBA_DO_OBJ_GPRS_REGISTER")
require("CBA_SWIPECHECK")
require("CBA_DEBUGPRINT")
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
