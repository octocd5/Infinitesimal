if not CurSong then CurSong = 1 end

if not Joined then Joined = {} end

local IncOffset = 1  -- Positive rotation
local DecOffset = 13 -- Negative rotation
local XOffset = 7    -- The center of the wheel

local function MoveSelection(self, offset, Songs)

  CurSong = CurSong + offset

  -- If selection is past the end of the list, wrap back to the first one
	if CurSong > #Songs then CurSong = 1 end
	-- If the selection is lower than one, wrap to the end of the list
	if CurSong < 1 then CurSong = #Songs end

  -- Update the offsets for increase/decrease
	DecOffset = DecOffset + offset
	IncOffset = IncOffset + offset

  if DecOffset > 13 then DecOffset = 1 end
	if IncOffset > 13 then IncOffset = 1 end

  if DecOffset < 1 then DecOffset = 13 end
  if IncOffset < 1 then IncOffset = 13 end

  -- Update the offset for the center of the wheel
	XOffset = XOffset + offset
	if XOffset > 13 then XOffset = 1 end
	if XOffset < 1 then XOffset = 13 end

  -- If we're updating the offset with a value that isn't 0, we move the wheel
  if offset ~= 0 then

    for i = 1,13 do
      local pos = CurSong + (4 * offset)

      if offset == 1 then
        pos = CurSong + (5 * offset)
      end

      while pos > #Songs do pos = pos-#Songs end
			while pos < 1 do pos = #Songs+pos end

      -- wheeeeeeeeee
      self:GetChild("Wheel"):GetChild("Container"..i):decelerate(.1)
      :addx(offset * -240)
      :rotationy(clamp((i - XOffset) * 36, -85, 85))
      :zoom(clamp(1.1 - (math.abs(i - XOffset) / 3), 0.8, 1.1))
      :z(-math.abs(i - XOffset))

      if (i == IncOffset and offset == -1) or (i == DecOffset and offset == 1) then
        self:GetChild("Wheel"):GetChild("Container"..i):sleep(0):addx((offset*-240)*-13)
        :GetChild("Banner"):queuecommand("UpdateBanner")
      end
    end

  end

  if offset ~= 0 then
		-- Stop all the music playing, Which is the Song Music
		SOUND:StopMusic()

		-- Check if its a song.
		if type(Songs[CurSong]) ~= "string" then
			-- Play Current selected Song Music.
			if Songs[CurSong][1]:GetMusicPath() then
				SOUND:PlayMusicPart(Songs[CurSong][1]:GetMusicPath(),Songs[CurSong][1]:GetSampleStart(),Songs[CurSong][1]:GetSampleLength(),0,0,true)
			end
		end
	end

end

-- The wheel itself
return function(Style)

  -- Load all the songs for a specified style (currently just pump_single)
  local Songs = LoadModule("Songs.Loader.lua")(Style)
  -- Defining the wheel itself
  local Wheel = Def.ActorFrame{Name = "Wheel"}

  -- The number of items in the wheel - some will be offscreen, this is
  -- done intentionally to make the end result look less janky
  for i = 1,13 do

    local Offset = i - 7
    local pos = CurSong + i - 7

    while pos > #Songs do pos = pos-#Songs end
		while pos < 1 do pos = #Songs+pos end

    Wheel[#Wheel+1] = Def.ActorFrame {
      Name="Container"..i,
      FOV=90,
      OnCommand=function(self)
        local Spacing = math.abs(math.sin(Offset / math.pi))
        self:x(Offset * (250 - Spacing * 100))
        self:rotationy(clamp(Offset * 36, -85, 85))
        self:z(-math.abs(Offset))
        self:zoom(clamp(1.1 - (math.abs(Offset) / 3), 0.8, 1.1))
        self:ztest(true):zbuffer(true)
      end,

      Def.Banner {
        Name="Banner",

        InitCommand=function(self)
          self:queuecommand("UpdateBanner")
        end,

    		UpdateBannerCommand=function(self)
          Song = Songs[pos][1]
  				local Path = Song:GetBannerPath()
  				if not Path then
  					Path = Song:GetBackgroundPath()
  					if not Path then
  						Path = THEME:GetPathG("Common fallback", "banner")
  					end
          else
            -- Make the banner slightly larger than 210x118 to avoid garbled edges
            -- (if only AFTs could be done here)
  				  self:LoadFromCachedBanner(Path):scaletoclipped(212, 120)
          end
    		end
    	},

      Def.Sprite {
    		Texture=THEME:GetPathG("", "MusicWheel/SongFrame"),
    	},

      Def.BitmapText {
    		Font="Combo Numbers",
    		InitCommand=function(self)
    			self:addy(-50):zoom(0.25)
    		end,
    		OnCommand=function(self, params)
    				self:settext(pos)
    		end
    	}
    }

  end

  return Def.ActorFrame {
    OnCommand=function(self)
      self:Center():zoom(SCREEN_HEIGHT/720)

      SCREENMAN:GetTopScreen():AddInputCallback(TF_WHEEL.Input(self))
      MoveSelection(self,0,Songs)
    end,

    MenuLeftCommand=function(self)
			MoveSelection(self,-1,Songs)
		end,

    MenuRightCommand=function(self)
			MoveSelection(self,1,Songs)
		end,

    BackCommand=function(self)
      SCREENMAN:GetTopScreen():SetNextScreenName(SCREENMAN:GetTopScreen():GetPrevScreenName()):StartTransitioningScreen("SM_GoToNextScreen")
    end,

    Wheel
  }

end
