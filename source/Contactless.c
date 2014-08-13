/*
**-----------------------------------------------------------------------------
** PROJECT:         AURIS
**
** FILE NAME:       Contactless.c
**
** DATE CREATED:    08 Oct 2012
**
** AUTHOR:          Dwarika Pandey
**
** DESCRIPTION:     This module contains the ctls EMV functions
**-----------------------------------------------------------------------------
*/

#pragma region includes

#include <ctype.h>
#include <string.h>
#include <svc.h>
#include <svc_sec.h>
#include <math.h>
#include <stdlib.h>
#include "Contactless.h"
//#include "Trans.h"
#include "global.h"
#include "system.h"
#include "date.h"
#include "emvtags.hpp"
#include "emvcwrappers.h"

// for EOS log
#include <eoslog.h>

#include <ctlsinterface.h>
#include "ctlsmod.h"
#include "inputmacro.h"

#pragma endregion

#pragma region Defines

#pragma region Defines_Consts

#define VIVO_HDR_STR "ViVOtech"
#define VIVO2_HDR_STR "ViVOtech2"
#define CTLS_BUFF_SZ 5000
#define ARQC "80"
#define TC "40"
#define AAC "00"

#define CTLSDEBUG 0
#pragma endregion

#pragma region Defines_PktFldOfs

//packet field offsets
#define V2_STATUS_OFS 11
#define V2_DAT_LEN_MSB_OFS 12
#define V2_DAT_LEN_LSB_OFS 13
#define V2_DATA_OFS 14
#define V2_CRC_MSB_OFS 14
#define V2_CRC_LSB_OFS 15
#define V2_FXD_BYTES 16
#define V2_ERR_T2_OFS 4
#define V2_T2EQD_SZ 21

#pragma endregion

#pragma region Defines_Vivo2StatCds

//vivo status codes
#define V2_OK 0
#define V2_INCORRECT_TAG_HDR 0x01
#define V2_UNK_CMD 0x02
#define V2_UNK_SUB_CMD 0x03
#define V2_CRC_ERR 0x04
#define V2_INCORRECT_PARAM 0x05
#define V2_PARAM_NOT_SUPPORTED 0x06
#define V2_MAL_FORMATTED_DATA 0x07
#define V2_TXN_TIMED_OUT 0x08
#define V2_FAILED_NAK 0x0A
#define V2_CMD_NOT_ALLOWED 0x0B
#define V2_SUB_CMD_NOT_ALLOWED 0x0C
#define V2_BUFF_OVERFLOW 0x0D
#define V2_USER_IF_EVT 0x0E
#define V2_REQ_OL_AUTH 0x23

#pragma endregion

#pragma region Defines_Vivo1StatCds

//vivo status codes
#define V1_OK 0
#define V1_INC_FRAME_Tag 0x01
#define V1_INC_FRAME_TYP 0x02
#define V1_UNK_FRAME_TYP 0x03
#define V1_UNK_CMD 0x04
#define V1_UNK_SUB_CMD 0x05
#define V1_CRC_ERROR 0x06
#define V1_FAIL 0x07
#define V1_TIMEOUT 0x08
#define V1_INC_PARAM 0x09
#define V1_CMD_NOT_SUPP 0x0A
#define V1_SUB_CMD_NOT_SUPP 0x0B
#define V1_PARAM_NOT_SUPP 0x0C
#define V1_CMD_ABORT 0x0D
#define V1_CMD_NOT_ALW 0x0E
#define V1_SUB_CMD_NOT_ALW 0x0F

#define V1_ACK_FRAME 'A'
#define V1_NACK_FRAME 'N'

#define V1_RTC_NO_ERR 0x00
#define V1_RTC_ERR_UNK 0x01
#define V1_RTC_INV_DATA 0x02
#define V1_RTC_ERR_NO_RTC_RSP 0x03

#define V1_KEYMGT_NO_ERR 0x00
#define V1_KEYMGT_UNK_ERR 0x01
#define V1_KEYMGT_INV_DATA 0x02
#define V1_KEYMGT_DATA_NOT_CMP 0x03
#define V1_KEYMGT_INV_KEY_NDX 0x04
#define V1_KEYMGT_INV_HSH_ALG_IND 0x05
#define V1_KEYMGT_INV_KEY_ALG_IND 0x06
#define V1_KEYMGT_INV_KEY_MOD_Len 0x07
#define V1_KEYMGT_INV_KEY_EXP 0x08
#define V1_KEYMGT_KEY_EXISTS 0x09
#define V1_KEYMGT_NO_SPACE 0x0A
#define V1_KEYMGT_KEY_NOT_FOUND 0x0B
#define V1_KEYMGT_CRYP_CHP_NO_RSP 0x0C
#define V1_KEYMGT_CRYP_CHP_COM_ERR 0x0D
#define V1_KEYMGT_RID_SLT_FULL 0x0E
#define V1_KEYMGT_NO_FREE_SLOTS 0x0F

#pragma endregion

#pragma region Defines_Vivo2ErrCds
//vivio error codes

#define V2_NO_ERR 0x00
#define V2_OUT_SEQ_CMD 0x01
#define V2_GOTO_CNT 0x02
#define V2_AMT_ZERO 0x03
#define V2_CRD_ERR_STAT 0x20
#define V2_COLLISION 0x21
#define V2_AMT_OVR_MAX 0x22
#define V2_REQ_OL_AUTH 0x23
#define V2_CRD_BLKD 0x25
#define V2_CRD_EXPD 0x26
#define V2_CRD_NOT_SUPP 0x27
#define V2_CRD_NOT_RSP 0x30
#define V2_UNK_DAT_ELMT 0x40
#define V2_DAT_ELMT_MISS 0x41
#define V2_CRD_GEN_AAC 0x42
#define V2_CRD_GEN_ARQC 0x43
#define V2_CA_PUB_KEY_FAIL 0x50
#define V2_ISS_PUB_KEY_FAIL 0x51
#define V2_SDA_FAIL 0x52
#define V2_ICC_PUB_KEY_FAIL 0x53
#define V2_DYN_SIG_VER_FAIL 0x54
#define V2_PRCS_RST_FAIL 0x55
#define V2_TRM_FAIL 0x56
#define V2_CVM_FAIL 0x57
#define V2_TAA_FAIL 0x58
#define V2_SD_MEM_ERR 0x61

#pragma endregion

_ctlsStru * p_ctls = NULL;
CHIP	ICC_Details;

enum
{
	NO_CONV_ASC,
	CONV_TO_ASC
};

static int ctlsInitialising = 1;
static AID_DATA AIDlist[10];

#define RSP_DATA_LEN ((*(rsp+12)<<8)|*(rsp+13))

#pragma endregion

#pragma region Data Types

typedef struct TlvCollection_
{
	char tag50_appLbl[18];
	char tag56_trk1EqData[81];
	char tag57_trk2EqData[21];
	char tag5a_pan[12]; 
	char tag5f20_cardHldrName[29];
	char tag5f24_expDate[6];		
	char tag5f2a_currCode[7];
	char tag5f34_appPanSeqNo[4];		
	char tag82_aip[4];
	char tag8e_cvmList[252];
	char tag95_tvr[7];
	char tag97_tdol[67];
	char tag9a_txnDate[5];
	char tag9b_tsi[4];
	char tag9c_txnType[5];		
	char tag9f02_amtAuthNum[9];
	char tag9f03_otherAmtNo[9];
	char tag9f06_appId[20];
	char tag9f07_appUsgCtrl[5];
	char tag9f09_appVerNo[5];
	char tag9f0d_iacDef[8];	
	char tag9f0e_iacDen[8];
	char tag9f0f_iacOnl[8];
	char tag9f10_iad[35];
	char tag9f1a_termCountryCode[5];
	char tag9f1b_termFloorLmt[7];
	char tag9f21_txnTime[6];
	char tag5f25_appEftDate[6];
	char tag9f26_appCrypto[11];
	char tag9f27_cid[4];	
	char tag9f33_termCap[6];	
	char tag9f34_cvmRes[6];
	char tag9f35_termType[4];
	char tag9f36_atc[5];
	char tag9f37_unpredNo[7];	
	char tag9f40_addTermCap[7];
	char tag9f45_dataAuthCode[5];
	char tag9f4c_iccDynNo[11];		
	char tag9f5d_avOflnSpendAmt[9];	
	char tag9f66_txnQual[7];							
	char tag9f6c_cardTxnQual[5];		
	char tag9f74_vlpIac[9];					
	char tage300_authCode[9];
	char tagffe0_appProviderId[8];
	char tagffe1_prtlSelAllow[4];
	char tagffe2_appFlow[4];		
	char tagffe3_ppseDisabled[4];
	char tagffe4_groupNo[4];			
	char tagffe5_maxAidLen[4];
	char tagffe6_AidDisabled[4];
	char tagfff1_txnLmt[9];
	char tagfff4_statusChk[6];
	char tagfff5_cvmReqLmt[9];
	char tagfff8_uiScheme[4];
	char tagfffb_lcdLangOpt[4];
	char tagfffc_forceMag[4];
	char tagfffd_tacOther[8];
	char tagfffe_tacDefault[8];
	char tagffff_tacDenial[8];	
} TlvCollection;

typedef struct TLV_
{
	short tag;
	short len;
	char val[1000];
} TLV;

#pragma endregion

#pragma region FuncPrototypes

static int InitComPort(char comPortNumber);
static void ResetMsg(void);
static void ResetRsp(void);
static void AddToMsg(char *subMsg, int length);
static void AddVivoHeader(void);
static void AddVivo2Header(void);
static void AppendCRC(void);
static void UnformatNStr(char *numStr, char *unfmtStr, int noDgts, char convAsc);
static void FormatAmt(char *amt, char *formattedAmt);
static int  GetNumDigits(char *amt, int length);
static int  CheckCRC(char *rsp);
static int  GetDataLen(char *rsp);

static void BuildSetPollOnDemandMsg(void);
static void BuildActivateTransactionMsg(char timeout);
static void BuildSetEMVTxnAmtMsg(void);
static void BuildCancelTransactionMsg(void);
static void BuildStoreLCDMsgMsg(char msgNdx, char *str, char *paramStr1, char *paramStr2, char *paramStr3);
static void BuildGetTLVsMsg(char *aid, short sz);
static void BuildGetCfgGroupMsg(char *groupNo);
static void BuildGetAllAidsMsg(void);
static void BuildDeleteAidMsg(char *aid, short len);
static void BuildSetDateMsgCF(void);
static void BuildSetTimeMsgCF(void);
static void BuildSetDateMsgDF(void);
static void BuildSetTimeMsgDF(void);
static void BuildSetEmvMsg(char *tlv, char closeMsg);
static void BuildSetCfgGroupMsg(char *tlv, char closeMsg);
static void BuildSetCfgAidMsg(char *tlv, char closeMsg);
static void BuildSetCAPubKeyMsgCF(char dataLen1, char dataLen2);
static void BuildSetCAPubKeyMsgDF(char *data, char len);

static int SetPollOnDemandMode(void);
static int ActivateTransaction(char waitForRsp, int timeout);
static int CancelTransaction(int reason);
static int SetEMVTxnAmt(void);
static int GetPayment(char waitForRsp, int timeout);
static int StoreLCDMsg(char msgNdx, char *str, char *paramStr1, char *paramStr2, char *paramStr3);
static int GetCfgGroup(char *groupNo);
static int GetCfgGroupForAid(char *Aid, short sz);
static int SetSource(void);
static int SetDateTime(void);
static int SetCAPubKey(char *keyFile);
static int SetCAPubKeys(void);
static int DeleteCAPubKeys(void);
static int SetTxnLimit(char *amt);
static int SetCfgAids(void);
static int DeleteAids(void);
static int SetCfgGroups(void);
static int SetEmvParams(void);
static int GetAllAids(void);

static void InitRdr(char comPortNumber);
static int CbAcquireCard(void *pParams);
static int CbProcessCard(void *pParams);
static int CbCancelAcquireCard(void *pParams);

static int SendRxMsg(int timeout);
static int GetRsp(char waitForRsp, int timeout);
static int AcquireRsp(char waitForRsp, int timeout);
static int ExtractCardDetails(void);
static int ExtractClearingRec(char *clrRec);
static int ExtractTrack(char *trk, char *trkInfo);
static int ExtractEMVDetails(void);
static int ExtractFailedEMVDetails(char *details, int length);
static int ExtractTLVs(void);
static int HandleErrRsp(void);
static int HandleReqOLErrRsp(void);
static int HandleNoReqOLErrRsp(void);
static void getTlv(char *tlv, TLV *tlvStruct);
static int processEmvTlv(char *tlv);
static int processCfgAidTlv(char *tlv);
static int processCfgGroupTlv(char *tlv);
static int GetRspStatus(void);
static char GetFrameType(void);
static int HandleRTCNFrame(void);
static int HandleKeyMgtNFrame(void);

static int SetEMVTermCap(void);
static void BuildSetEMVTrmCapMsg(void);
static int SendRawMsg(void);
static void BuildRawMsg(char* tlv,int tlvlen);
static int SetADDReaderPrm(void);
static void BuildSetADDReaderPrm(void);
static void BuildSetEMVGrpMsg(void);
static void BuildDelGroup(void);

#pragma endregion
#pragma region TLV ops

//T
static short Tag2(char *pTag) { return (short)(*pTag & 0xFF); }
static short Tag4(short *pTag) { return *pTag; }
static char Is2DigTag(char *pTag) { return (*pTag & 0x1F)!=0x1F; }
static char TagLen(char *pTag) { return Is2DigTag(pTag)?1:2; }
//L
static char Is1ByteLen(char *pLen) { return ((*pLen & 0x80) < 0x80); }
static char LenLen(char *pLen) { return (Is1ByteLen(pLen)?1:*pLen & 0x7F); }
//TLV
static short Tag(char *pTag) { return (Is2DigTag(pTag)?Tag2(pTag):Tag4((short*)pTag)); }
static short Len(char *pLen) { return (Is1ByteLen(pLen)?*pLen & 0x7F:*(short*)(pLen+1) & (1<<(LenLen(pLen)*8))-1); }
static char *Val(char *tlv)
{
	TLV tlvStruct = {0};
	getTlv(tlv, &tlvStruct);
	return tlv+TagLen((char*)&tlvStruct.tag)+LenLen((char*)&tlvStruct.len);
}
static int TLVLen(char* tlv) 
{	
	TLV tlvStruct = {0};
	getTlv(tlv, &tlvStruct);
	return TagLen((char*)&tlvStruct.tag)+LenLen((char*)&tlvStruct.len)+tlvStruct.len;
}
void ExtractNTo(TLV tlvStruct, char *TO, int length, char ASCII)
{
	char unfVal[1000] = {0};
	UnformatNStr(tlvStruct.val, unfVal, tlvStruct.len*2, ASCII);
	memset(TO, 0, length);
	memcpy(TO, unfVal, tlvStruct.len*2);
}
void ExtractBTo(TLV tlvStruct, char *TO, int length, char ASCII)
{
	if(ASCII) SVC_HEX_2_DSP(tlvStruct.val, TO, tlvStruct.len);
	else
	{
		memset(TO, 0, length);
		memcpy(TO, tlvStruct.val, tlvStruct.len);
	}
}
/* 
void ExtractDTo(TLV tlvStruct, Date *TO)
{
	char unfVal[1000] = {0};
	char date[9] = {'2', '0', 0,0,0,0,0,0,0};
	UnformatNStr(tlvStruct.val, unfVal, tlvStruct.len*2, 1);
	memcpy(date+2, unfVal, 6);
}
*/
#pragma endregion

