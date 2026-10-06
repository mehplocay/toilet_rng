-- Shared post-award presentation. Only normal awards update natural records/events.
local Presentation = {}
function Presentation.Publish(player, profile, item, payload, world, events, remotes, duration, stopped)
	if payload.Admin then
		events:Preview(player, item)
	else
		events:Trigger(player, item, payload.FlushId)
	end
	-- Compact describes the owner's result UI, never the shared toilet animation.
	if not stopped then
		world:Animate(
			player,
			item,
			profile.Settings.SkipAnimation,
			duration,
			payload.Admin == true,
			payload.Compact,
			payload.Automatic
		)
	end
	remotes.Result:FireClient(player, "Flush", payload)
end
return Presentation
