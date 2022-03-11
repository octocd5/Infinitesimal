function WheelTransform (self, OffsetFromCenter, ItemIndex, NumItems)
	local Spacing = math.abs(math.sin(OffsetFromCenter / math.pi))
	self:x(OffsetFromCenter * (250 - Spacing * 100))
	self:rotationy(clamp(OffsetFromCenter * 36, -85, 85))
  self:z(-math.abs(OffsetFromCenter))

  self:zoom(clamp(1.1 - (math.abs(OffsetFromCenter) / 3), 0.8, 1.1))
end

function WheelTransformGroup (self, OffsetFromCenter, ItemIndex, NumItems)
	local Spacing = math.abs(math.sin(OffsetFromCenter / math.pi))
	self.container:x(OffsetFromCenter * (250 - Spacing * 100))
	self.container:rotationy(clamp(OffsetFromCenter * 30, -85, 85))

  self.container:zoom(clamp(1.1 - (math.abs(OffsetFromCenter) / 3), 0.8, 1.1))
end

-- TinyFoxes wheel stuff
TF_WHEEL = {}

TF_WHEEL.StyleDB = {
	["pump_single"] = "single", ["pump_halfdouble"] = "halfdouble", ["pump_double"] = "double", ["pump_couple"] = "couple", ["pump_routine"] = "routine"
}

TF_WHEEL.MPath = THEME:GetCurrentThemeDirectory().."Modules/"

function Actor:ForParent(Amount)
	local CurSelf = self
	for i = 1,Amount do
		CurSelf = CurSelf:GetParent()
	end
	return CurSelf
end

-- Change Difficulties to numbers.
TF_WHEEL.DiffTab = {
	["Difficulty_Beginner"] = 1,
	["Difficulty_Easy"] = 2,
	["Difficulty_Medium"] = 3,
	["Difficulty_Hard"] = 4,
	["Difficulty_Challenge"] = 5,
	["Difficulty_Edit"] = 6
}

-- Resize function, We use this to resize images to size while keeping aspect ratio.
function TF_WHEEL.Resize(width,height,setwidth,sethight)

	if height >= sethight and width >= setwidth then
		if height*(setwidth/sethight) >= width then
			return sethight/height
		else
			return setwidth/width
		end
	elseif height >= sethight then
		return sethight/height
	elseif width >= setwidth then
		return setwidth/width
	else
		return 1
	end
end

-- TO WRITE DOC.
function TF_WHEEL.CountingNumbers(self,NumStart,NumEnd,Duration,format)
	self:stoptweening()

	TF_WHEEL.Cur = 1
	TF_WHEEL.Count = {}

	if format == nil then format = "%.0f" end

	local Length = (NumEnd - NumStart)/10
	if string.format("%.0f",Length) == "0" then Length = 1 end
	if string.format("%.0f",Length) == "-0" then Length = -1 end

	if not self:GetCommand("Count") then
		self:addcommand("Count",function(self)
			self:settext(TF_WHEEL.Count[TF_WHEEL.Cur])
			TF_WHEEL.Cur = TF_WHEEL.Cur + 1
		end)
	end

	for n = NumStart,NumEnd,string.format("%.0f",Length) do
		TF_WHEEL.Count[#TF_WHEEL.Count+1] = string.format(format,n)
		self:sleep(Duration/10):queuecommand("Count")
	end
	TF_WHEEL.Count[#TF_WHEEL.Count+1] = string.format(format,NumEnd)
	self:sleep(Duration/10):queuecommand("Count")
end

-- Main Input Function.
-- We use this so we can do ButtonCommand.
-- Example: MenuLeftCommand=function(self) end.
function TF_WHEEL.Input(self)
	return function(event)
		if not event.PlayerNumber then return end
		self.pn = event.PlayerNumber
		if ToEnumShortString(event.type) == "FirstPress" or ToEnumShortString(event.type) == "Repeat" then
			self:queuecommand(event.GameButton)
		end
		if ToEnumShortString(event.type) == "Release" then
			self:queuecommand(event.GameButton.."Release")
		end
	end
end