#pragma region LocalVars

static char msg[CTLS_BUFF_SZ] = {0};
static char rsp[CTLS_BUFF_SZ] = {0};
static int  msgLength = 0;
static int  rspLength = 0;
static TlvCollection TLVs = {0};
#pragma endregion

#pragma region Utils

static int InitComPort(char comPortNumber)
{	
	int i = 0;
	int ret;
	
	ret = CTLSInitInterface(20000);
	LOG_PRINTFF(0x00000001L,"CTLSInitInterface ret %d", ret);
	if (ret != 0)
	{
		LOG_PRINTFF(0x00000001L,"error initialising CTLS reader");
		return -1;
	}

	// open CTLS
	for(i=0;i<20;i++) {
		ret = CTLSOpen();
		if(ret) SVC_WAIT(500);
		else break;
	}
	if (ret != 0)
	{
		LOG_PRINTFF(0x00000001L,"error Opening CTLS reader");
		return -1;
	}
	
	// configure the CTLS app
	CTLS_GREEN_STYLE_LED;
	CTLSClientUIParamHandler(UI_LED_STYLE_PARAM, &ret, sizeof(ret));
	CTLSClientUISetCardLogoBMP("N:/CTLSMV.bmp");

	return ret;
}

static void ResetMsg()
{
	memset(msg, 0, sizeof(msg));
	msgLength = 0;
}

static void ResetRsp()
{	
	memset(rsp, 0, sizeof(rsp));
	rspLength = 0;	
}

static void AddToMsg(char *subMsg, int length)
{		
	memcpy(msg+msgLength, subMsg, length);	
	msgLength += length;	
}

static void AddVivoHeader(void)
{
	AddToMsg(VIVO_HDR_STR, strlen(VIVO_HDR_STR)+1);
}

static void AddVivo2Header()
{
	AddToMsg(VIVO2_HDR_STR, strlen(VIVO2_HDR_STR)+1);
}

static void AppendCRC()
{
	unsigned short crc = SVC_CRC_CCITT_M(msg, msgLength, 0xFFFF);	
	AddToMsg((char*)&crc, 2);	
}

static int GetDataLen(char *rsp)
{
	return ((*(rsp+V2_DAT_LEN_MSB_OFS) << 8) | *(rsp+V2_DAT_LEN_LSB_OFS));		
}

static int CheckCRC(char *rsp)
{
	unsigned short suppliedCRC = 
		*(rsp+V2_CRC_MSB_OFS+GetDataLen(rsp)) |
		(*(rsp+V2_CRC_LSB_OFS+GetDataLen(rsp)) << 8);
	
//	LOG_PRINTFF(0x00000001L,"CheckCRC");
	if(SVC_CRC_CCITT_M(rsp, GetDataLen(rsp)+V2_FXD_BYTES-2, 0xFFFF) == suppliedCRC)		
	{
	//	LOG_PRINTFF(0x00000001L,"CheckCRC 1");
		return CTLS_SUCCESS;	
	}
//	LOG_PRINTFF(0x00000001L,"CheckCRC 2");
	return CTLS_CRC_CHK_FAILED;
}

static int GetNumDigits(char *amt, int length)
{
	int numDigits = 0, i = 0;
	for(; i < length; i++) if(isdigit(amt[i])) numDigits++;
	return numDigits;
}

static void UnformatNStr(char *numStr, char *unfmtStr, int noDgts, char convAsc)
{	
	if(convAsc) SVC_HEX_2_DSP(numStr, unfmtStr, noDgts);
	else
	{	
		int i = 0, j = 0;

		for(; i < noDgts; i++)
		{
			if(!(i%2)) numStr[i] = (numStr[j] >> 4);
			else
			{
				numStr[i] = (numStr[j] & 0x0F);
				j++;
			}
		}
	}
}

static void FormatAmt(char *amt, char *formattedAmt)
{
	int fAmtNdx = 0, tAmtNdx = 0, posToggle = 0;

	int padLength = 
		12-strlen(amt)+
		(strlen(amt)-GetNumDigits(amt, 12));		

	memset(formattedAmt, 0, 6);			

	fAmtNdx = (padLength-(padLength%2?1:0))/2; //pad with 0's	

	posToggle = padLength%2; //set byte position flag

	while(fAmtNdx < 6)
	{
		if(isdigit(amt[tAmtNdx])) 
		{			
			if(!posToggle)		
				formattedAmt[fAmtNdx] = ((amt[tAmtNdx]-0x30) << 4);				
			else			
				formattedAmt[fAmtNdx++] |= amt[tAmtNdx]-0x30;							
			
			posToggle = !posToggle;
		}
		tAmtNdx++;
	}
}

///////////////////helpers////////////////////

static int SendMsg() 
{	
	int res = -1;
	LOG_PRINTFF(0x00000001L,"SendMsg");
	res = CTLSSend((char *)msg, msgLength);
	if(CTLSDEBUG) {
		char stmp[1024]="";
		long len = 0;
		LOG_PRINTFF(0x00000001L,"CTLSSent:%d",msgLength);
		for(len=0;len<msgLength;len++) sprintf(&stmp[strlen(stmp)],"%02x",	msg[len]);
		for(len=0;len<msgLength*2;len+=100) LOG_PRINTFF(0x00000001L,"[%-.100s]",stmp+len);
	}
	SVC_WAIT(50);
	return res;
}

static int SendRxMsg(int timeout)
{			
	int snd;
	//LOG_PRINTFF(0x00000001L,"SendRxMsg");
	snd = SendMsg();		
	if(snd < 0) 
	{
		LOG_PRINTFF(0x00000001L,"SendRxMsg failed");
		return snd;
	}
	//LOG_PRINTFF(0x00000001L,"SendRxMsg 2");
	snd = GetRsp(1, timeout);	
	//LOG_PRINTFF(0x00000001L,"SendRxMsg snd :%d",snd);
	return snd;
}

static int GetRsp(char waitForRsp, int timeout)
{		 	
	int bytes;
	//LOG_PRINTFF(0x00000001L,"GetRsp");
	ResetMsg();
	//LOG_PRINTFF(0x00000001L,"GetRsp 1");
	bytes = AcquireRsp(waitForRsp, timeout);
	//LOG_PRINTFF(0x00000001L,"bytes :%d",bytes);
	if(!bytes) 
	{
	//	//LOG_PRINTFF(0x00000001L,"GetRsp 2");
		return bytes;	
	}

	if( bytes < 0 ) 
	{
		return bytes;	
	}

	//Check CRC	
	return CheckCRC(rsp);
	//return CTLS_SUCCESS;
}

static int AcquireRsp(char waitForRsp, int timeout)
{		
	unsigned long t1 = read_ticks();
	extern int mcrHandle ;
	int cardinput = 0;
	char temp[6];

	if(p_ctls) cardinput = 1;

	ResetRsp();

	if(!timeout) timeout = 20000; //default

	if(cardinput) {
		if(EmvIsCardPresent()) return(-1002);
	}

	for(;;)
	{				
		int i;
		if(cardinput)
		{
			unsigned char key = 0;
			int evt = 0;

			if(read(STDIN, &key,1) == 1)
			{
				key &= 0x7F;
				if(key == KEY_CNCL)
				{
					LOG_PRINTFF(0x00000001L,"AcquireRsp key cancel");
					return -1;
				}
			}

			if (mcrHandle == 0) mcrHandle = open(DEV_CARD, 0);
			evt = read_evt(EVT_MAG|EVT_ICC1_INS);
			if(evt & EVT_MAG) {
				return(-1001);
			}

			if(evt & EVT_ICC1_INS) {
				return(-1002);
			}
		}
		
		if(	(i=CTLSReceive((char *)&rsp+rspLength, sizeof(rsp)-rspLength))>0)
		{	
			//attempt quick reads
			rspLength += i;			
			t1 = read_ticks();
			for(;;)
			{						
				if(	(i=CTLSReceive((char *)&rsp+rspLength, sizeof(rsp)-rspLength))>0)
				{		
					t1 = read_ticks();
					rspLength += i;
					SVC_WAIT(10);
					continue;
				}				
				break;				
			}
		}
		if(rspLength)
		{
			if(read_ticks() > t1+50)		
			{
				if(CTLSDEBUG) {
				char stmp[1024]="";
				long len = 0;
				LOG_PRINTFF(0x00000001L,"CTLSreceived:%d",rspLength);
				for(len=0;len<rspLength;len++) sprintf(&stmp[strlen(stmp)],"%02x",	rsp[len]);
				for(len=0;len<rspLength*2;len+=100) LOG_PRINTFF(0x00000001L,"[%-.100s]",stmp+len);
				SVC_WAIT(50);
				}

				return rspLength;			
			}
		}
		else
		{	
			if(!waitForRsp) 
			{
				//LOG_PRINTFF(0x00000001L,"AcquireRsp 3");
				return 0;			
			}
			
			if(read_ticks() > t1+timeout)
			{	
				LOG_PRINTFF(0x00000001L,"AcquireRsp 4");
				return CTLS_RSP_TIMED_OUT;
			}			
		}
		SVC_WAIT(0);
	}	
}

#pragma endregion

#pragma region MsgProcessing

static int HandleReqOLErrRsp()
{
	LOG_PRINTFF(0x00000001L,"handling req onl err");
	processEmvTlv(rsp+V2_DATA_OFS+V2_ERR_T2_OFS);	
	LOG_PRINTFF(0x00000001L,"handling req onl err 1");
	ExtractFailedEMVDetails(rsp+V2_DATA_OFS+31, GetDataLen(rsp)-31);
	LOG_PRINTFF(0x00000001L,"handling req onl err 2");
	return CTLS_EMV | CTLS_REQ_OL; //change this return value maybe
}

static int HandleNoReqOLErrRsp()
{	
	LOG_PRINTFF(0x00000001L,"handling no req onl err. err is %x", *(rsp+V2_DATA_OFS));
	LOG_PRINTFF(0x00000001L,"handling no req onl err. err is %x", *(rsp+V2_DATA_OFS+9));

	ExtractFailedEMVDetails(rsp+V2_DATA_OFS+9, GetDataLen(rsp)-9);

#pragma region switch(ERROR)
	//We know it's not req onl so what err is it?
	switch(*(rsp+V2_DATA_OFS))
	{
		//////////DECLINE TXN//////////
	case V2_NO_ERR:
		//something went wrong but nothing went wrong? BAIL!
		LOG_PRINTFF(0x00000001L,"ERROR! HandleNoReqOLErrRsp() called but ERR == 0");
		return CTLS_UNKNOWN | CTLS_DECLINED;
	case V2_AMT_ZERO:
		//IGNORE TXN!
		LOG_PRINTFF(0x00000001L,"ERROR! Contactless zero amount txn");
		return CTLS_UNKNOWN | CTLS_DECLINED;
	case V2_OUT_SEQ_CMD:
		//slap my wrists - software error
		LOG_PRINTFF(0x00000001L,"ERROR! Contactless received out of sequence command");
		return CTLS_UNKNOWN | CTLS_DECLINED;
	case V2_UNK_DAT_ELMT:
	case V2_DAT_ELMT_MISS:
		//reserved future use
		LOG_PRINTFF(0x00000001L,"ERROR! Reserved contactless error code has been used: %d", *(rsp+V2_DATA_OFS));
		return CTLS_UNKNOWN | CTLS_DECLINED;
	case V2_CA_PUB_KEY_FAIL:
		//must fix missing key problem, could try sending it if have it	
		LOG_PRINTFF(0x00000001L,"ERROR! Contactless missing public key");
		return CTLS_UNKNOWN | CTLS_DECLINED;
	case V2_ISS_PUB_KEY_FAIL:
		//must fix key problem, could try resending it
		LOG_PRINTFF(0x00000001L,"ERROR! Recovering contactless issuer public key");		
		return CTLS_UNKNOWN | CTLS_DECLINED;
	case V2_SDA_FAIL:	
		//retry not worth it
		LOG_PRINTFF(0x00000001L,"ERROR! Contactless data auth failed during SSAD");
		return CTLS_UNKNOWN | CTLS_DECLINED;
	case V2_ICC_PUB_KEY_FAIL:	
		//retry not worth it
		LOG_PRINTFF(0x00000001L,"ERROR! Contactless data auth failed during attempted recovery of ICC pub key");
		return CTLS_UNKNOWN | CTLS_DECLINED;
	case V2_DYN_SIG_VER_FAIL:
		//retry not worth it
		LOG_PRINTFF(0x00000001L,"ERROR! Contactless data auth failed during dynamic sig verif");				
		return CTLS_UNKNOWN | CTLS_DECLINED;
	case V2_PRCS_RST_FAIL:	
		//could be wrong emv params, retry not worth it
		LOG_PRINTFF(0x00000001L,"ERROR! Contactless processing restrictions step failed");
		return CTLS_EMV | CTLS_DECLINED;
	case V2_TRM_FAIL:	
		//could be wrong emv params, retry not worth it
		LOG_PRINTFF(0x00000001L,"ERROR! Contactless terminal risk management step failed"); 
		return CTLS_EMV | CTLS_DECLINED;
	case V2_CVM_FAIL:		
		//could be wrong emv params, retry not worth it
		LOG_PRINTFF(0x00000001L,"ERROR! Contactless cardholder verification step failed"); 
		return CTLS_EMV | CTLS_DECLINED;
	case V2_TAA_FAIL:
		LOG_PRINTFF(0x00000001L,"ERROR! Contactless terminal action analysis step failed"); 
		//could be wrong emv params, retry not worth it
		return CTLS_EMV | CTLS_DECLINED;
	case V2_CRD_ERR_STAT:
		//card returned error
		if(*(rsp+V2_DATA_OFS+3) >= 3) 			
			return CTLS_UNKNOWN | CTLS_FALL_FORWARD; 	
		//else fall through	
	case V2_CRD_EXPD:
		//visa only	
		return CTLS_UNKNOWN | CTLS_DECLINED;
	case V2_CRD_GEN_AAC:
		strcpy((char*)ICC_Details.CrypInfoData, AAC);
		return CTLS_EMV | CTLS_DECLINED;
		//////////FALL FORWARD//////////	
	case V2_CRD_BLKD:
		//card blocked
	case V2_CRD_NOT_SUPP:
		//possibly no aid for card
	case V2_AMT_OVR_MAX:
		//txn above offline limit	
	case V2_GOTO_CNT:
		//fall forward
		LOG_PRINTFF(0x00000001L,"ERROR! Contactless try contact txn");
		sprintf(p_ctls->TxnStatus,"%2d",99);
		return CTLS_UNKNOWN | CTLS_TRY_CONTACT;			
		//////////RETRY TXN//////////
	case V2_CRD_NOT_RSP:
		//card removed from field, try again
		if(!strstr(TLVs.tag50_appLbl, "VISA") && 
			!strstr(TLVs.tag50_appLbl, "visa") &&
			!strstr(TLVs.tag50_appLbl, "Visa") &&
			!strstr(TLVs.tag50_appLbl, "V PAY"))
		{
			if(*(rsp+V2_DATA_OFS+3) >= 3)
				return CTLS_UNKNOWN | CTLS_FALL_FORWARD;
		}
		//}
	case V2_COLLISION:
		//more than 1 card - retry txn
		return CTLS_UNKNOWN | CTLS_RETRY;	

		//////////REQUEST ONLINE AUTH//////////
	case V2_REQ_OL_AUTH:
		//THIS IS AN ERROR!!! WE ARE IN THIS PROC BECAUSE IT'S NOT REQ ONL!!
		//above card balance but below max offline
		return CTLS_UNKNOWN | V2_REQ_OL_AUTH;		

	case V2_CRD_GEN_ARQC:
		strcpy((char*)ICC_Details.CrypInfoData, ARQC);
		return CTLS_EMV | V2_REQ_OL_AUTH;
	
	case V2_SD_MEM_ERR:
		//only see this when requesting txn logs
		break;
	default:
		break;
	}
#pragma endregion

	LOG_PRINTFF(0x00000001L,"Unknown No Req OL Error Code");
	return CTLS_UNKNOWN | CTLS_DECLINED;
}

