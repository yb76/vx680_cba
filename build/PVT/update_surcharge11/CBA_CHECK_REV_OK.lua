function check_rev_ok()
	local revok =  ( not config.safsign or config.safsign and do_obj_saf_rev_send("REVERSAL") )
	if not revok then return false else return true end
end
