local t = Def.ActorFrame {
    OnCommand=function(self)
        -- Change default sort to Basic Mode songs only
        SONGMAN:SetPreferredSongs("PreferredSongs")
        SCREENMAN:GetTopScreen():GetMusicWheel():ChangeSort("SortOrder_Preferred")
        -- Change timing window to Easy
        LoadModule("Config.Save.lua")("SmartTimings",tostring("Pump Easy"),"Save/OutFoxPrefs.ini")
    end
}

-- The column thing
t[#t+1] = Def.Quad {
    InitCommand=function(self)
        self:xy(SCREEN_CENTER_X,SCREEN_CENTER_Y):valign(0.5)
        :zoomx(255)
        :diffuse(0,0,0,0.75)
        :zoomy(0)
        :decelerate(0.5)
        :zoomy(SCREEN_HEIGHT)
    end,
    OffCommand=function(self)
        self:stoptweening():decelerate(0.5):zoomy(0)
    end
}

for pn in ivalues(GAMESTATE:GetEnabledPlayers()) do
    local spacing = (IsUsingWideScreen() and 80 or 15)
    local width = (IsUsingWideScreen() and 200 or 175)
    local posx = (pn == PLAYER_1 and SCREEN_LEFT + spacing or SCREEN_RIGHT - (spacing + width + 10) )
    local title = THEME:GetString("MessageBoxes", "TutorialTitle")
    local body = THEME:GetString("MessageBoxes", "TutorialBody")

    t[#t+1] = Def.ActorFrame {
        Name="TutorialMessage"..pn,
        LoadModule("UI.MessageBox.lua")(posx, SCREEN_CENTER_Y - 125, width, 15, title, body)
    }
    
    t[#t+1] = Def.ActorFrame {
        InitCommand=function(self)
            self:xy(SCREEN_CENTER_X, -SCREEN_CENTER_Y)
            :easeoutexpo(1):y(SCREEN_CENTER_Y)
        end,
        
        OffCommand=function(self)
            self:stoptweening():easeoutexpo(1):y(-SCREEN_CENTER_Y)
        end,
        
        Def.ActorFrame {
            InitCommand=function(self) self:y(90) end,

            StepsChosenMessageCommand=function(self, params)
                if params.Player == pn then
                    self:stoptweening():easeoutexpo(0.5)
                    :x(pn == PLAYER_2 and 360 or -360)
                end
            end,
            StepsUnchosenMessageCommand=function(self)
                self:stoptweening():easeoutexpo(0.5):x(0)
            end,
            
            SongChosenMessageCommand=function(self)
                self:stoptweening():easeoutexpo(0.5):y(160):zoom(2)
            end,
            SongUnchosenMessageCommand=function(self)
                self:stoptweening():easeoutexpo(0.5):xy(0, 85):zoom(1)
            end,

            Def.Quad {
                InitCommand=function(self)
                    self:zoomto(128, 32):diffuse(Color.White)

                    if pn == PLAYER_2 then
                        self:diffuserightedge(Color.Invisible)
                    else
                        self:diffuseleftedge(Color.Invisible)
                    end
                end
            },

            Def.Sprite {
                Texture=THEME:GetPathG("", "UI/Ready" .. ToEnumShortString(pn)),
                InitCommand=function(self) self:y(1) end
            }
        }
    }
end

t[#t+1] = Def.ActorFrame {
    Def.ActorFrame {
        InitCommand=function(self)
            self:xy(SCREEN_CENTER_X, -SCREEN_CENTER_Y)
            :easeoutexpo(1):y(SCREEN_CENTER_Y)
        end,
        OffCommand=function(self)
            self:stoptweening():easeoutexpo(1):y(-SCREEN_CENTER_Y)
        end,

        LoadActor("SongPreview") .. {
            InitCommand=function(self) self:y(-100) end
        },

        Def.ActorFrame {
            InitCommand=function(self) self:y(85) end,

            SongChosenMessageCommand=function(self)
                self:stoptweening():easeoutexpo(0.5):y(160):zoom(2)
            end,
            SongUnchosenMessageCommand=function(self)
                self:stoptweening():easeoutexpo(0.5):y(85):zoom(1)
            end,

            Def.Sprite {
                Texture=THEME:GetPathG("", "DifficultyDisplay/ShortBar"),
                InitCommand=function(self) self:zoom(1.2) end
            },

            LoadActor("BasicChartDisplay", 4)
        }
    }
}

t[#t+1] = Def.ActorFrame {
    LoadActor("FullModeAnim"),

    CodeCommand=function(self, params)
        if params.Name == "FullMode" then
            LoadModule("Config.Save.lua")("SmartTimings",tostring("Pump Normal"),"Save/OutFoxPrefs.ini")
            self:GetChild("FullModeSound"):play()
            self:GetChild("FullModeAnim"):playcommand("Animate")
            self:sleep(1):queuecommand("FullModeTransition")
        end
    end,

    FullModeTransitionCommand=function()
        setenv("IsBasicMode", false)
        SCREENMAN:GetTopScreen():GetMusicWheel():Move(0)
        SCREENMAN:GetTopScreen():SetNextScreenName("ScreenSelectMusic")
        SCREENMAN:GetTopScreen():StartTransitioningScreen("SM_GoToNextScreen")
    end,

    Def.Sound {
        Name="FullModeSound",
        File=THEME:GetPathS("", "FullMode"),
        IsAction=true
    }
}

return t