static int HandleErrRsp()
{	
	LOG_PRINTFF(0x00000001L,"HandleErrRsp");
	if(*(rsp+V2_DATA_OFS) == V2_REQ_OL_AUTH)
	{		
		LOG_PRINTFF(0x00000001L,"HandleErrRsp 1");
		//retries = 0;
		strcpy((char*)ICC_Details.CrypInfoData, ARQC);
		LOG_PRINTFF(0x00000001L,"HandleErrRsp 2");
		return HandleReqOLErrRsp();	
	}	
	LOG_PRINTFF(0x00000001L,"HandleErrRsp 3");
	return HandleNoReqOLErrRsp();	
}

static int HandleRTCNFrame()
{
	LOG_PRINTFF(0x00000001L,"NACK RXD - ERR CODE IS %d", *(rsp+12));
	switch(*(rsp+12))
	{	
	case V1_RTC_ERR_UNK:
	case V1_RTC_INV_DATA:
	case V1_RTC_ERR_NO_RTC_RSP:
	case V1_RTC_NO_ERR:
	default:
		break;
	}
	return CTLS_FAILED;
}

static int HandleKeyMgtNFrame(void)
{
	LOG_PRINTFF(0x00000001L,"NACK RXD - ERR CODE IS %d", *(rsp+12));
	switch(*(rsp+12))
	{	
	case V1_KEYMGT_NO_ERR:
	case V1_KEYMGT_UNK_ERR:	
	case V1_KEYMGT_INV_DATA:
	case V1_KEYMGT_DATA_NOT_CMP:
	case V1_KEYMGT_INV_KEY_NDX:
	case V1_KEYMGT_INV_HSH_ALG_IND:
	case V1_KEYMGT_INV_KEY_ALG_IND:
	case V1_KEYMGT_INV_KEY_MOD_Len:
	case V1_KEYMGT_INV_KEY_EXP:
	case V1_KEYMGT_KEY_EXISTS:
	case V1_KEYMGT_NO_SPACE:
	case V1_KEYMGT_KEY_NOT_FOUND:
	case V1_KEYMGT_CRYP_CHP_NO_RSP:
	case V1_KEYMGT_CRYP_CHP_COM_ERR:
	case V1_KEYMGT_RID_SLT_FULL:
	case V1_KEYMGT_NO_FREE_SLOTS:
	default:
		break;
	}
	return CTLS_FAILED;
}

static int ExtractCardDetails()
{	
	int emvRes, magRes; 
	
	LOG_PRINTFF(0x00000001L,"ExtractCardDetails");
	
	emvRes = ExtractEMVDetails();	
	magRes = ExtractTrack("2", rsp+V2_DATA_OFS);	

	if(emvRes == CTLS_NO_CLR_REC) 
	{
		LOG_PRINTFF(0x00000001L,"ExtractCardDetails");
		return magRes == CTLS_SUCCESS ?CTLS_MSD:magRes;
	}

	LOG_PRINTFF(0x00000001L,"Clearing record present emvRes:%d",emvRes);

	if(emvRes != CTLS_SUCCESS)
	{
		LOG_PRINTFF(0x00000001L,"Clearing record present ");
		return emvRes;
	}
	else
	{		
		TLV tlv = {0};
		
		getTlv(TLVs.tag9f06_appId, &tlv);
		emvRes = GetCfgGroupForAid(tlv.val, tlv.len);			
		//LOG_PRINTFF(0x00000001L,"ExtractCardDetails 1");
		if(emvRes == CTLS_SUCCESS)
		{			
			if(!*ICC_Details.CrypInfoData)
			{
				//Must be VISA
				char hex[32] = {0};
				SVC_DSP_2_HEX((char*)ICC_Details.IADIssuer, hex, strlen((char*)ICC_Details.IADIssuer)/2);				

				switch(hex[4] & 0x30)
				{
				case 0x00:
					//LOG_PRINTFF(0x00000001L,"AAC");					
					strcpy((char*)ICC_Details.CrypInfoData, AAC);
					break;				
				case 0x10:
					//LOG_PRINTFF(0x00000001L,"TC");					
					strcpy((char*)ICC_Details.CrypInfoData, TC);
					break;
				case 0x20:
					//LOG_PRINTFF(0x00000001L,"ARQC");					
					strcpy((char*)ICC_Details.CrypInfoData, ARQC);
					break;
				default:
					break;
				}	
			}			

		}		
	}		
	//LOG_PRINTFF(0x00000001L,"ExtractCardDetails emvRes:%d",emvRes);
	return (emvRes==CTLS_SUCCESS ?CTLS_EMV:emvRes);
}

static void getTlv(char *tlv, TLV *tlvStruct)
{
	int tlvStart, tagLen, lenLen;
	short tg, ln;
	//LOG_PRINTFF(0x00000001L,"getTlv");
	
	if(!tlv || !tlvStruct) return;
	memset(tlvStruct, 0, sizeof(TLV));
	//LOG_PRINTFF(0x00000001L,"getTlv 1");
	//LOG_PRINTFF(0x00000001L,"tlv:%s:%x:%d",tlv,tlv,tlv);
	memcpy(&tlvStart, tlv, sizeof(tlvStart));
	tagLen = (Is2DigTag((char*)&tlvStart))?1:2;
	lenLen = LenLen((char*)&tlvStart+tagLen);
	//LOG_PRINTFF(0x00000001L,"getTlv 2");
	tg = Tag((char*)&tlvStart) & 0xFFFF;
	tlvStruct->tag = tg;
	memcpy(&ln, tlv+tagLen, sizeof(short));
	//LOG_PRINTFF(0x00000001L,"getTlv 3");
	ln = Len((char*)&ln) & 0xFFFF;
	//LOG_PRINTFF(0x00000001L,"getTlv 3.1");
	tlvStruct->len = ln;
	//LOG_PRINTFF(0x00000001L,"ln:%d,tagLen:%d,lenLen",ln,tagLen,lenLen);
	//LOG_PRINTFF(0x00000001L,"getTlv 3.2");
	memcpy(tlvStruct->val, tlv+tagLen+lenLen, ln);	
	//LOG_PRINTFF(0x00000001L,"getTlv 4");
}

static int processCfgGroupTlv(char *tlv)
{
	TLV tlvStruct = {0};
	getTlv(tlv, &tlvStruct);

	switch(tlvStruct.tag & 0xFFFF)
	{
	case 0xFFE4:				
		memcpy(TLVs.tagffe4_groupNo, tlv, TLVLen(tlv));
		return TLVLen(tlv);
	case 0x5F2A:				
		memcpy(TLVs.tag5f2a_currCode, tlv, TLVLen(tlv));
		return TLVLen(tlv);
	case 0x9C:				
		memcpy(TLVs.tag9c_txnType, tlv, TLVLen(tlv));
		return TLVLen(tlv);		
	case 0x9F1A:		
		memcpy(TLVs.tag9f1a_termCountryCode, tlv, TLVLen(tlv));
		return TLVLen(tlv);
	case 0x9F1B:		
		memcpy(TLVs.tag9f1b_termFloorLmt, tlv, TLVLen(tlv));		
		{
			int i = 0;
			long limit = 0;
			char fl[20] = {0};			
			ExtractBTo(tlvStruct, fl, sizeof(fl), CONV_TO_ASC);
			for(i = strlen(fl)-1; i >= 0; i--)
				limit += (fl[i]-(isdigit(fl[i])?0x30:0x37))*pow(16, strlen(fl)-i-1);
			//Dwarika
			//ICC_Details.FloorLimit = limit;
		}
		return TLVLen(tlv);
	case 0x9F33:		
		memcpy(TLVs.tag9f33_termCap, tlv, TLVLen(tlv));				
		//Dwarika
		//ExtractBTo(tlvStruct, (char*)ICC_Details.emvTerminalCapabilities, sizeof(ICC_Details.emvTerminalCapabilities), CONV_TO_ASC);
		return TLVLen(tlv);
	case 0x9F35:		
		memcpy(TLVs.tag9f35_termType, tlv, TLVLen(tlv));				
		ExtractBTo(tlvStruct, (char*)ICC_Details.TerType, sizeof(ICC_Details.TerType), CONV_TO_ASC);
		ExtractBTo(tlvStruct, (char*)ICC_Details.EMV_Term_Type, sizeof(ICC_Details.EMV_Term_Type), CONV_TO_ASC);		
		return TLVLen(tlv);
	case 0x9F40:		
		memcpy(TLVs.tag9f40_addTermCap, tlv, TLVLen(tlv));
		return TLVLen(tlv);
	case 0x9F66:			
		memcpy(TLVs.tag9f66_txnQual, tlv, TLVLen(tlv));		
		return TLVLen(tlv);
	case 0xFFF1:		
		memcpy(TLVs.tagfff1_txnLmt, tlv, TLVLen(tlv));
		return TLVLen(tlv);
	case 0xFFF4:		
		memcpy(TLVs.tagfff4_statusChk, tlv, TLVLen(tlv));
		return TLVLen(tlv);
	case 0xFFF5:					
		memcpy(TLVs.tagfff5_cvmReqLmt, tlv, TLVLen(tlv));		
		return TLVLen(tlv);
	case 0xFFFB:				
		memcpy(TLVs.tagfffb_lcdLangOpt, tlv, TLVLen(tlv));
		return TLVLen(tlv);
	case 0xFFFC:				
		memcpy(TLVs.tagfffc_forceMag, tlv, TLVLen(tlv));
		return TLVLen(tlv);
	case 0xFFFD:			
		memcpy(TLVs.tagfffd_tacOther, tlv, TLVLen(tlv));				
		ExtractBTo(tlvStruct, (char*)ICC_Details.TAC_Online, sizeof(ICC_Details.TAC_Online), CONV_TO_ASC);
		return TLVLen(tlv);
	case 0xFFFE:						
		memcpy(TLVs.tagfffe_tacDefault, tlv, TLVLen(tlv));				
		ExtractBTo(tlvStruct, (char*)ICC_Details.TAC_Default, sizeof(ICC_Details.TAC_Default), CONV_TO_ASC);
		return TLVLen(tlv);
	case 0xFFFF:
		memcpy(TLVs.tagffff_tacDenial, tlv, TLVLen(tlv));				
		ExtractBTo(tlvStruct, (char*)ICC_Details.TAC_denial, sizeof(ICC_Details.TAC_denial), CONV_TO_ASC);
		return TLVLen(tlv);
	case 0x97:				
		memcpy(TLVs.tag97_tdol, tlv, TLVLen(tlv));
		return TLVLen(tlv);		
	case 0x9F09:		
		memcpy(TLVs.tag9f09_appVerNo, tlv, TLVLen(tlv));				
		ExtractBTo(tlvStruct, (char*)ICC_Details.TermAppVer, sizeof(ICC_Details.TermAppVer), CONV_TO_ASC);
		return TLVLen(tlv);
	case 0xFFF8:		
		memcpy(TLVs.tagfff8_uiScheme, tlv, TLVLen(tlv));
		return TLVLen(tlv);		
	default:
		LOG_PRINTFF(0x00000001L,"Tag %x not known", tlvStruct.tag);
		return CTLS_TLV_ERR_T;
	}
}

static int processCfgAidTlv(char *tlv)
{	
	TLV tlvStruct = {0};
	getTlv(tlv, &tlvStruct);	

	switch(tlvStruct.tag & 0xFFFF)
	{		
	case 0x9F06:							
		memcpy(TLVs.tag9f06_appId, tlv, TLVLen(tlv));
		return TLVLen(tlv);
	case 0xFFE0:						
		memcpy(TLVs.tagffe0_appProviderId, tlv, TLVLen(tlv));
		return TLVLen(tlv);
	case 0xFFE1:						
		memcpy(TLVs.tagffe1_prtlSelAllow, tlv, TLVLen(tlv));
		return TLVLen(tlv);
	case 0xFFE2:						
		memcpy(TLVs.tagffe2_appFlow, tlv, TLVLen(tlv));
		return TLVLen(tlv);
	case 0xFFE3:						
		memcpy(TLVs.tagffe3_ppseDisabled, tlv, TLVLen(tlv));
		return TLVLen(tlv);
	case 0xFFE4: 								
		memcpy(TLVs.tagffe4_groupNo, tlv, TLVLen(tlv));
		return TLVLen(tlv);
	case 0xFFE5:						
		memcpy(TLVs.tagffe5_maxAidLen, tlv, TLVLen(tlv));
		return TLVLen(tlv);
	case 0xFFE6:						
		memcpy(TLVs.tagffe6_AidDisabled, tlv, TLVLen(tlv));
		return TLVLen(tlv);
	default:
		LOG_PRINTFF(0x00000001L,"Tag %x not known", tlvStruct.tag);
		return CTLS_TLV_ERR_T;
	}
}

