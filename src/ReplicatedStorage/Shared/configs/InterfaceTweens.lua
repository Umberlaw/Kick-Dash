local TweenService = game:GetService("TweenService")
local InterfaceTweens = {}

InterfaceTweens.Tweens = {}

local Details = {}

function InterfaceTweens:Lerp(a, b, t)
	return a + (b - a) * t
end
--------------------------------------------------------------------
function InterfaceTweens:HealthBarGlowUpdate(element, values: table)
	return TweenService:Create(element, TweenInfo.new(1.75, Enum.EasingStyle.Back), { Offset = values.Offset })
end
function InterfaceTweens:HealthBarUpdate(element, values: table)
	return TweenService:Create(element, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Offset = values.Offset })
end
function InterfaceTweens:HealthBarRedUpdate(element, values: table)
	return TweenService:Create(element, TweenInfo.new(2, Enum.EasingStyle.Quint), { Offset = values.Offset })
end

--------------HealthBars-------------------------------
function InterfaceTweens:HitNotificationAppear(element, values: table)
	local SizeUpTween = TweenService:Create(
		element.UIScale,
		TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0),
		{ Scale = values.Scale }
	)
	local SizeNormalTween = TweenService:Create(
		element.UIScale,
		TweenInfo.new(0.225, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0),
		{ Scale = 1 }
	)

	local rotateUpTween = TweenService:Create(
		element:FindFirstChild(element.Name),
		TweenInfo.new(0.113, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0),
		{ Rotation = element.Rotation + 18 }
	)
	local rotateDownTween = TweenService:Create(
		element:FindFirstChild(element.Name),
		TweenInfo.new(0.113, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0),
		{ Rotation = 0 }
	)
	return SizeUpTween, SizeNormalTween, rotateUpTween, rotateDownTween
end

function InterfaceTweens:HitNotificationDisAppear(element, values: table)
	local DiseAppearTransparency = TweenService:Create(
		element,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0),
		{ GroupTransparency = 1 }
	)
	local ScaleDown = TweenService:Create(
		element.UIScale,
		TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0),
		{ Scale = 0 }
	)
	return DiseAppearTransparency, ScaleDown
end

-----------PASSIVESSS--------------------------------
function InterfaceTweens:PassivePopUp(element, values)
	return TweenService:Create(
		element,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0),
		{ Position = values.Position, Size = values.Size }
	)
end

function InterfaceTweens:PassivePopNormal(element, values)
	return TweenService:Create(
		element,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In, 0, false, 0),
		{ Position = values.Position, Size = values.Size }
	)
end

function InterfaceTweens:ShowPassiveBubble(element)
	return TweenService:Create(
		element,
		TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, false, 0),
		{ ImageTransparency = 0 }
	)
end

function InterfaceTweens:IconTransparency(element, values)
	return TweenService:Create(
		element,
		TweenInfo.new(0.8, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, 0, false, 0),
		{ GroupTransparency = values.Transparency }
	)
end

----------------------TextEffects(Countdowns)-------------------------------------

function InterfaceTweens:FadeInOut(element: TextLabel, values: table)
	local PopScale = values.PopScale or 0.8
	local TweenDuration = values.TweenDuration or 0.15
	local OriginalSize = element.Size
	local OriginalPosition = element.Position
	local bounceX = OriginalPosition.X.Scale + 0.01
	local bounceY = OriginalPosition.Y.Scale + 0.0375
	local BounceDownY = OriginalPosition.Y.Scale - 0.1
	local YOffset = OriginalPosition.Y.Offset
	print(YOffset, BounceDownY)

	local FadeInAnim = TweenService:Create(
		element,
		TweenInfo.new(TweenDuration / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ TextTransparency = 0.5 }
	)
	local UIStrokeFadeInAnim = TweenService:Create(
		element.UIStroke,
		TweenInfo.new(TweenDuration / 2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Transparency = 0.5 }
	)

	local GrowTween =
		TweenService:Create(element, TweenInfo.new(TweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Size = UDim2.new(OriginalSize.X.Scale * PopScale, 0, OriginalSize.Y.Scale * PopScale, 0),
			Rotation = 0,
			Position = UDim2.new(bounceX, 0, bounceY, YOffset),
		})

	local ShrinkTween = TweenService:Create(
		element,
		TweenInfo.new(TweenDuration, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
		{
			Size = OriginalSize,
			Rotation = 0,
			Position = UDim2.new(OriginalPosition.X.Scale, 0, BounceDownY, YOffset),
		}
	)
	local FadeOutTween =
		TweenService:Create(element, TweenInfo.new(TweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
			TextTransparency = 0,
		})
	local strokeFadeOutTween = element.UIStroke
		and TweenService:Create(
			element.UIStroke,
			TweenInfo.new(TweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{
				Transparency = 0,
			}
		)
	local ResetTween =
		TweenService:Create(element, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Rotation = 0,
			Position = UDim2.new(OriginalPosition.X.Scale, 0, OriginalPosition.Y.Scale, YOffset),
		})

	return FadeInAnim, UIStrokeFadeInAnim, GrowTween, ShrinkTween, FadeOutTween, strokeFadeOutTween, ResetTween
end

function InterfaceTweens:TextIncrease(element: textLabel, values: table)
	local popUpScale = 1.15
	local popDuration = 0.8

	local growTween = TweenService:Create(
		element.UIScale,
		TweenInfo.new(popDuration / 2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{
			Scale = popUpScale,
		}
	)

	local shrinkTween = TweenService:Create(
		element.UIScale,
		TweenInfo.new(popDuration / 2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
		{
			Scale = 1,
		}
	)

	return growTween, shrinkTween
end

function InterfaceTweens:TextDecrease(element: TextLabel, values: table)
	local popDuration = 0.4
	local PopScale = 0.93
	--[[if not Details[element] then
		Details[element] = { times = 0 }
	end
	local radiusX = 0.0035
	local speed = 2 * math.pi / 0.75
	local radiusY = 0.0025
	local maxRotation = -2.5
	print(values)
	Details[element].times = Details[element].times + values.times * speed

	local offSetX = math.sin(Details[element].times) * radiusX
	local offSetY = math.cos(Details[element].times) * radiusY
	element.Position =
		UDim2.fromScale(values.OriginalPosition.X.Scale + offSetX, values.OriginalPosition.Y.Scale + offSetY)

	local rotationOffset = math.sin(Details[element].times) * maxRotation
	element.Rotation = values.OriginalRotation + rotationOffset]]

	local GrowTween = TweenService:Create(
		element.UIScale,
		TweenInfo.new(popDuration / 2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{
			Scale = PopScale,
		}
	)

	local ShrinkTween = TweenService:Create(
		element.UIScale,
		TweenInfo.new(popDuration / 2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
		{
			Scale = 1,
		}
	)

	return GrowTween, ShrinkTween
end

function InterfaceTweens:TextGain(element: TextLabel, values: table) end

function InterfaceTweens:TextLose(element: TextLabel, values: table) end

return InterfaceTweens
