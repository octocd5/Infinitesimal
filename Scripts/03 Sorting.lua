-- Our main table which will contain all sorted groups.
SortGroups = {}

function PlayableSongs(SongList)
	local SongTable = {}
	for Song in ivalues(SongList) do
        local Steps = SongUtil.GetPlayableSteps(Song)
		if #Steps > 0 then
			SongTable[#SongTable+1] = Song
		end
	end
	return SongTable
end

function RunGroupSorting()
	if not (SONGMAN and GAMESTATE) then
        Warn("SONGMAN or GAMESTATE were not ready! Aborting!")
        return
    end
	
	-- Empty current table if needed
	SortGroups = {}

	local SongGroups = {}

	-- Iterate through the song groups and check if they have AT LEAST one song with valid charts.
	-- If so, add them to the group.
	for GroupName in ivalues(SONGMAN:GetSongGroupNames()) do
		for Song in ivalues(SONGMAN:GetSongsInGroup(GroupName)) do
			local Steps = SongUtil.GetPlayableSteps(Song)
			if #Steps > 0 then
				SongGroups[#SongGroups + 1] = GroupName
				break
			end
		end
	end

	for i,v in ipairs(SongGroups) do
		SortGroups[#SortGroups + 1] = {
			Name = SongGroups[i],
			Banner = SONGMAN:GetSongGroupBannerPath(SongGroups[i]),
			Songs = PlayableSongs(SONGMAN:GetSongsInGroup(SongGroups[i]))
		}
		Trace("Group added: " .. SongGroups[i])
	end
	
	Trace("Group sorting done!")
end