static int processEmvTlv(char *tlv)
{		
	TLV tlvStruct = {0};
	char string[1024];
	char stmp[30];
	
	getTlv(tlv, &tlvStruct);
	
#pragma region switch(tag)
	switch(tlvStruct.tag & 0xFFFF)
	{			
	default:
		sprintf(stmp,"%X", (tlvStruct.tag & 0xFFFF));
		if(strlen(stmp)==2) strcat(stmp,"00");
		memcpy(&p_ctls->sTLvData[p_ctls->nTLvLen],stmp,4);
		p_ctls->nTLvLen = p_ctls->nTLvLen + 4;
		sprintf(&p_ctls->sTLvData[p_ctls->nTLvLen],"%02x",tlvStruct.len);
		p_ctls->nTLvLen = p_ctls->nTLvLen + 2;
		memset(string,0x00,sizeof(string));
		UtilHexToString((const char *)tlvStruct.val , tlvStruct.len , string);
		memcpy(&p_ctls->sTLvData[p_ctls->nTLvLen],string,strlen(string));
		p_ctls->nTLvLen = p_ctls->nTLvLen + strlen(string);
		
		return TLVLen(tlv);
	}
#pragma endregion
}

static int ExtractClearingRec(char *clrRec)
{
	char len = *(clrRec+1), dataRead = 0;	
	LOG_PRINTFF(0x00000001L,"ExtractClearingRec len:%d:", len);
	while(dataRead < len)
	{
		int read = processEmvTlv(clrRec+2+dataRead);
		if(read > 0) dataRead += read;
		else 
		{
			LOG_PRINTFF(0x00000001L,"ExtractClearingRec 1");
			return read;		
		}
	}	
	
	return dataRead;
}

static int ExtractEMVDetails()
{
	int t1Len, t2Len, dataRead = 0, dataLen = GetDataLen(rsp);
	char *track1, *track2;

	LOG_PRINTFF(0x00000001L,"extracting EMV details");

	t1Len = *(rsp+V2_DATA_OFS);
	//Dwarika .. 20121117
	track1 = rsp+V2_DATA_OFS+1;
	//track1 = rsp+V2_DATA_OFS+t1Len;
	
	t2Len = *(track1+t1Len);
	track2 = track1+1+t1Len;
	
	memcpy(p_ctls->sTrackOne,track1,t1Len);
	memcpy(p_ctls->sTrackTwo,track2,t2Len);
	
	dataRead += t1Len+t2Len+2;	   
	
	dataRead++;
	if(!*(track2+t2Len)) 
	{
		LOG_PRINTFF(0x00000001L,"extracting EMV details 1");
		//return CTLS_NO_CLR_REC;
	} else
		dataRead += ExtractClearingRec(rsp+V2_DATA_OFS+dataRead)+2;		

	LOG_PRINTFF(0x00000001L,"extracting EMV details 2");
	//Get remaining TLVs
	while(dataRead < dataLen)
	{			
		int read = processEmvTlv(rsp+V2_DATA_OFS+dataRead);				
		if(read > 0) dataRead += read;
		else 
		{
			LOG_PRINTFF(0x00000001L,"extracting EMV details 3");
			return read;
		}
	}	
	
	LOG_PRINTFF(0x00000001L,"extracting EMV details 4");
	return CTLS_SUCCESS;
}

static int ExtractFailedEMVDetails(char *details, int length)
{
	int dataRead = 0;
	
	LOG_PRINTFF(0x00000001L,"ExtractFailedEMVDetails");
	
	//Get remaining TLVs
	while(dataRead < length)
	{				
		int read = processEmvTlv(details+dataRead);		
		LOG_PRINTFF(0x00000001L,"ExtractFailedEMVDetails 1");
		if(read > 0) dataRead += read;
		else return read;
	}
	LOG_PRINTFF(0x00000001L,"ExtractFailedEMVDetails 2");
	return CTLS_SUCCESS;
}

//formats data so accepted by card_parse()
static int ExtractTrack(char *trk, char *trkInfo)
{	
	return CTLS_SUCCESS;
}

static int GetRspStatus()
{	
	if(rspLength < 1) return CTLS_NO_REPLY;	
	return *(rsp+V2_STATUS_OFS);
}

static int ExtractTLVs()
{
	int dataRead = 0;	
	
	while(dataRead < RSP_DATA_LEN)
	{
		int read = processCfgAidTlv(rsp+V2_DATA_OFS+dataRead);
		if(read > 0) dataRead += read;
		else return read;
	}

	return CTLS_SUCCESS;
}

static int ExtractCfgGroup()
{
	int dataRead = 0;	
	
	if(GetRspStatus() == V2_FAILED_NAK) return CTLS_FAILED;		

	while(dataRead < RSP_DATA_LEN)
	{		
		int read = processCfgGroupTlv(rsp+V2_DATA_OFS+dataRead);		
		if(read > 0) dataRead += read;
		else return read;
	}
		
	return CTLS_SUCCESS;
}

static char GetFrameType()
{
	return *(rsp+9);
}
////////////////////////////////////////
#pragma endregion

#pragma region MsgBuilders
////////////////Build Contactless Msgs//////////////

static void BuildSetPollOnDemandMsg()
{	
	char fields[5] = {0x01, 0x01, 0x00, 0x01, 0x01};
	LOG_PRINTFF(0x00000001L,"BuildSetPollOnDemandMsg");
	ResetMsg();
	AddVivo2Header();
	AddToMsg(fields, sizeof(fields));		
	AppendCRC();
	LOG_PRINTFF(0x00000001L,"BuildSetPollOnDemandMsg 1");
}

static void BuildActivateTransactionMsg(char timeout) //add txn amount and type
{		
	char currencyCode[5] = {0x30, 0,0,0,0};
	char fields[4] = {0x02, 0x01, 0x00, 0x22};
	char tlv_9f02[9] = {0x9F, 0x02, 0x06 ,0,0,0,0,0,0};
	char tlv_9a[5] = {0x9A, 0x03 ,0,0,0};
	char tlv_9f21[6] = {0x9F, 0x21, 0x03 ,0,0,0};
	char tlv_5f2a[5] = {0x5F, 0x2A, 0x02, 0,0};
	char tlv_9f1a[5] = {0x9F, 0x1A, 0x02, 0,0x36};
	char tlv_9c[3] = {0x9C, 0x01, 0};
	char hexDateTime[6] = {0};
	char DateTime[20];

	read_clock(DateTime);
	DateTime[14] = '\0';
	SVC_DSP_2_HEX(DateTime+2, hexDateTime, 6);	
	FormatAmt(p_ctls->sAmt, tlv_9f02+3);
	
	memcpy(tlv_9a+2, hexDateTime, 3);
	memcpy(tlv_9f21+3, hexDateTime+3, 3);
	//Dwarika
	memcpy(currencyCode+1, "036", 3);
	SVC_DSP_2_HEX(currencyCode, tlv_5f2a+3, 2);

	switch(0)
	{
	//case TxnType::purchase:		
	case 0:
		tlv_9c[2] = 0x00;
		break;
	//case TxnType::purchaseWithCashback:		
	case 1:
		tlv_9c[2] = 0x09;
		break;
	//case TxnType::refund:		
	case 2:
		tlv_9c[2] = 0x20;
		break;
	//case TxnType::cashAdvance:		
	case 3:
		tlv_9c[2] = 0x01;
		break;
	}

	ResetMsg();
	AddVivo2Header();	
	AddToMsg(fields, sizeof(fields));
	AddToMsg(&timeout, 1);
	AddToMsg(tlv_9f02, sizeof(tlv_9f02));
	AddToMsg(tlv_9a, sizeof(tlv_9a));
	AddToMsg(tlv_9f21, sizeof(tlv_9f21));
	AddToMsg(tlv_5f2a, sizeof(tlv_5f2a));
	AddToMsg(tlv_9f1a, sizeof(tlv_9f1a));
	AddToMsg(tlv_9c, sizeof(tlv_9c));
	AppendCRC();		
	LOG_PRINTFF(0x00000001L,"BuildActivateTransactionMsg 3");
}

static void BuildSetEMVTxnAmtMsg()
{	
	char fields[4] = {0x04, 0x00, 0x00, 0x12};	
	char tlv_9f02[9] = {0x9F, 0x02, 0x06 ,0,0,0,0,0,0};
	char tlv_9f03[9] = {0x9F, 0x03, 0x06, 0,0,0,0,0,0};							

	LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg");
	
	FormatAmt(p_ctls->sAmt, tlv_9f02+3);
	LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg 1");

	ResetMsg();
	AddVivo2Header();	
	AddToMsg(fields, sizeof(fields));	
	AddToMsg(tlv_9f02, sizeof(tlv_9f02));
	AddToMsg(tlv_9f03, sizeof(tlv_9f03));	
	AppendCRC();
	LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg 2");
}

static void BuildSetEMVTrmCapMsg()
{	
	int dataLen,dataRead;
	char CTLSTranaLmt[15], CVMLmt[15], TermCapb1[7],TermCapb2[7],TermCapb3[7], HTermCapb1[3],HTermCapb2[3],HTermCapb3[3], HGroupNo[1];
	char fields[4] = {0x04, 0x00, 0x00, 0x1E};	
	char tlv_9f33[6] = {0x9F, 0x33, 0x03 ,0,0,0};
	char tlv_ffe4[4] = {0xFF, 0xE4, 0x01 ,0};
	//char tlv_fffc[4] = {0xFF, 0xFC, 0x01, 0};							

	LOG_PRINTFF(0x00000001L,"BuildSetEMVTrmCapMsg");
		{
			char fields1[4] = {0x03, 0x07, 0x00, 0x00};
			int read = 0;
			int Fff1,Fff5,count=0;
			char FFe4[6];
			char string[1024];
				
			ResetMsg();
			AddVivo2Header();	
			AddToMsg(fields1, sizeof(fields1));	
			AppendCRC();
			SendRxMsg(0);
			LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg 1..1");
			dataLen = GetDataLen(rsp);
			dataRead = 0;
			read = 2;
			LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg dataLen:%d",dataLen);
			Fff1=Fff5 = 0;
			while(dataRead < dataLen)
			{
				TLV tlvStruct = {0};
				LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg 1..2"); 			
				
				getTlv(rsp+V2_DATA_OFS+dataRead, &tlvStruct);
	
				switch(tlvStruct.tag & 0xFFFF)
				{			
					case 0xFFE4:	
					{
						count++;
						LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg 0xFFE4");
						memset(FFe4,0x00,sizeof(FFe4));
						memset(string,0x00,sizeof(string));
						UtilHexToString((const char *)tlvStruct.val , tlvStruct.len , string);
						LOG_PRINTFF(0x00000001L,"strlen(string):%d, string:%s",strlen(string),string);
						memcpy(FFe4,string,strlen(string));
						LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg FFe4:%s",FFe4);
						break;
					}
					case 0xFFF1:	
					{
						LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg 0xFFF1");
						Fff1 = 1;
						memset(CTLSTranaLmt,0x00,sizeof(CTLSTranaLmt));
						memset(string,0x00,sizeof(string));
						UtilHexToString((const char *)tlvStruct.val , tlvStruct.len , string);
						LOG_PRINTFF(0x00000001L,"strlen(string):%d, string:%s",strlen(string),string);
						memcpy(CTLSTranaLmt,string,strlen(string));
						LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg CTLSTranaLmt:%s",CTLSTranaLmt);
						break;
					}
					case 0xFFF5:	
					{
						LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg 0xFFF5");
						Fff5 = 1;
						memset(CVMLmt,0x00,sizeof(CVMLmt));
						memset(string,0x00,sizeof(string));
						UtilHexToString((const char *)tlvStruct.val , tlvStruct.len , string);
						LOG_PRINTFF(0x00000001L,"strlen(string):%d, string:%s",strlen(string),string);
						memcpy(CVMLmt,string,strlen(string));
						LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg CVMLmt:%s",CVMLmt);						
						break;
					}
					case 0x9F33:	
					{
						LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg 0x9F33");
						
						memset(string,0x00,sizeof(string));
						UtilHexToString((const char *)tlvStruct.val , tlvStruct.len , string);
						LOG_PRINTFF(0x00000001L,"strlen(string):%d, string:%s",strlen(string),string);
						if(strcmp(FFe4,"00") == 0)
						{
							memset(TermCapb1,0x00,sizeof(TermCapb1));
							memcpy(TermCapb1,string,strlen(string));
							LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg TermCapb1:%s",TermCapb1);						
						}
						else if(strcmp(FFe4,"01") == 0)
						{
							memset(TermCapb2,0x00,sizeof(TermCapb2));
							memcpy(TermCapb2,string,strlen(string));
							LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg TermCapb2:%s",TermCapb2);						
						}
						else if(strcmp(FFe4,"02") == 0)
						{
							memset(TermCapb3,0x00,sizeof(TermCapb3));
							memcpy(TermCapb3,string,strlen(string));
							LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg TermCapb3:%s",TermCapb3);						
						}
						break;
					}

				}
				
				if (count > 3)
					break;
				read = TLVLen(rsp+V2_DATA_OFS+dataRead);
				LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg read:%d",read);
				if(read > 0) dataRead += read;
				else 
				{
					LOG_PRINTFF(0x00000001L,"BuildSetEMVTxnAmtMsg 1..3");
					//return read;
					break;
				}
				
			}	
		}
		
		
	{
		char event[64]="";
		char input[256]="";
		char srcline1[1024]="WIDELBL,THIS,PLEASE WAIT,4,C;";
		DisplayObject(srcline1,0,EVT_TIMEOUT,2000,event,input);				
	}
	
	if(atoi(p_ctls->sAmt) > atoi(CVMLmt))
	{
		BuildSetEMVGrpMsg();
	}
	else if (atoi(p_ctls->sAmt) <= atoi(CVMLmt))
	{
		SetCfgGroups();
	}
	return;
}

