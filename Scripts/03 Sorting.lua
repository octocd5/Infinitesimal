-- Our main table which will contain all sorted groups.
SortGroups = {}

local function GetValue(t, value)
    for k, v in pairs(t) do
        if v == value then return k end
    end
    return nil
end

local function HasValue(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function PairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end

local function SortSongsByTitle(a, b)
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
        
        for i, Letter in ipairs(Alphabet) do
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
    
    -- Level order (single and double)
    local LevelGroups = {}
    
    for j, Song in ipairs(AllSongs) do
        for i, Chart in ipairs(SongUtil.GetPlayableSteps(Song)) do
            if ToEnumShortString(ToEnumShortString(Chart:GetStepsType())) == "Single" then
                local ChartLevel = Chart:GetMeter()
                if LevelGroups[ChartLevel] == nil then LevelGroups[ChartLevel] = {} end
                if not HasValue(LevelGroups[ChartLevel], Song) then
                table.insert(LevelGroups[ChartLevel], Song) end
            end
		end
    end
    
    for i, v in PairsByKeys(LevelGroups) do
        SortGroups[#SortGroups + 1] = {
            Name = "Single " .. i,
            Banner = THEME:GetPathG("", "Common fallback banner"), -- something appending v at the end
            Songs = v,
        }
        
		Trace("Group added: " .. SortGroups[#SortGroups].Name)
	end
    
    -- Reset table (yes I am this lazy)
    LevelGroups = {}
    
    for j, Song in ipairs(AllSongs) do
        for i, Chart in ipairs(SongUtil.GetPlayableSteps(Song)) do
            if ToEnumShortString(ToEnumShortString(Chart:GetStepsType())) == "Double" then
                local ChartLevel = Chart:GetMeter()
                if LevelGroups[ChartLevel] == nil then LevelGroups[ChartLevel] = {} end
                if not HasValue(LevelGroups[ChartLevel], Song) then
                table.insert(LevelGroups[ChartLevel], Song) end
            end
		end
    end
    
    for i, v in PairsByKeys(LevelGroups) do
        SortGroups[#SortGroups + 1] = {
            Name = "Double " .. i,
            Banner = THEME:GetPathG("", "Common fallback banner"), -- something appending v at the end
            Songs = v,
        }
        
		Trace("Group added: " .. SortGroups[#SortGroups].Name)
	end
	
	Trace("Group sorting done!")
end