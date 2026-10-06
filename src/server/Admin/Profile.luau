-- Bounded server-only metadata; backups contain no nested admin metadata.
local Profile = {}
function Profile.Restore(profile, raw, sanitize)
	if type(raw) ~= "table" then
		return
	end
	local metadata = { Touched = raw.Touched == true, Items = {} }
	for id, count in pairs(profile.Inventory) do
		local granted = type(raw.Items) == "table" and raw.Items[id]
		if type(granted) == "number" and granted == granted and granted >= 0 and granted <= 9e15 then
			metadata.Items[id] = math.min(count, math.floor(granted))
		end
	end
	if type(raw.Backup) == "table" then
		metadata.Backup = sanitize(raw.Backup, true)
		metadata.BackupAt = if type(raw.BackupAt) == "number"
				and raw.BackupAt >= 0
				and raw.BackupAt <= 4102444800
			then math.floor(raw.BackupAt)
			else 0
	end
	profile.Admin = metadata
end
function Profile.Touch(profile)
	profile.Admin = profile.Admin or { Items = {} }
	profile.Admin.Touched = true
	return profile.Admin
end
return Profile