static void BuildSetEMVGrpMsg()
{	
	char buff[2] = {0};
	char tlv[1000] = {0};
	char tlvHex[500] = {0};
	int noBytes, ndx = 0;
	int hCfgFile = open("ctlsEmvCfg_CVMREQ.txt", O_RDONLY);
	LOG_PRINTFF(0x00000001L,"BuildSetEMVGrpMsg");
	
	if(hCfgFile < 0) 
	{
		return;	
	}
	
	while(buff[0] != 'G' && buff[0] != (char)EOF)
	{
		noBytes = read(hCfgFile, buff, 1);
		//LOG_PRINTFF(0x00000001L,"BuildSetEMVGrpMsg noBytes:%d, buff:%s",noBytes,buff);
		if(noBytes != 1)
		{
			close(hCfgFile);
			//LOG_PRINTFF(0x00000001L,"BuildSetEMVGrpMsg 2");
			return ; //no Group params			
		}
	}	
	if(buff[0] == (char)EOF) 
	{
		close(hCfgFile);
		//LOG_PRINTFF(0x00000001L,"BuildSetEMVGrpMsg 3");
		return ;		
	}
	noBytes = read(hCfgFile, buff, 1);	
	LOG_PRINTFF(0x00000001L,"BuildSetEMVGrpMsg noBytes:%d, buff:%s",noBytes,buff);
	if(noBytes != 1 || buff[0] != ';')
	{
		close(hCfgFile);
		//LOG_PRINTFF(0x00000001L,"BuildSetEMVGrpMsg 4");
		return ;		
	}

	for(;;)
	{
		do
		{
			noBytes = read(hCfgFile, buff, 1);
			LOG_PRINTFF(0x00000001L,"BuildSetEMVGrpMsg noBytes:%d, buff:%s",noBytes,buff);
			if(noBytes <= 0)
			{				
				close(hCfgFile);
			//	LOG_PRINTFF(0x00000001L,"BuildSetEMVGrpMsg 5");
				return ;
			}

			if(buff[0] == '\n')
			{
				int res;
				BuildSetCfgGroupMsg(NULL, 1);
				res = SendRxMsg(0);
				if(res != CTLS_SUCCESS) 
				{			
					close(hCfgFile);
				//	LOG_PRINTFF(0x00000001L,"BuildSetEMVGrpMsg 6");
					return ;
				}

				noBytes = read(hCfgFile, buff, 2);		
				LOG_PRINTFF(0x00000001L,"BuildSetEMVGrpMsg noBytes:%d, buff:%s",noBytes,buff);
				if(noBytes <= 0 || buff[0] != 'G') 
				{					
					close(hCfgFile);
				//	LOG_PRINTFF(0x00000001L,"SetCfgGroups 7");
					return ;
				}				
							
				continue;
			}
			else if(buff[0] == (char)EOF)
			{
				close(hCfgFile);
				LOG_PRINTFF(0x00000001L,"BuildSetEMVGrpMsg 8");
				return;
			}
			else if(isxdigit(buff[0])) 
			{
				LOG_PRINTFF(0x00000001L,"BuildSetEMVGrpMsg 9");
				tlv[ndx++] = buff[0];
			}
		}
		while(buff[0] != ';');
		
		LOG_PRINTFF(0x00000001L,"BuildSetEMVGrpMsg 10");
		
		SVC_DSP_2_HEX(tlv, tlvHex, strlen(tlv)/2);	
		LOG_PRINTFF(0x00000001L,"BuildSetEMVGrpMsg tlv:%s,tlvHex:%s",tlv,tlvHex);
		BuildSetCfgGroupMsg(tlvHex, 0);
		
		LOG_PRINTFF(0x00000001L,"BuildSetEMVGrpMsg 11");
		memset(tlv, 0, sizeof(tlv));
		memset(tlvHex, 0, sizeof(tlvHex));
		ndx = 0;
	}			

}

static int SendRawMsg()
{	
	
	char buff[2] = {0};
	char tlv[2048] = {0};
	char tlvHex[1024] = {0};
	char fld[1024] = {0};
	int noBytes, ndx = 0;
	int fndx = 0;
	int hCfgFile = open("ctlsEmvCfg.txt", O_RDONLY);
	int grpidx = 0;
	int found = 0;
	
	if(hCfgFile < 0) 
	{
		return;	
	}
	
	while(buff[0] != 'R' && buff[0] != (char)EOF)
	{
		noBytes = read(hCfgFile, buff, 1);
		if(noBytes != 1)
		{
			close(hCfgFile);
			return ; //no Group params			
		}
	}	
	if(buff[0] == (char)EOF) 
	{
		close(hCfgFile);
		return ;		
	}
	noBytes = read(hCfgFile, buff, 1);	
	if(noBytes != 1 || buff[0] != ';')
	{
		close(hCfgFile);
		return ;		
	}

	grpidx = 0;
	for(;;)
	{
			noBytes = read(hCfgFile, buff, 1);
			if(noBytes <= 0)
			{				
				close(hCfgFile);
				return ;
			}

			if(buff[0] == '\n')
			{
				int res;
				SVC_DSP_2_HEX(tlv, tlvHex, strlen(tlv)/2);	
				if(strlen(tlv)) {
					BuildRawMsg(tlvHex, strlen(tlv)/2);
					res = SendRxMsg(0);
				}
				if(res != CTLS_SUCCESS) 
				{			
					close(hCfgFile);
					return ;
				}

				noBytes = read(hCfgFile, buff, 2);		
				if(noBytes <= 0 || buff[0] != 'R') 
				{					
					close(hCfgFile);
					return ;
				}				

				memset(fld, 0, sizeof(fld));
				memset(tlv, 0, sizeof(tlv));
				memset(tlvHex, 0, sizeof(tlvHex));
				ndx = 0;
				fndx = 0;
				found = 0;
							
				continue;
			}
			else if(buff[0] == (char)EOF)
			{
				close(hCfgFile);
				return;
			}
			else if(buff[0] == ';')
			{
				char stmp[30];
				//
				if(strncmp(fld,"9f06",4) ==0) {
						strcpy(stmp,fld+6);
						grpidx = 0;
						while(AIDlist[grpidx].GroupNo!=0 && strcmp(AIDlist[grpidx].AID,stmp) ) grpidx ++;
						if(AIDlist[grpidx].GroupNo && strcmp(AIDlist[grpidx].AID,stmp)==0)
							found = 1;	
				} 
				if( found ) {
					char *tag = fld;
					char *value = fld+6;

					if(strncmp(tag,"1ff2",4) ==0) {
						strcpy(AIDlist[grpidx].TermPriority,value);
					} else if(strncmp(tag,"1ff3",4) ==0) {
						strcpy(AIDlist[grpidx].MaxTargetD,value);
					} else if(strncmp(tag,"1ff4",4) ==0) {
						strcpy(AIDlist[grpidx].TargetPerD,value);
					} else if(strncmp(tag,"1ff6",4) ==0) {
						strcpy(AIDlist[grpidx].ThresholdD,value);
					}
				}

				fndx = 0;
				memset(fld, 0, sizeof(fld));

			}
			else if(isxdigit(buff[0])) 
			{
				tlv[ndx++] = buff[0];
				fld[fndx++] = buff[0];
			}
	}			

}

static void BuildRawMsg(char* tlv,int tlvlen)
{	
	ResetMsg();
	AddVivo2Header();
	AddToMsg(tlv, tlvlen);
	tlvlen = tlvlen - 4;

	LOG_PRINTFF(0x00000001L,"build raw msg:%d",tlvlen);
	msg[12] = (tlvlen >> 8) & 0xFF;
	msg[13] = tlvlen & 0xFF;
	AppendCRC();
}

static void BuildSetADDReaderPrm()
{	
	int dataLen,dataRead;
	char fields[4] = {0xF7, 0x00, 0x00, 0x0D};	
	char tlv_1f13[10] = {0x1F, 0x13, 0x06 ,0x00,0xE8,0x01,0xE8,0x02,0xE8};
	char tlv_1fee[4] = {0x1F, 0xEE, 0x01 ,0x78};
							

	LOG_PRINTFF(0x00000001L,"BuildSetADDReaderPrm");
		//SVC_DSP_2_HEX(TermCapb1, HTermCapb1, 3);	
	
	ResetMsg();
	AddVivo2Header();	
	AddToMsg(fields, sizeof(fields));	
	AddToMsg(tlv_1f13, sizeof(tlv_1f13));
	AddToMsg(tlv_1fee, sizeof(tlv_1fee));
	
	AppendCRC();
	LOG_PRINTFF(0x00000001L,"BuildSetADDReaderPrm 3");
}

static void BuildCancelTransactionMsg()
{		
	char fields[4] = {0x05, 0x01, 0x00, 0x00};
	ResetMsg();
	AddVivo2Header();
	AddToMsg(fields, sizeof(fields));	
	AppendCRC();
}

static void BuildStoreLCDMsgMsg(char msgNdx, char *str, char *paramStr1, char *paramStr2, char *paramStr3)
{	
	char fields[4] = {0x01, 0x03, 0x00, 0x00};
	char data[512] = {0};
				
	if(msgNdx == 0xFD || msgNdx == 0xFE || msgNdx == 0xFF)
	{		
		data[0] = msgNdx;
		fields[3] = 1;
	}
	else
	{
		data[0] = msgNdx;
		data[1] = strlen(str);
		data[2] = strlen(paramStr1);
		data[3] = strlen(paramStr2);
		data[4] = strlen(paramStr3);
		sprintf(data+5, "%s%s%s%s", str, paramStr1, paramStr2, paramStr3);
		fields[3] = strlen(data+5)+5;
	}

	ResetMsg();
	AddVivo2Header();
	AddToMsg(fields, sizeof(fields));	
	AddToMsg(data, fields[3]);
	AppendCRC();	
}

static void BuildGetLCDMsgMsg()
{	
	char fields[5] = {0x01, 0x04, 0x00, 0x01,0xFF};
				
	ResetMsg();
	AddVivo2Header();
	AddToMsg(fields, sizeof(fields));	
	AppendCRC();	
}

static void BuildGetTLVsMsg(char *Aid, short sz)
{
	short dataLen = sz+3;
	char fields1[2] = {0x03, 0x04};
	char fields2[3] = {0};	
	fields2[0] = 0x9F; fields2[1] = 0x06; fields2[2] = sz;
	ResetMsg();
	AddVivo2Header();
	AddToMsg(fields1, sizeof(fields1));
	AddToMsg((char*)&dataLen, 1);
	AddToMsg((char*)(&dataLen)+1, 1);
	AddToMsg(fields2, sizeof(fields2));
	AddToMsg(Aid, sz);
	AppendCRC();	
}

static void BuildGetCfgGroupMsg(char *groupNo)
{
	char fields[8] = {0x03, 0x06, 0x00, 0x04, 0xFF, 0xE4, 0x01, 0x00};	
	fields[7] = *groupNo;
	ResetMsg();
	AddVivo2Header();
	AddToMsg(fields, sizeof(fields));
	AppendCRC();	
}

static int SendGeneralMsg(char cmd,char subcmd,char *data,short datalen)
{
	int res = 0;
	BuildGeneralMsg(cmd,subcmd,data,datalen);
	LOG_PRINTFF(0x00000001L,"SendGeneralMsg %c%c..",cmd,subcmd);
	res = SendRxMsg(2000);
	if(res != CTLS_SUCCESS) return res;
	return CTLS_SUCCESS;
}

static int BuildGeneralMsg(char cmd,char subcmd,char *data,short datalen)
{
	char fields[4] = {0x00, 0x00, 0x00, 0x00};
	fields[0] = cmd;
	fields[1] = subcmd;
	if(datalen) fields[3] = datalen; 
	ResetMsg();
	AddVivo2Header();
	AddToMsg(fields, sizeof(fields));
	AddToMsg(data, datalen);
	AppendCRC();
}

static void BuildGetAllAidsMsg(void)
{
	char fields[4] = {0x03, 0x05, 0x00, 0x00};
	ResetMsg();
	AddVivo2Header();
	AddToMsg(fields, sizeof(fields));
	AppendCRC();
}

static void BuildDeleteAidMsg(char *aid, short len)
{
	//char fields[7] = {0x04, 0x04, 0x00, 0x00, 0x9f, 0x06, 0x00};	
	char fields[11] = {0x04, 0x02, 0x00, 0x00, 0xFF,0xE4,0x01,0x00, 0x9f, 0x06, 0x00};	
	char fields2[4] = "\xFF\xE6\x01\x80";
	fields[3] = len+11;	
	fields[6] = len;
	ResetMsg();
	AddVivo2Header();
	AddToMsg(fields, sizeof(fields));	
	AddToMsg(aid, len);
	AddToMsg(fields2, 4);
	AppendCRC();	

}

static void BuildSetSourceMsg()
{ 
	char fields[6] = {0x01 , 0x05, 0x00, 0x02, 0x15, 0x05};	
	ResetMsg();
	AddVivo2Header();
	AddToMsg(fields, sizeof(fields));
	AppendCRC();
}

static void BuildSetDateMsgCF()
{
	char fields[2] = {0x25, 0x03};
	char dataLen = 0x04;	
	
	ResetMsg();
	AddVivoHeader();
	AddToMsg("C", 1);	
	AddToMsg(fields, sizeof(fields));
	AddToMsg("", 1);
	AddToMsg(&dataLen, 1);
	AppendCRC();		
}

static void BuildSetDateMsgDF()
{		
	char dateTime[15] = {0};	
	char hexDate[4] = {0};	
	read_clock(dateTime);	

	SVC_DSP_2_HEX(dateTime, hexDate, 4);	

	ResetMsg();
	AddVivoHeader();
	AddToMsg("D", 1);

	AddToMsg(hexDate, 1);
	AddToMsg(hexDate+1, 1);
	AddToMsg(hexDate+2, 1);
	AddToMsg(hexDate+3, 1);
	
	AppendCRC();			
}

static void BuildSetTimeMsgCF()
{
	//Dwarika..
	//char fields[2] = {0x25, 0x05};	
	
	char fields[2] = {0x25, 0x01};	
	char dataLen = 0x03;	
	
	//Dwarika..
	/*****/
		char dateTime[15] = {0};
		char hexTime[3] = {0};
		read_clock(dateTime);
		//LOG_PRINTFF(0x00000001L,"BuildSetTimeMsgCF() dateTime:%s:",dateTime);
		//LOG_PRINTFF(0x00000001L,"SetDateTime() 2");
		SVC_DSP_2_HEX(dateTime+8, hexTime, 3);
		LOG_PRINTFF(0x00000001L,"BuildSetTimeMsgCF() hexTime:%s:",hexTime);
	/*****/
		
	ResetMsg();
	AddVivoHeader();
	AddToMsg("C", 1);
	AddToMsg(fields, sizeof(fields));
	//Dwarika
	/*****/
	//AddToMsg("", 1);
	//AddToMsg(&dataLen, 1);
		AddToMsg(hexTime, 1);
		AddToMsg(hexTime+1, 1);
	
	/*****/
	AppendCRC();
}

static void BuildSetTimeMsgDF()
{	
	char dateTime[15] = {0};
	char hexTime[3] = {0};
	read_clock(dateTime);

	SVC_DSP_2_HEX(dateTime+8, hexTime, 3);		

	ResetMsg();
	AddVivoHeader();
	AddToMsg("D", 1);
	AddToMsg(hexTime, 1);
	AddToMsg(hexTime+1, 1);
	AddToMsg(hexTime+2, 1);
	
	AppendCRC();		
}

//Due to the statics this is not a re-entrant function.
static void BuildSetEmvMsg(char *tlv, char closeMsg)
{
	static char addHdr = 1;
	static int dataSz = 0;

	if(addHdr) 
	{
		char fields[4] = {0x04, 0x00, 0x00, 0x00};
		ResetMsg();
		AddVivo2Header();
		AddToMsg(fields, sizeof(fields));		
	}
	addHdr = closeMsg;
	
	if(tlv)
	{		
		AddToMsg(tlv, TLVLen(tlv));	
		dataSz += TLVLen(tlv);				
	}

	if(closeMsg)
	{		
		msg[12] = (dataSz >> 8) & 0xFF;
		msg[13] = dataSz & 0xFF;
		AppendCRC();
		dataSz = 0;				
	}
}

