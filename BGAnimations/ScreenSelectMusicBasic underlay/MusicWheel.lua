local WheelSize = 11
local WheelCenter = math.ceil( WheelSize * 0.5 )
local WheelItem = { Width = 212, Height = 120 }
local WheelSpacing = 250
local WheelRotation = 0.1

local Songs = {}
local Targets = {}

for Song in ivalues(SONGMAN:GetPreferredSortSongs()) do
	if SongUtil.GetPlayableSteps(Song) then
		Songs[#Songs+1] = Song
	end
end

local CurrentIndex = math.random(#Songs)
local SongIsChosen = false

local function InputHandler(event)
	local pn = event.PlayerNumber
    if not pn then return end

    -- To avoid control from a player that has not joined, filter the inputs out
    if pn == PLAYER_1 and not GAMESTATE:IsPlayerEnabled(PLAYER_1) then return end
    if pn == PLAYER_2 and not GAMESTATE:IsPlayerEnabled(PLAYER_2) then return end

    if not SongIsChosen then
        -- Don't want to move when releasing the button
        if event.type == "InputEventType_Release" then return end

        local button = event.button
        if button == "Left" or button == "MenuLeft" or button == "DownLeft" then
            CurrentIndex = CurrentIndex - 1
            if CurrentIndex < 1 then CurrentIndex = #Songs end
            
            UpdateItemTargets(CurrentIndex)
            MESSAGEMAN:Broadcast("Scroll", { Direction = -1 })
            GAMESTATE:SetCurrentSong(Songs[CurrentIndex])

        elseif button == "Right" or button == "MenuRight" or button == "DownRight" then
            CurrentIndex = CurrentIndex + 1
            if CurrentIndex > #Songs then CurrentIndex = 1 end
            
            UpdateItemTargets(CurrentIndex)
            MESSAGEMAN:Broadcast("Scroll", { Direction = 1 })
            GAMESTATE:SetCurrentSong(Songs[CurrentIndex])

        elseif button == "Start" or button == "MenuStart" or button == "Center" then
            MESSAGEMAN:Broadcast("MusicWheelStart")

        elseif button == "Back" then
            SCREENMAN:GetTopScreen():Cancel()
        end
    end

	MESSAGEMAN:Broadcast("UpdateMusic")
end

-- Update Songs item targets
function UpdateItemTargets(val)
    for i = 1, WheelSize do
        Targets[i] = val + i - WheelCenter
        -- wrap to fit to Songs list size
        while Targets[i] > #Songs do Targets[i] = Targets[i] - #Songs end
        while Targets[i] < 1 do Targets[i] = Targets[i] + #Songs end
    end
end

-- Manages banner on sprite
function UpdateBanner(self, Song)
    self:LoadFromCachedBanner(Song:GetBannerPath()):scaletoclipped(WheelItem.Width / 2, WheelItem.Height / 2):zoom(2)
end

local t = Def.ActorFrame {
    InitCommand=function(self)
        self:y(SCREEN_HEIGHT / 2 + 150):fov(90):SetDrawByZPosition(true)
        :vanishpoint(SCREEN_CENTER_X, SCREEN_BOTTOM-150)
        UpdateItemTargets(CurrentIndex)
    end,

    OnCommand=function(self)
        GAMESTATE:SetCurrentSong(Songs[CurrentIndex])
        SCREENMAN:GetTopScreen():AddInputCallback(InputHandler)

        self:easeoutexpo(1):y(SCREEN_HEIGHT / 2 - 150)
    end,

    -- Prevent the song list from moving when transitioning
    OffCommand=function(self)
        SongIsChosen = true
    end,

    -- Update song list
    CurrentSongChangedMessageCommand=function(self)
        self:stoptweening()

        -- Play song preview
        SOUND:StopMusic()
        self:sleep(0.25):queuecommand("PlayMusic")
    end,

    -- Race condition workaround (yuck)
    MusicWheelStartMessageCommand=function(self) self:sleep(0.01):queuecommand("Confirm") end,
    ConfirmCommand=function(self) MESSAGEMAN:Broadcast("SongChosen") end,

    -- These are to control the functionality of the music wheel
    SongChosenMessageCommand=function(self)
        self:stoptweening():easeoutexpo(1):y(SCREEN_HEIGHT / 2 + 150)
        SongIsChosen = true
    end,
    SongUnchosenMessageCommand=function(self)
        self:stoptweening():easeoutexpo(0.5):y(SCREEN_HEIGHT / 2 - 150)
        SongIsChosen = false
    end,

    -- Play song preview (thanks Luizsan)
    PlayMusicCommand=function(self)
        local Song = GAMESTATE:GetCurrentSong()
        if Song then
            SOUND:PlayMusicPart(Song:GetMusicPath(), Song:GetSampleStart(), Song:GetSampleLength(), 0, 1, false, false, false, Song:GetTimingData())
        end
    end,

    Def.Sound {
        File=THEME:GetPathS("MusicWheel", "change"),
        IsAction=true,
        ScrollMessageCommand=function(self) self:play() end
    },

    Def.Sound {
        File=THEME:GetPathS("Common", "Start"),
        IsAction=true,
        MusicWheelStartMessageCommand=function(self) self:play() end
    },
}

-- item wheel
for i = 1, WheelSize do

    t[#t+1] = Def.ActorFrame{
        OnCommand=function(self)
            -- load banner
            UpdateBanner(self:GetChild("Banner"), Songs[Targets[i]])

            -- set initial position
            -- Direction = 0 means it won't tween
            self:playcommand("Scroll", {Direction = 0})
        end,

        ScrollMessageCommand=function(self,param)
            self:finishtweening()

            -- calculate position
            local xpos = SCREEN_CENTER_X + (i - WheelCenter) * WheelSpacing

            -- calculate displacement based on input
            local displace = -param.Direction * WheelSpacing

            -- only tween if a Direction was specified
            local tween = param and param.Direction and math.abs(param.Direction) > 0
            
            -- adjust and wrap actor index
            i = i - param.Direction
            while i > WheelSize do i = i - WheelSize end
            while i < 1 do i = i + WheelSize end

            -- if it's an edge item, load a new banner
            -- edge items should never tween
            if i == 1 or i == WheelSize then
				UpdateBanner(self:GetChild("Banner"), Songs[Targets[i]])
            elseif tween then
                self:easeoutexpo(0.25)
            end

            -- animate
            self:xy(xpos + displace, SCREEN_CENTER_Y)
            self:rotationy((SCREEN_CENTER_X - xpos - displace) * -WheelRotation)
            self:z(-math.abs(SCREEN_CENTER_X - xpos - displace) * 0.25)
            self:GetChild(""):GetChild("Index"):playcommand("Refresh")
        end,

        Def.Banner {
            Name="Banner",
        },

        Def.Sprite {
            Texture=THEME:GetPathG("", "MusicWheel/SongFrame"),
        },

        Def.ActorFrame {
            Def.Quad {
                InitCommand=function(self)
                    self:zoomto(60, 18):addy(-50)
                    :diffuse(0,0,0,0.6)
                    :fadeleft(0.3):faderight(0.3)
                end
            },

            Def.BitmapText {
                Name="Index",
                Font="Montserrat semibold 40px",
                InitCommand=function(self)
                    self:addy(-50):zoom(0.4):skewx(-0.1):diffusetopedge(0.95,0.95,0.95,0.8):shadowlength(1.5)
                end,
                RefreshCommand=function(self,param) self:settext(Targets[i]) end
            }
        }
    }
end

return t
