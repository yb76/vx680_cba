function toomany_saf()
	local safmin,safmax= terminal.GetArrayRange("SAF")
	local cnt = safmax - safmin + 1
	local limit = config.saf_limit or 0
	if cnt > limit then return true else return false end
end
