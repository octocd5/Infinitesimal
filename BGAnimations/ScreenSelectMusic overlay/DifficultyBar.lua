local t = Def.ActorFrame {
	
	-- This is weird. Don't ask me
	InitCommand=function(self)
		self:vertalign(top):horizalign(center)
		:x(SCREEN_CENTER_X)
        :y(SCREEN_CENTER_Y+27.5)
	end;
	SongChosenMessageCommand=function(self)
		self:stoptweening():decelerate(0.25):zoom(1.265)
	end;
	SongUnchosenMessageCommand=function(self)
		self:stoptweening():decelerate(0.2):zoom(1)
	end;
	
    LoadActor(THEME:GetPathG("","DiffBar"))..{
        InitCommand=function(self)
            self:zoom(0.73):vertalign(top):horizalign(center)
        end;
    };

    LoadActor(THEME:GetPathG("","DifficultyDisplay"))..{
        InitCommand=function(self)
            self:vertalign(top):horizalign(center)
        end;
    };
};

return t;
