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
