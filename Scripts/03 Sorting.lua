-- Our main table which will contain all sorted groups.
SortGroups = {}

function GetValue( t, value )
    for k, v in pairs(t) do
        if v == value then return k end
    end
    return nil
end

function SortSongsByTitle(a, b)
    return ToLower(a:GetTranslitFullTitle()) < ToLower(b:GetTranslitFullTitle())
end

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
	
	-- Empty current table
	SortGroups = {}
    
    -- All songs available
    local AllSongs = PlayableSongs(SONGMAN:GetAllSongs())
    
    SortGroups[#SortGroups + 1] = {
        Name = "All",
        Banner = THEME:GetPathG("", "Common fallback banner"),
        Songs = AllSongs
    }
    
    Trace("Group added: " .. SortGroups[#SortGroups].Name)

    -- Song groups
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

	for i, v in ipairs(SongGroups) do
		SortGroups[#SortGroups + 1] = {
			Name = SongGroups[i],
			Banner = SONGMAN:GetSongGroupBannerPath(SongGroups[i]),
			Songs = PlayableSongs(SONGMAN:GetSongsInGroup(SongGroups[i]))
		}
        
		Trace("Group added: " .. SongGroups[i])
	end
    
    -- Alphabet order
    local Alphabet = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "#"}
    local AlphabetGroups = {}
    local SongInserted = false
    
    for j, Song in ipairs(AllSongs) do
        SongInserted = false
        
        for i, Letter in ipairs(Alphabet) do -- Skip last item
            if ToUpper(Song:GetDisplayMainTitle():sub(1, 1)) == Letter then
                if AlphabetGroups[Letter] == nil then AlphabetGroups[Letter] = {} end
                table.insert(AlphabetGroups[Letter], Song)
                SongInserted = true
                break
            end
		end
        
        if SongInserted == false then
            if AlphabetGroups["#"] == nil then AlphabetGroups["#"] = {} end
            table.insert(AlphabetGroups["#"], Song)
        end
    end
    
    for i, v in pairs(Alphabet) do
        if AlphabetGroups[v] ~= nil then
            table.sort(AlphabetGroups[v], SortSongsByTitle)
            SortGroups[#SortGroups + 1] = {
                Name = v,
                Banner = THEME:GetPathG("", "Common fallback banner"), -- something appending v at the end
                Songs = AlphabetGroups[v],
            }
        end
        
		Trace("Group added: " .. SortGroups[#SortGroups].Name)
	end
	
	Trace("Group sorting done!")
end