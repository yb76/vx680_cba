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