static void BuildSetCfgGroupMsg(char *tlv, char closeMsg)
{
	static char addHdr = 1;
	static int dataSz = 0;

	if(addHdr) 
	{
		char fields[4] = {0x04, 0x03, 0x00, 0x00};
		ResetMsg();
		AddVivo2Header();
		AddToMsg(fields, sizeof(fields));		
	}
	addHdr = closeMsg;
	
	if(tlv)
	{
		AddToMsg(tlv, TLVLen(tlv));
		dataSz += TLVLen(tlv);
	}

	if(closeMsg)
	{		
		msg[12] = (dataSz >> 8) & 0xFF;
		msg[13] = dataSz & 0xFF;
		AppendCRC();
		dataSz = 0;				
	}
}

static void BuildSetCfgAidMsg(char *tlv, char closeMsg)
{
	static char addHdr = 1;
	static int dataSz = 0;	

	if(addHdr) 
	{
		char fields[4] = {0x04, 0x02, 0x00, 0x00};
		ResetMsg();
		AddVivo2Header();
		AddToMsg(fields, sizeof(fields));		
	}
	addHdr = closeMsg;
	
	if(tlv)
	{		
		AddToMsg(tlv, TLVLen(tlv));		
		dataSz += TLVLen(tlv);		
	}

	if(closeMsg)
	{				
		msg[12] = (dataSz >> 8) & 0xFF;
		msg[13] = dataSz & 0xFF;
		AppendCRC();
		dataSz = 0;						
	}
}

static void BuildSetCAPubKeyMsgCF(char dataLen1, char dataLen2)
{
	char fields[4] = {0x24, 0x01, 0,0};	
	fields[2] = dataLen2;
	fields[3] = dataLen1;

	ResetMsg();
	AddVivoHeader();
	AddToMsg("C", 1);
	AddToMsg(fields, sizeof(fields));	
	AppendCRC();
}

static void BuildSetCAPubKeyMsgDF(char *data, char len)
{		
	ResetMsg();
	AddVivoHeader();
	AddToMsg("D", 1);	
	AddToMsg(data, len);
	AppendCRC();		
}

static void BuildDelCAPubKeysMsg()
{
	char fields[4] = {0x24, 0x03, 0,0};		
	ResetMsg();
	AddVivoHeader();
	AddToMsg("C", 1);
	AddToMsg(fields, sizeof(fields));	
	AppendCRC();
}

//////////////////////////////////////
#pragma endregion

#pragma region ReaderFuncs
/////////////////Contactless ops/////////////////

static int GetPayment(char waitForRsp, int timeout)
{	
	LOG_PRINTFF(0x00000001L,"GetPayment");
	return ActivateTransaction(waitForRsp, timeout);
	LOG_PRINTFF(0x00000001L,"GetPayment 1");
}

static int CancelTransaction(int reason)
{
	int res;
	LOG_PRINTFF(0x00000001L,"CancelTransaction");
	BuildCancelTransactionMsg();	

	res = SendRxMsg(0);	
	LOG_PRINTFF(0x00000001L,"CancelTransaction 1");
	return res;
}
static int SetPollOnDemandMode()
{	
	LOG_PRINTFF(0x00000001L,"SetPollOnDemandMode");
	BuildSetPollOnDemandMsg();
	return SendRxMsg(0);
}
static int ActivateTransaction(char waitForRsp, int timeout)
{	
	LOG_PRINTFF(0x00000001L,"ActivateTransaction");
	BuildActivateTransactionMsg(timeout);
	//LOG_PRINTFF(0x00000001L,"ActivateTransaction 1");
	if(waitForRsp) return SendRxMsg(timeout+500);		
	return SendMsg();		
}

static int SetEMVTxnAmt()
{
	BuildSetEMVTxnAmtMsg();
	return SendRxMsg(0);
}
static int SetEMVTermCap()
{
	//BuildSetEMVTrmCapMsg();
	LOG_PRINTFF(0x00000001L,"SetEMVTermCap");
	return 1;
}
static int SetADDReaderPrm()
{
	BuildSetADDReaderPrm();
	return SendRxMsg(0);
}
static int StoreLCDMsg(char msgNdx, char *str, char *paramStr1, char *paramStr2, char *paramStr3)
{
	BuildStoreLCDMsgMsg(msgNdx, str, paramStr1, paramStr2, paramStr3);
	return SendRxMsg(5000);
}
static int GetLCDMsg()
{
	BuildGetLCDMsgMsg();
	return SendRxMsg(5000);
}
static int GetTLVs(char *Aid, short sz)
{
	int res = 0;
	//LOG_PRINTFF(0x00000001L,"GetTLVs");
	BuildGetTLVsMsg(Aid, sz);

	res = SendRxMsg(2000);	

	if(res == CTLS_SUCCESS)
	{
		//LOG_PRINTFF(0x00000001L,"GetTLVs 1");
		return ExtractTLVs();
	}
	//LOG_PRINTFF(0x00000001L,"GetTLVs 2");
	return res;
}
static int GetCfgGroup(char *groupNo)
{
	int res = 0;
	BuildGetCfgGroupMsg(groupNo);

	res = SendRxMsg(0);

	if(res == CTLS_SUCCESS)
		return ExtractCfgGroup();

	return res;
}
static int GetCfgGroupForAid(char *Aid, short sz)
{
	int res = GetTLVs(Aid, sz);		

	if(res == CTLS_SUCCESS)
		return GetCfgGroup(TLVs.tagffe4_groupNo+3);
	
	return res;
}
static int SetSource()
{
	BuildSetSourceMsg();
	return SendRxMsg(0);
}
static int SetDateTime()
{
	int res;
	//LOG_PRINTFF(0x00000001L,"SetDateTime()");
	
	BuildSetDateMsgCF();
	res = SendRxMsg(0);
	if(res != CTLS_SUCCESS) return res;
	
	if(GetFrameType() == V1_ACK_FRAME) res = CTLS_SUCCESS;
	else if(GetFrameType() == V1_NACK_FRAME) res = HandleRTCNFrame();
	else return CTLS_FAILED;

	if(res != CTLS_SUCCESS) return res;	
	
	//LOG_PRINTFF(0x00000001L,"SetDateTime() 1");
	
	BuildSetDateMsgDF();
	res = SendRxMsg(0);
	if(res != CTLS_SUCCESS) return res;
	
	if(GetFrameType() == V1_ACK_FRAME) res = CTLS_SUCCESS;
	else if(GetFrameType() == V1_NACK_FRAME) res = HandleRTCNFrame();
	else return CTLS_FAILED;	

	if(res != CTLS_SUCCESS) return res;	
	
	//LOG_PRINTFF(0x00000001L,"SetDateTime() 2");
	
	BuildSetTimeMsgCF();
	res = SendRxMsg(0);
	if(res != CTLS_SUCCESS) return res;
	
	if(GetFrameType() == V1_ACK_FRAME) res = CTLS_SUCCESS;
	else if(GetFrameType() == V1_NACK_FRAME) res = HandleRTCNFrame();
	else res = CTLS_FAILED;	
	
	return res;
}

static int SetCAPubKey(char *keyFile)
{	
	char data1[244] = {0}, data2[244] = {0}, dataLen1, dataLen2;
	int bytes = dir_get_file_sz(keyFile);
	int fHndl, res;	
	unsigned char rid[10], idx[10], mod[1000], exp[10], chk[100],Modata[2048];
	unsigned int modlen, explen;
	unsigned char capkdata[1000];
	unsigned char reqdata1[300], reqdata2[300];
	int reqdata1len, reqdata2len;
	char temp[1024], temp2[1024], temp3[1024],tmpdata[2048];
	char *ptr;
	unsigned long ulmodlen;
	int i,j,RetVal;
	
	//LOG_PRINTFF(0x00000001L,"SetCAPubKey");
	if(bytes <= 0) return CTLS_FAILED;	
	
	//LOG_PRINTFF(0x00000001L,"SetCAPubKey 1");
	fHndl = open(keyFile, O_RDONLY);
	if(fHndl < 0) return CTLS_FAILED;	
	res = read(fHndl, temp2, bytes);	
	close(fHndl);
	if(res < 0) 
	{
		return CTLS_FAILED;
	}
	
	strcpy(temp,&keyFile[2]);
	//LOG_PRINTFF(0x00000001L,"SetCAPubKey temp;%s,strlen(temp);%d,keyFile;%s",temp,strlen(temp),keyFile);
	
	// extract all required data
	SVC_DSP_2_HEX(temp, (char *)rid, strlen(temp) - 8);
	SVC_DSP_2_HEX(&temp[strlen(temp) - 7], (char *)idx, 2);
	
	strncpy(temp3, temp2, 3);
	temp3[3] = 0;
	modlen = atoi(temp3);
	SVC_DSP_2_HEX(&temp2[3], (char *)mod, modlen * 2);
	strncpy(temp3, &temp2[3 + modlen * 2], 2);
	temp3[2] = 0;
	explen = atoi(temp3);
	SVC_DSP_2_HEX(&temp2[5 + modlen * 2], (char *)exp, explen * 2);

	memset(Modata,0x00,sizeof(Modata));
	memcpy(Modata, rid, 5);
	Modata[5] = idx[0];
	memcpy(&Modata[6], mod, modlen);
	memcpy(&Modata[6 + modlen], exp, explen);
	
	
	ulmodlen = (unsigned long)modlen + explen + 6;
//	LOG_PRINTFF(0x00000001L,"SetCAPubKey modlen;%d, explen:%d,ulmodlen:%ul,bytes:%d",modlen,explen,ulmodlen,bytes);
	memset(chk,0x00,sizeof(chk));
	RetVal = 0;
	RetVal = SHA1(NULL,Modata,ulmodlen,chk);
//	LOG_PRINTFF(0x00000001L,"SetCAPubKey SHA1 RetVal:%d",RetVal);
	
	memset(tmpdata,0x00,sizeof(tmpdata));
	ptr=tmpdata;
	for(i=0;i<bytes-32;i++)
		ptr+=sprintf(ptr,"%c ",chk[i]);
//	LOG_PRINTFF(0x00000001L,"SetCAPubKey chk:%s",tmpdata);
	memset(tmpdata,0x00,sizeof(tmpdata));
	ptr=tmpdata;
	for(i=0;i<bytes-32;i++)
		ptr+=sprintf(ptr,"%02x ",chk[i]);
//	LOG_PRINTFF(0x00000001L,"SetCAPubKey chk1:%s",tmpdata);
	memset(tmpdata,0x00,sizeof(tmpdata));
	ptr=tmpdata;
	for(i=0;i<bytes-32;i++)
		ptr+=sprintf(ptr,"%d ",chk[i]);
	LOG_PRINTFF(0x00000001L,"SetCAPubKey chk2:%s",tmpdata);
	
	// reassemble the data
	memset(capkdata, 0x00, sizeof(capkdata));
	memcpy(capkdata, rid, 5);
	capkdata[5] = idx[0];
	capkdata[6] = 0x01;
	capkdata[7] = 0x01;
	memcpy(&capkdata[8], chk, 20);
	memcpy(&capkdata[28 + 4 - explen], exp, explen);
	capkdata[33] = modlen;
	memcpy(&capkdata[34], mod, modlen);
	
	bytes = 34+modlen;
	dataLen1 = (bytes <= 244?bytes:244);
	dataLen2 = (bytes <= 244?0:bytes-244);		

	BuildSetCAPubKeyMsgCF(dataLen1, dataLen2);
	res = SendRxMsg(0);	
//	LOG_PRINTFF(0x00000001L,"SetCAPubKey 2");
	if(res != CTLS_SUCCESS) 
	{
		return res;
	}
	
//	LOG_PRINTFF(0x00000001L,"SetCAPubKey 3");
	if(GetFrameType() == V1_ACK_FRAME) res = CTLS_SUCCESS;
	else if(GetFrameType() == V1_NACK_FRAME) res = HandleKeyMgtNFrame();
	else 
	{
		return CTLS_FAILED;
	}
	
//	LOG_PRINTFF(0x00000001L,"SetCAPubKey 4");

	if(res != CTLS_SUCCESS) 
	{
		return res;		
	}
//	LOG_PRINTFF(0x00000001L,"SetCAPubKey 5");
	BuildSetCAPubKeyMsgDF(capkdata, dataLen1);
	res = SendRxMsg(0);	
//	LOG_PRINTFF(0x00000001L,"SetCAPubKey 6");
	if(res != CTLS_SUCCESS)
	{
		return res;
	}
//	LOG_PRINTFF(0x00000001L,"SetCAPubKey 7");
	if(GetFrameType() == V1_ACK_FRAME) res = CTLS_SUCCESS;
	else if(GetFrameType() == V1_NACK_FRAME) res = HandleKeyMgtNFrame();
	else 
	{
		return CTLS_FAILED;
	}
//	LOG_PRINTFF(0x00000001L,"SetCAPubKey 8");
	if(res != CTLS_SUCCESS) 
	{
		return res;		
	}
//	LOG_PRINTFF(0x00000001L,"SetCAPubKey 9");
	if(!dataLen2) 
	{
		return CTLS_SUCCESS;	
	}

//	LOG_PRINTFF(0x00000001L,"SetCAPubKey 10");
	BuildSetCAPubKeyMsgDF(&capkdata[dataLen1], dataLen2);
	res = SendRxMsg(0);	

	if(res != CTLS_SUCCESS) 
	{
		return res;
	}
//	LOG_PRINTFF(0x00000001L,"SetCAPubKey 11");
	if(GetFrameType() == V1_ACK_FRAME) res = CTLS_SUCCESS;
	else if(GetFrameType() == V1_NACK_FRAME) res = HandleKeyMgtNFrame();
	else 
	{
		return CTLS_FAILED;
	}
//	LOG_PRINTFF(0x00000001L,"SetCAPubKey 12");	
	return res;
}  

