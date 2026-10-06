-- Shared post-award presentation. Only normal awards update natural records/events.
local Presentation = {}
function Presentation.Publish(player, profile, item, payload, world, events, remotes, duration)
	if payload.Admin then
		events:Preview(player, item)
	else
		events:Trigger(player, item, payload.FlushId)
	end
	if not payload.Compact then
		world:Animate(player, item, profile.Settings.SkipAnimation, duration, payload.Admin == true)
	end
	remotes.Result:FireClient(player, "Flush", payload)
end
return Presentation
