local TweenService = game:GetService("TweenService")
local InterfaceTweens = {}

InterfaceTweens.Tweens = {}

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

return InterfaceTweens