static int SetCAPubKeys()
{	
	char fName[100] = {0};
	
	int res = DeleteCAPubKeys();
	if(res <= 0) return res;	
	//LOG_PRINTFF(0x00000001L,"SetCAPubKeys ");
	strcpy(fName, "I:");
	if(dir_get_first(fName) < 0) return CTLS_FAILED;
	//LOG_PRINTFF(0x00000001L,"SetCAPubKeys 1"); 
	while(dir_get_next(fName) >= 0)
	{	
	//	LOG_PRINTFF(0x00000001L,"SetCAPubKeys fName:%s",fName);
		if(strstr(fName, ".CEMV") || strstr(fName, ".cemv"))	
			if(SetCAPubKey(fName) != CTLS_SUCCESS) 				
			{
		//		LOG_PRINTFF(0x00000001L,"SetCAPubKeys 2");
				//return CTLS_FAILED;		
			}
	}
	
//	LOG_PRINTFF(0x00000001L,"SetCAPubKeys 3");
	return CTLS_SUCCESS;	
}
static int DeleteCAPubKeys(void)
{
	int res;
	BuildDelCAPubKeysMsg();
	res = SendRxMsg(2000);
	LOG_PRINTFF(0x00000001L,"DeleteCAPubKeys");
	if(res != CTLS_SUCCESS) return res;

	if(GetFrameType() == V1_ACK_FRAME) res = CTLS_SUCCESS;
	else if(GetFrameType() == V1_NACK_FRAME) res = HandleKeyMgtNFrame();
	else return CTLS_FAILED;

	return res;	
}
static int SetTxnLimit(char *amt)
{
	char txnLimTlv[9] = {0xFF, 0xF1, 0x06, 0,0,0,0,0,0};	
	FormatAmt(amt, txnLimTlv+3);	
	BuildSetEmvMsg(txnLimTlv, 1);

	return SendRxMsg(0);
}
static int SetCfgGroups()
{	
	char buff[2] = {0};
	char tlv[1000] = {0};
	char tlvHex[500] = {0};
	int noBytes, ndx = 0;
	int hCfgFile = open("ctlsEmvCfg.txt", O_RDONLY);
	int idx = -1;
	char stmp[30];
	char stmphex[30];
	static int firsttime = 1;

	LOG_PRINTFF(0x00000001L,"SetCfgGroups");
	if(hCfgFile < 0) 
	{
		//LOG_PRINTFF(0x00000001L,"SetCfgGroups 1");
		return CTLS_FAILED;	
	}
	
	
	while(buff[0] != 'G' && buff[0] != (char)EOF)
	{
		noBytes = read(hCfgFile, buff, 1);
	//	LOG_PRINTFF(0x00000001L,"SetCfgGroups noBytes:%d, buff:%s",noBytes,buff);
		if(noBytes != 1)
		{
			close(hCfgFile);
			LOG_PRINTFF(0x00000001L,"SetCfgGroups 2");
			return CTLS_SUCCESS; //no Group params			
		}
	}	
	if(buff[0] == (char)EOF) 
	{
		close(hCfgFile);
		//LOG_PRINTFF(0x00000001L,"SetCfgGroups 3");
		return CTLS_SUCCESS;		
	}
	noBytes = read(hCfgFile, buff, 1);	
	LOG_PRINTFF(0x00000001L,"SetCfgGroups noBytes:%d, buff:%s",noBytes,buff);
	if(noBytes != 1 || buff[0] != ';')
	{
		close(hCfgFile);
		//LOG_PRINTFF(0x00000001L,"SetCfgGroups 4");
		return CTLS_FAILED;		
	}
	
	if(firsttime) memset(&AIDlist,0,sizeof(AIDlist));

	for(;;)
	{
		do
		{
			noBytes = read(hCfgFile, buff, 1);
			//LOG_PRINTFF(0x00000001L,"SetCfgGroups noBytes:%d, buff:%s",noBytes,buff);
			if(noBytes <= 0)
			{				
				close(hCfgFile);
			//	LOG_PRINTFF(0x00000001L,"SetCfgGroups 5");
				firsttime = 0;
				return CTLS_FAILED;
			}

			if(buff[0] == '\n')
			{
				int res;
				BuildSetCfgGroupMsg(NULL, 1);
				res = SendRxMsg(0);
				if(res != CTLS_SUCCESS) 
				{			
					close(hCfgFile);
					firsttime = 0;
				//	LOG_PRINTFF(0x00000001L,"SetCfgGroups 6");
					return res;
				}

				noBytes = read(hCfgFile, buff, 2);		
				//LOG_PRINTFF(0x00000001L,"SetCfgGroups noBytes:%d, buff:%s",noBytes,buff);
				if(noBytes <= 0 || buff[0] != 'G') 
				{					
					firsttime = 0;
					close(hCfgFile);
				//	LOG_PRINTFF(0x00000001L,"SetCfgGroups 7");
					return CTLS_SUCCESS;
				}				
							
				continue;
			}
			else if(buff[0] == (char)EOF)
			{
				firsttime = 0;
				close(hCfgFile);
			//	LOG_PRINTFF(0x00000001L,"SetCfgGroups 8");
				return CTLS_SUCCESS;
			}
			else if(isxdigit(buff[0])) 
			{
			//	LOG_PRINTFF(0x00000001L,"SetCfgGroups 9");
				tlv[ndx++] = buff[0];
			}
		}
		while(buff[0] != ';');
		
	//	LOG_PRINTFF(0x00000001L,"SetCfgGroups 10");
		if (firsttime) {
			char *value = tlv + 6;
			if(strncmp(tlv,"ffe4",4) ==0) {
				idx ++;
				AIDlist[idx].GroupNo = atoi(value);
			} else if(strncmp(tlv,"fff1",4) ==0) {
				AIDlist[idx].TranLimitExists = atoi(value);
			} else if(strncmp(tlv,"fff5",4) ==0) {
				AIDlist[idx].CVMReqLimitExists = atoi(value);
			} else if(strncmp(tlv,"9f1b",4) ==0) {
				SVC_DSP_2_HEX(value,AIDlist[idx].FloorLimit,4);
			} else if(strncmp(tlv,"fffd",4) ==0) {
				SVC_DSP_2_HEX(value,AIDlist[idx].TACOnline,5);
			} else if(strncmp(tlv,"fffe",4) ==0) {
				SVC_DSP_2_HEX(value,AIDlist[idx].TACDefault,5);
			} else if(strncmp(tlv,"ffff",4) ==0) {
				SVC_DSP_2_HEX(value,AIDlist[idx].TACDenial,5);

			} else if(strncmp(tlv,"9f33",4) ==0) {
				SVC_DSP_2_HEX(value,AIDlist[idx].TermCap,3);
			} else if(strncmp(tlv,"df28",4) ==0) {
				SVC_DSP_2_HEX(value,AIDlist[idx].TermCapNoCVMReq,3);
			} else if(strncmp(tlv,"df29",4) ==0) {
				SVC_DSP_2_HEX(value,AIDlist[idx].TermCapCVMReq,3);
			} else if(strncmp(tlv,"9f40",4) ==0) {
				SVC_DSP_2_HEX(value,AIDlist[idx].AddTermCap,5);
			} else if(strncmp(tlv,"9f09",4) ==0) {
				strcpy(AIDlist[idx].AppVer, value );
			}



		}
		
		SVC_DSP_2_HEX(tlv, tlvHex, strlen(tlv)/2);	
	//	LOG_PRINTFF(0x00000001L,"SetCfgGroups tlv:%s,tlvHex:%s",tlv,tlvHex);
		BuildSetCfgGroupMsg(tlvHex, 0);
		
	//	LOG_PRINTFF(0x00000001L,"SetCfgGroups 11");
		memset(tlv, 0, sizeof(tlv));
		memset(tlvHex, 0, sizeof(tlvHex));
		ndx = 0;
	}			
}
static int SetCfgAids()
{
	char buff[2] = {0};
	char tlv[1000] = {0};
	char tlvHex[500] = {0};
	int noBytes, ndx = 0;
	int hCfgFile = open("ctlsEmvCfg.txt", O_RDONLY);
	char stmp[30];
	int grpidx=0;
	int grp= 0;
	int found = 0;

	if(hCfgFile < 0) 
	{
		return CTLS_FAILED;
	}
	while(buff[0] != 'A' && buff[0] != (char)EOF)
	{
		noBytes = read(hCfgFile, buff, 1);
		if(noBytes != 1) 
		{
			close(hCfgFile);
			return CTLS_SUCCESS; //no AID params		
		}
	}
	if(buff[0] == (char)EOF) 
	{
		close(hCfgFile);
		return CTLS_SUCCESS;	
	}
	noBytes = read(hCfgFile, buff, 1);	
	if(noBytes != 1 || buff[0] != ';') 
	{
		close(hCfgFile);
		return CTLS_FAILED;	
	}
	
	found = 0;
	grpidx = 0;
	for(;;)
	{
		do
		{			
			noBytes = read(hCfgFile, buff, 1);
			if(noBytes <= 0)
			{
				close(hCfgFile);
				return CTLS_FAILED;
			}

			if(buff[0] == '\n')
			{
				int res;				
				BuildSetCfgAidMsg(NULL, 1);
				res = SendRxMsg(0);
				if(res != CTLS_SUCCESS) 
				{					
					close(hCfgFile);
				//	LOG_PRINTFF(0x00000001L,"SetCfgAids 7");
					return res;
				}

				noBytes = read(hCfgFile, buff, 2);
				//LOG_PRINTFF(0x00000001L,"SetCfgAids noBytes:%d, buff:%s",noBytes,buff);
				if(noBytes <= 0 || buff[0] != 'A')
				{					
					close(hCfgFile);
				//	LOG_PRINTFF(0x00000001L,"SetCfgAids 8");
					return CTLS_SUCCESS;
				}
				found = 0;
				grpidx = 0;
								
				continue;
			}	
			else if(buff[0] == (char)EOF) 
			{				
				close(hCfgFile);
			//	LOG_PRINTFF(0x00000001L,"SetCfgAids 9");
				return CTLS_SUCCESS;
			}
			else if(isxdigit(buff[0])) 
			{
			//	LOG_PRINTFF(0x00000001L,"SetCfgAids 10");
				tlv[ndx++] = buff[0];			
			}
		}
		while(buff[0] != ';');		

		if(strncmp(tlv,"ffe4",4) ==0) {
				int i=0;
				sprintf(stmp,"%2.2s",tlv+6);
				grp = atoi(stmp);
				while(AIDlist[grpidx].GroupNo!=0 && AIDlist[grpidx].GroupNo!= grp ) grpidx ++;
				if(AIDlist[grpidx].GroupNo==grp)
					found = 1;	
		} 
		if( found ) {
			if(strncmp(tlv,"9f06",4) ==0) {
				sprintf(stmp,"%14.14s",tlv+6);
				if(strlen(AIDlist[grpidx].AID) ) {
					int oldidx = grpidx;
					while(AIDlist[grpidx].GroupNo) grpidx++;
					AIDlist[grpidx] = AIDlist[oldidx];
				
				}
				LOG_PRINTFF(0x00000001L,"AIDLIST [%d],AID %s",grpidx,stmp);
				strcpy(AIDlist[grpidx].AID,stmp);
			}
		}
		
	//	LOG_PRINTFF(0x00000001L,"SetCfgAids 11");
		SVC_DSP_2_HEX(tlv, tlvHex, strlen(tlv)/2);
	//	LOG_PRINTFF(0x00000001L,"SetCfgAids tlv:%s",tlv);
		BuildSetCfgAidMsg(tlvHex, 0);
	//	LOG_PRINTFF(0x00000001L,"SetCfgAids 12");
		memset(tlv, 0, sizeof(tlv));
		memset(tlvHex, 0, sizeof(tlvHex));
		ndx = 0;
	}			
}

static int GetAllAids()
{
	int res = 0, dataLen, dataRead = 0;

	BuildGetAllAidsMsg();
	LOG_PRINTFF(0x00000001L,"GetAll AIDS..");
	res = SendRxMsg(2000);
	LOG_PRINTFF(0x00000001L,"GetAll AIDS..done");
	if(res != CTLS_SUCCESS) return res;

	return CTLS_SUCCESS;
}

static int DeleteAids()
{
	int res = 0, dataLen, dataRead = 0;
	char getAidsRsp[CTLS_BUFF_SZ] = {0};
	TLV tlv = {0};
	LOG_PRINTFF(0x00000001L,"DeleteAids");
	BuildGetAllAidsMsg();
	res = SendRxMsg(2000);
	if(res != CTLS_SUCCESS) return res;
	LOG_PRINTFF(0x00000001L,"DeleteAids 1");
	memcpy(getAidsRsp, rsp, rspLength);	

	//get datalen
	dataLen = GetDataLen(getAidsRsp);	

	//loop while data left
	while(dataLen-dataRead)
	{			
		//get tlv 9f06
		getTlv(getAidsRsp+V2_DATA_OFS+dataRead, &tlv);
		if(tlv.tag == 0xffff9f06)
		{			
			//delete aid of that value
			BuildDeleteAidMsg(tlv.val, tlv.len);
			res = SendRxMsg(5000);
			if(res != CTLS_SUCCESS) return res;			
		}		
		dataRead += TLVLen(getAidsRsp+V2_DATA_OFS+dataRead);
	}
	
	LOG_PRINTFF(0x00000001L,"DeleteAids 2");
	return CTLS_SUCCESS;
}

static int SetEmvParams()
{
	char buff[2] = {0};
	char tlv[1000] = {0};
	char tlvHex[500] = {0};
	int noBytes, ndx = 0;
	int hCfgFile = open("ctlsEmvCfg.txt", O_RDONLY);
	LOG_PRINTFF(0x00000001L,"SetEmvParams");
	if(hCfgFile < 0) 
	{
		LOG_PRINTFF(0x00000001L,"SetEmvParams 1");
		return CTLS_FAILED;	
	}

	while(buff[0] != 'E' && buff[0] != (char)EOF)
	{
		noBytes = read(hCfgFile, buff, 1);
		//LOG_PRINTFF(0x00000001L,"SetEmvParams noBytes:%d, buff:%s",noBytes,buff);
		if(noBytes != 1) 
		{
			close(hCfgFile);			
			LOG_PRINTFF(0x00000001L,"SetEmvParams 2");
			return CTLS_SUCCESS; //no EMV params
		}
	}
	if(buff[0] == (char)EOF)
	{
		close(hCfgFile);
		LOG_PRINTFF(0x00000001L,"SetEmvParams 3");
		return CTLS_SUCCESS;	
	}
	noBytes = read(hCfgFile, buff, 1);		
//	LOG_PRINTFF(0x00000001L,"SetEmvParams noBytes:%d, buff:%s",noBytes,buff);
	if(noBytes != 1 || buff[0] != ';')
	{
		close(hCfgFile);
		LOG_PRINTFF(0x00000001L,"SetEmvParams 4");
		return CTLS_FAILED;	
	}
	
	for(;;)
	{
		do
		{
			noBytes = read(hCfgFile, buff, 1);
		//	LOG_PRINTFF(0x00000001L,"SetEmvParams noBytes:%d, buff:%s",noBytes,buff);
			if(noBytes <= 0)
			{
				close(hCfgFile);
				LOG_PRINTFF(0x00000001L,"SetEmvParams 5");
				return CTLS_FAILED;
			}

			if(buff[0] == '\n')
			{
				int res;
				BuildSetEmvMsg(NULL, 1);				
				res = SendRxMsg(0);
				if(res != CTLS_SUCCESS) 
				{
					close(hCfgFile);
					LOG_PRINTFF(0x00000001L,"SetEmvParams 6");
					return res;
				}

				noBytes = read(hCfgFile, buff, 2);
			//	LOG_PRINTFF(0x00000001L,"SetEmvParams noBytes:%d, buff:%s",noBytes,buff);
				if(noBytes <= 0 || buff[0] != 'E')
				{					
					close(hCfgFile);
				//	LOG_PRINTFF(0x00000001L,"SetEmvParams 7");
					return CTLS_SUCCESS;
				}
								
				continue;
			}	
			else if(buff[0] == (char)EOF) 
			{
				close(hCfgFile);
			//	LOG_PRINTFF(0x00000001L,"SetEmvParams 8");
				return CTLS_SUCCESS;
			}
			else if(isxdigit(buff[0])) 
			{
			//	LOG_PRINTFF(0x00000001L,"SetEmvParams 9");
				tlv[ndx++] = buff[0];
			}
		}
		while(buff[0] != ';');
				
	//	LOG_PRINTFF(0x00000001L,"SetEmvParams 10");
		
		SVC_DSP_2_HEX(tlv, tlvHex, strlen(tlv)/2);		
	//	LOG_PRINTFF(0x00000001L,"SetEmvParams tlv:%s,tlvHex:%s",tlv,tlvHex);
		BuildSetEmvMsg(tlvHex, 0);
		
	//	LOG_PRINTFF(0x00000001L,"SetEmvParams 11");
		
		memset(tlv, 0, sizeof(tlv));
		memset(tlvHex, 0, sizeof(tlvHex));
		ndx = 0;
	}			
}
/////////////////////////////////////////////
#pragma endregion

