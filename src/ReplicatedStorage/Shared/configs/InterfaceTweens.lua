local TweenService = game:GetService("TweenService")
local InterfaceTweens = {}

InterfaceTweens.Tweens = {}

function InterfaceTweens:OpenFrame(element, TweenTime, Value) end
function InterfaceTweens:CloseFrame(element, TweenTime, Value) end

function InterfaceTweens:NotificationAppear(element, TweenTime, Value) end

function InterfaceTweens:NotificationDiseappear(element, TweenTime, Value) end

function InterfaceTweens:SymbolAppear(element, TweenTime, Value) end
function InterfaceTweens:SymbolDiseappear(element, TweenTime, Value) end

function InterfaceTweens:DebuffAppear(element, TweenTime, Value) end
function InterfaceTweens:DebuffDiseappear(element, TweenTime, Value) end

return InterfaceTweens
