if not CurSong then CurSong = 1 end

if not Joined then Joined = {} end

local Offset = 7

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
        -- This doesn't work and I don't understand why
    		OnCommand=function(self)
          Song = Songs[i][1]
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
    				self:settext(i)
    		end
    	}
    }

  end

  return Def.ActorFrame {
    OnCommand=function(self)
      self:Center():zoom(SCREEN_HEIGHT/720)
    end,

    Wheel
  }

end
