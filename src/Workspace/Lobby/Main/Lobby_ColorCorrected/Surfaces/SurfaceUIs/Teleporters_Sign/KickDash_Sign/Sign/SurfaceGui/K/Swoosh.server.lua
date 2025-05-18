local TweenService = game:GetService("TweenService")

local uiElement = script.Parent
local gradient = uiElement:WaitForChild("UIGradient")

-- Gather available swoosh sounds
local soundFolder = script.Parent.Parent.Parent
local swooshSounds = {}

for _, child in ipairs(soundFolder:GetChildren()) do
	if child:IsA("Sound") and (child.Name == "swoosh" or child.Name == "swoosh2" or child.Name == "swoosh3") then
		table.insert(swooshSounds, child)
	end
end

if #swooshSounds == 0 then
	warn("No swoosh sounds found in: ", soundFolder:GetFullName())
end

local originalSize = uiElement.Size
local maxSize = originalSize + UDim2.new(0.1, 0, 0.1, 0)
local tweenDuration = 0.5

local easingStyle = Enum.EasingStyle.Back
local easingDirection = Enum.EasingDirection.Out

gradient.Offset = Vector2.new(-1, 0)
uiElement.Size = maxSize

local backwardTween = TweenService:Create(gradient, TweenInfo.new(tweenDuration, easingStyle, easingDirection), {
	Offset = Vector2.new(0, 0)
})

local sizeDownTween = TweenService:Create(uiElement, TweenInfo.new(tweenDuration, easingStyle, easingDirection), {
	Size = originalSize
})

local forwardTween = TweenService:Create(gradient, TweenInfo.new(tweenDuration, easingStyle, easingDirection), {
	Offset = Vector2.new(-1, 0)
})

local sizeUpTween = TweenService:Create(uiElement, TweenInfo.new(tweenDuration, easingStyle, easingDirection), {
	Size = maxSize
})

-- Utility function to play a random swoosh
local function playRandomSwoosh()
	if #swooshSounds > 0 then
		local chosenSound = swooshSounds[math.random(1, #swooshSounds)]
		chosenSound:Play()
	end
end

while true do
	playRandomSwoosh()

	backwardTween:Play()
	sizeDownTween:Play()
	backwardTween.Completed:Wait()

	wait(0.0825)

	playRandomSwoosh()

	forwardTween:Play()
	sizeUpTween:Play()
	forwardTween.Completed:Wait()
end