#pragma region PublicIF

/////////////PUBLIC CONTACTLESS FUNCS//////////////

typedef struct AcquireCardParams_
{
	char waitForRsp;
	int timeoutMs;
} AcquireCardParams;

int AcquireCard(char waitForRsp, int timeoutMs, _ctlsStru * ptr_ctls )
{			
	int res = -1;
	void *params = 0;		
	p_ctls = ptr_ctls;
	LOG_PRINTFF(0x00000001L,"AcquireCard");
		
	params = calloc(1, sizeof(AcquireCardParams));
	if(!params)
	{		
		return res;
	}

	if(p_ctls->nosaf) {
		char lcdMsg[100];
		strcpy(lcdMsg, "%F3%Pcc12Declined");
		StoreLCDMsg(0x0d, lcdMsg, "", "", "");
	}
	
	((AcquireCardParams*)params)->waitForRsp = waitForRsp;
	((AcquireCardParams*)params)->timeoutMs = timeoutMs;
	res = CbAcquireCard(params);
	LOG_PRINTFF(0x00000001L,"AcquireCard res:%d",res);
	free(params);
	return res;
}

//Not to be called without first calling AcquireCard
int ProcessCard()
{
	int res = -1;	
	res = CbProcessCard( (void*)0);	
	return res;
}

void CancelAcquireCard(int reason)
{	
	int res = -1;
	void *params = 0;

	if(p_ctls->nosaf) {
		char lcdMsg[] = "%F2%Pcc00Approved\n%Pcc15Thank you";
		StoreLCDMsg(0x0d, lcdMsg, "", "", "");
	}

	LOG_PRINTFF(0x00000001L,"CancelAcquireCard");
	params = calloc(1, sizeof(int));
	if(!params)
	{
		return;
	}
	*(int*)params = reason;
	LOG_PRINTFF(0x00000001L,"CancelAcquireCard 1");
	res = CbCancelAcquireCard(params);
	free(params);
}

#pragma endregion

#pragma region Comms Thread Bits

///////Execute once callbacks///////
static int CbAcquireCard(void *pParams)
{			
	memset(&TLVs, 0, sizeof(TLVs));
	SetEMVTxnAmt();	
	SetEMVTermCap();
	return GetPayment(((AcquireCardParams*)pParams)->waitForRsp, 
									((AcquireCardParams*)pParams)->timeoutMs);
}
static int CbProcessCard(void *pParams)
{
	int ret = -1;
	int txnRsp , statusCode;
	
	statusCode = GetRspStatus();
	if(strlen(p_ctls->TxnStatus)==0) sprintf(p_ctls->TxnStatus,"%2d",statusCode);
	LOG_PRINTFF(0x00000001L,"CbProcessCard %s",p_ctls->TxnStatus);
	switch(statusCode)
	{	
	case CTLS_NO_REPLY:
		//LOG_PRINTFF(0x00000001L,"NO REPLY");
		return CTLS_NO_CARD;

	case V2_FAILED_NAK:			
		//LOG_PRINTFF(0x00000001L,"CTLS FAILED NAK");
		ret = HandleErrRsp();	
		LOG_PRINTFF(0x00000001L,"CTLS FAILED NAK 1");
		return ret;
		
	case V2_REQ_OL_AUTH:		
		LOG_PRINTFF(0x00000001L,"REQ ONL AUTH");
		{
			int extRes;			
			
			strcpy((char*)ICC_Details.CrypInfoData, ARQC);
			extRes = ExtractCardDetails();			

			LOG_PRINTFF(0x00000001L,"extract card details res is %d", extRes);
			
			if(extRes < 0)
			{				
				return CTLS_BAD_CARD_READ;
			}
			return extRes | CTLS_REQ_OL;
		}

	case V2_OK:		
		LOG_PRINTFF(0x00000001L,"OFFLINE AUTH");
		{
			int extRes = ExtractCardDetails();

			LOG_PRINTFF(0x00000001L,"extract card details res is %d", extRes);  
			
			if(extRes < 0)
			{	
				LOG_PRINTFF(0x00000001L,"V2_OK 1", );
				return CTLS_BAD_CARD_READ;
			}			
			LOG_PRINTFF(0x00000001L,"V2_OK 2", );
			return extRes | CTLS_AUTHD;
		}

	case V2_INCORRECT_TAG_HDR:
	case V2_UNK_CMD:
	case V2_UNK_SUB_CMD:
	case V2_CRC_ERR:
	case V2_INCORRECT_PARAM:
	case V2_PARAM_NOT_SUPPORTED:
	case V2_MAL_FORMATTED_DATA:
	case V2_TXN_TIMED_OUT:
	case V2_CMD_NOT_ALLOWED:
	case V2_SUB_CMD_NOT_ALLOWED:
	case V2_BUFF_OVERFLOW:
	case V2_USER_IF_EVT:
	default:
		LOG_PRINTFF(0x00000001L,"UNEXPECTED RSP STATUS %d !!", statusCode);
		break;
	}
			
	return CTLS_UNKNOWN;
}
static int CbCancelAcquireCard(void *pParams)
{	
	LOG_PRINTFF(0x00000001L,"CbCancelAcquireCard");
	return CancelTransaction(*(int*)pParams);
}
////////////////////////

static void InitRdr(char comPortNumber)
{
	char lcdMsg[256] = {0};			
	static int ctlsInitRes = 0;
	static int  hCtlsRdr = -1;

	//	LOG_PRINTFF(0x00000001L,"InitRdr");
	if(hCtlsRdr < 0) 
	{
		hCtlsRdr = InitComPort(comPortNumber);			
	}
	if(hCtlsRdr >= 0) 
	{	
		ctlsInitRes = SetPollOnDemandMode();
	}
	
	if(ctlsInitRes > 0) 
	{
		LOG_PRINTFF(0x00000001L,"SetEmvParams");
		ctlsInitRes = SetEmvParams(); // 04-02
		LOG_PRINTFF(0x00000001L,"SetEmvParams ret = %d",ctlsInitRes);
	}
	if(ctlsInitRes > 0) 
	{
		LOG_PRINTFF(0x00000001L,"DeleteAids");
		//DeleteAids(); // 03-05 04-04
		SendGeneralMsg(0x04,0x02,"\xFF\xE4\x01\x00\x9f\x06\x07\xa0\x00\x00\x00\x04\x10\x10\xff\xe6\x01\x80",18);
		SendGeneralMsg(0x04,0x02,"\xff\xe4\x01\x00\x9f\x06\x07\xa0\x00\x00\x00\x03\x10\x10\xff\xe6\x01\x80",18);
	}
	if(ctlsInitRes > 0) 
	{
		LOG_PRINTFF(0x00000001L,"SetCfgGroups");
		ctlsInitRes = SetCfgGroups();//04-03
		LOG_PRINTFF(0x00000001L,"SetCfgGroups ret = %d",ctlsInitRes);
	}
	
	if(ctlsInitRes > 0) 
	{
		LOG_PRINTFF(0x00000001L,"SetCfgAids");
		ctlsInitRes = SetCfgAids();//04-02
	}

	SendRawMsg();
	
	SetADDReaderPrm();//F7-00
	
	if(ctlsInitRes > 0) 
	{
		ctlsInitRes = StoreLCDMsg(0xFF, "", "", "", "");
	}	
	if(ctlsInitRes > 0) 
	{
		strcpy(lcdMsg, "%F3%Pcc12PLEASE\n%Pcc37TRY AGAIN");
		ctlsInitRes = StoreLCDMsg(0x09, lcdMsg, "", "", "");
	}
	if(ctlsInitRes > 0) 
	{
		strcpy(lcdMsg, "%F3%Pcc12PRESENT 1 CARD\n%Pcc37ONLY");
		ctlsInitRes = StoreLCDMsg(0x0A, lcdMsg, "", "", "");
	}
	if(ctlsInitRes > 0) 
	{
		strcpy(lcdMsg, "%F3%Pcc12INSERT Or SWIPE\n%Pcc37CARD");
		ctlsInitRes = StoreLCDMsg(0x08, lcdMsg, "", "", "");
	}
	if(ctlsInitRes > 0) 
	{
		strcpy(lcdMsg, "%F3%Pcc12TRANSACTION CANCELLED..");
		ctlsInitRes = StoreLCDMsg(0x02, lcdMsg, "", "", "");
	}
	if(ctlsInitRes > 0) 
	{
		strcpy(lcdMsg, "%F3%Pcc12PROCESSING..");
		ctlsInitRes = StoreLCDMsg(0x03, lcdMsg, "", "", "");
	}
	if(ctlsInitRes > 0) 
	{
		strcpy(lcdMsg, "%F3%Pcc37PLEASE WAIT..");
		ctlsInitRes = StoreLCDMsg(0x04, lcdMsg, "", "", "");
	}
	if(ctlsInitRes > 0) 
	{
		strcpy(lcdMsg, "%F3%Pcc12TRANSACTION FAIL");
		ctlsInitRes = StoreLCDMsg(0x05, lcdMsg, "", "", "");
		//ctlsInitRes = StoreLCDMsg(0x05, "", "", "", "");
	}	
	if(ctlsInitRes > 0) 
	{
		memset(lcdMsg,0,sizeof(lcdMsg));
		strcpy(lcdMsg, "%F3%Pcc00TOTAL:%S1 %S3\n%Pcc30SWIPE,INSERT OR TAP");
		ctlsInitRes = StoreLCDMsg(0x06, lcdMsg, "", "", "");
	}	
	if(ctlsInitRes > 0) 
	{     
		strcpy(lcdMsg, "%F2%Pcc22Not Authorised");
		ctlsInitRes = StoreLCDMsg(0x0E, lcdMsg, "", "", "");
	}

	{
		strcpy(lcdMsg, "%F3%Pcc12 ");
		ctlsInitRes = StoreLCDMsg(23, lcdMsg, "", "", "");
	}
	
	//GetLCDMsg();

	if(ctlsInitRes > 0) 
	{
		ctlsInitRes = SetSource();   
	}
	
	if(ctlsInitRes > 0)
	{
		ctlsInitRes = SetDateTime();
	}
	
	if(ctlsInitRes > 0) 
	{
		ctlsInitRes = SetCAPubKeys();
	}

	if(CTLSDEBUG) {
		GetAllAids();
		LOG_PRINTFF(0x00000001L,"GetCfgGroup 0");
		GetCfgGroup("\x00");
		LOG_PRINTFF(0x00000001L,"GetCfgGroup 1");
		GetCfgGroup("\x01");
		LOG_PRINTFF(0x00000001L,"GetCfgGroup 2");
		GetCfgGroup("\x02");
		SVC_WAIT(100);
		LOG_PRINTFF(0x00000001L,"Get Configurable AID (GCA) 41010");
		SendGeneralMsg(0x03,0x04,"\x9f\x06\x07\xa0\x00\x00\x00\x04\x10\x10",10);
		SVC_WAIT(100);
		LOG_PRINTFF(0x00000001L,"Get Configurable AID (GCA) 31010");
		SendGeneralMsg(0x03,0x04,"\x9f\x06\x07\xa0\x00\x00\x00\x03\x10\x10",10);
		SVC_WAIT(100);
		LOG_PRINTFF(0x00000001L,"Get All Additional AID Parameters ");
		SendGeneralMsg(0xF0,0x01,NULL,0);
		SVC_WAIT(100);
		LOG_PRINTFF(0x00000001L,"Get Additional AID Parameters 41010");
		SendGeneralMsg(0xF0,0x00,"\x9f\x06\x07\xa0\x00\x00\x00\x04\x10\x10",10);
		SVC_WAIT(100);
		LOG_PRINTFF(0x00000001L,"Get Additional AID Parameters 31010");
		SendGeneralMsg(0xF0,0x00,"\x9f\x06\x07\xa0\x00\x00\x00\x03\x10\x10",10);
	}

	ctlsInitialising = 0;
	LOG_PRINTFF(0x00000001L,"InitRdr out");
}

void InitCtlsPort(void)
{
	InitRdr('0');
}

int GetCtlsTxnLimit(char *aid,  int *p_translimit, int *p_cvmlimit,int *p_floorlimit)
{
		int i =0;
		char aid_chk[30];
		char aid_chk2[30];

		strnlwr (aid_chk,aid ,strlen(aid));

		for(i=0;;i++){
			if( AIDlist[i].GroupNo==0) break;
			strnlwr (aid_chk2 , AIDlist[i].AID ,strlen(AIDlist[i].AID));
			if( strcmp( aid_chk,aid_chk2)==0) {
					*p_floorlimit = 0;//TODO
					*p_translimit = AIDlist[i].TranLimitExists ;
					*p_cvmlimit = AIDlist[i].CVMReqLimitExists ;
			}
		}
		return(0);
}

int CTLSEmvGetTac(char *tac_df,char *tac_dn,char *tac_ol, const char *AID)
{

		int i =0;
		char aid_chk[30];
		char aid_chk2[30];

		strcpy(tac_df,"");
		strcpy(tac_dn,"");
		strcpy(tac_ol,"");

		strnlwr (aid_chk,AID ,strlen(AID));
		for(i=0;;i++){
			if( AIDlist[i].GroupNo==0) break;
			strnlwr (aid_chk2 , AIDlist[i].AID ,strlen(AIDlist[i].AID));
			if( strcmp( aid_chk,aid_chk2)==0) {
				UtilHexToString( AIDlist[i].TACDefault , 5 , tac_df);
				UtilHexToString( AIDlist[i].TACDenial , 5 , tac_dn);
				UtilHexToString( AIDlist[i].TACOnline , 5 , tac_ol);
			}
		}

		return(0);
}

AID_DATA* getCtlsAIDlist()
{
	return (AIDlist);
}

#pragma endregion
