# Execute the actual builders with a small headless instance mock. This checks
# construction/budgets and decoration flags, not Roblox rendering or physics.
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path $PSScriptRoot -Parent
$generatedPath = Join-Path $workspaceRoot '.visual-check.generated.luau'
$harness = @'
local Vector3 = {}
local vm = {}
function Vector3.new(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, vm) end
vm.__add = function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vm.__sub = function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vm.__mul = function(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
vm.__index = function(a,key)
	if key == "Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
	if key == "Unit" then return a*(1/math.max(a.Magnitude, 1e-9)) end
end
local CFrame = {}
local cm = {}
function CFrame.new(x,y,z) return setmetatable({ Position = if type(x)=="table" then x else Vector3.new(x,y,z) },cm) end
function CFrame.Angles() return CFrame.new() end
function CFrame.lookAt(position) return CFrame.new(position) end
cm.__mul = function(a,b) return CFrame.new(a.Position+b.Position) end
cm.__add = function(a,b) return CFrame.new(a.Position+b) end
cm.__index = { VectorToWorldSpace = function(_,v) return v end }
local Color3 = {}
function Color3.new(r,g,b)
	return { R=r or 0,G=g or 0,B=b or 0,Lerp=function(a,other,t) return Color3.new(a.R+(other.R-a.R)*t,a.G+(other.G-a.G)*t,a.B+(other.B-a.B)*t) end }
end
function Color3.fromRGB(r,g,b) return Color3.new(r/255,g/255,b/255) end
local Enum = setmetatable({}, { __index=function(self,key)
	local enum = setmetatable({}, {__index=function(_,name) return key.."."..name end})
	rawset(self,key,enum)
	return enum
end })
local signal = { Connect=function() return {Disconnect=function() end} end, Once=function() end }
local methods = {}
local function isPart(object) return object.ClassName=="Part" or object.ClassName=="WedgePart" or object.ClassName=="SpawnLocation" end
function methods:IsA(class) return self.ClassName==class or class=="BasePart" and isPart(self) end
function methods:GetChildren() return table.clone(self._children) end
function methods:GetDescendants()
	local result={}
	for _,child in ipairs(self._children) do
		table.insert(result,child)
		for _,nested in ipairs(child:GetDescendants()) do table.insert(result,nested) end
	end
	return result
end
function methods:SetAttribute(key,value) self._attributes[key]=value end
function methods:GetAttribute(key) return self._attributes[key] end
function methods:Destroy()
	self:ClearAllChildren()
	self.Parent=nil
end
function methods:ClearAllChildren() for _,child in ipairs(self:GetChildren()) do child:Destroy() end end
function methods:GetPivot() return self.WorldPivot or (self.PrimaryPart and self.PrimaryPart.CFrame) or CFrame.new() end
function methods:ScaleTo() end
function methods:FindFirstChild(name) for _,child in ipairs(self._children) do if child.Name==name then return child end end end
local Instance = {}
function Instance.new(class)
	return setmetatable({_props={ClassName=class,Name=class},_children={},_attributes={}}, {
		__index=function(self,key) return methods[key] or self._props[key] or (if key=="Triggered" or key=="Changed" then signal else nil) end,
		__newindex=function(self,key,value)
			if key=="Parent" then
				local old=self._props.Parent
				if old then local index=table.find(old._children,self); if index then table.remove(old._children,index) end end
				if value then table.insert(value._children,self) end
			end
			self._props[key]=value
		end,
	})
end
local nodes, cache, sources = {}, {}, {}
local function node(path)
	if nodes[path] then return nodes[path] end
	local object={Path=path}
	nodes[path]=object
	local parent,name=path:match("^(.*)/([^/]+)$")
	if parent then object.Parent=node(parent); object.Parent[name]=object end
	return object
end
local game = { ReplicatedStorage={Shared=node("src/shared")} }
function game:GetService(name) return {Name=name} end
local function sequence(...) return {...} end
local globals={Vector3=Vector3,Vector2={new=sequence},CFrame=CFrame,Color3=Color3,Enum=Enum,Instance=Instance,game=game,
	UDim2={fromScale=sequence,fromOffset=sequence}, ColorSequence={new=sequence},NumberSequence={new=sequence},NumberSequenceKeypoint={new=sequence},NumberRange={new=sequence}}
local loadModule
loadModule=function(object)
	local path=object.Path
	if cache[path] then return cache[path] end
	local fn,err=loadstring(assert(sources[path],path),path)
	assert(fn,err)
	local env=setmetatable({script=object,require=loadModule},{__index=function(_,key) return globals[key] or getfenv()[key] end})
	setfenv(fn,env)
	local value=fn()
	cache[path]=value
	return value
end
'@
$modulePaths = @(
    'src/shared/Config/Assets.luau', 'src/shared/Config/Visuals.luau', 'src/shared/Config/World.luau',
    'src/shared/Config/Items.luau', 'src/shared/Config/Toilets.luau', 'src/shared/Config/Rarities.luau',
    'src/shared/Visuals/Primitives.luau', 'src/shared/Visuals/Items.luau', 'src/shared/Visuals/Toilets.luau',
    'src/server/World/Models.luau', 'src/server/World/Builders/Decor.luau',
    'src/server/World/Builders/Hub.luau', 'src/server/World/Builders/Plot.luau',
    'src/server/World/WorldService.luau'
)
foreach ($modulePath in $modulePaths) {
    $source = Get-Content -Raw -LiteralPath (Join-Path $workspaceRoot $modulePath)
    $moduleName = $modulePath.Substring(0, $modulePath.Length - 5)
    $harness += "`nnode('$moduleName')`nsources['$moduleName'] = [====[`n$source`n]====]`n"
}
$harness += @'
local P=loadModule(node("src/shared/Visuals/Primitives"))
local Toilets=loadModule(node("src/shared/Visuals/Toilets"))
local Items=loadModule(node("src/shared/Config/Items"))
local ItemBuilder=loadModule(node("src/shared/Visuals/Items"))
local V=loadModule(node("src/shared/Config/Visuals"))
local function validate(root)
	for _,object in ipairs(root:GetDescendants()) do
		if isPart(object) then
			assert(object.Anchored,"Unanchored geometry: "..object.Name)
			assert(not object.CanTouch,"Touch-enabled decoration: "..object.Name)
			assert(object.CanCollide or not object.CanQuery,"Queryable decoration: "..object.Name)
			assert(object.Size.X>0 and object.Size.Y>0 and object.Size.Z>0,"Invalid part size")
		end
		assert(object.ClassName~="MeshPart" and object.ClassName~="UnionOperation","External/runtime mesh geometry")
	end
end
local root=Instance.new("Folder")
local Hub=loadModule(node("src/server/World/Builders/Hub"))
local Plot=loadModule(node("src/server/World/Builders/Plot"))
Hub.Build(root)
local hubCount=P.Count(root)
assert(hubCount<V.Budget.Hub+1)
local maxItem=0
for _,item in ipairs(Items) do
	local model=ItemBuilder.Build(root,CFrame.new(),item)
	assert(model.PrimaryPart and P.Count(model)>4,item.Id.." missing geometry")
	maxItem=math.max(maxItem,P.Count(model))
	validate(model)
	model:Destroy()
end
local World=loadModule(node("src/server/World/WorldService"))
local maxPlot=0
local maxToilet=0
for tier=1,7 do
	local plot=Plot.Build(root,CFrame.new(),tier)
	plot.Toilet=Toilets.Build(plot.Model,plot.CFrame,tier)
	maxToilet=math.max(maxToilet,P.Count(plot.Toilet))
	for _,name in ipairs({"Bowl","Tank","Foot","OpenLid","FlushHandle","Water","Seat"}) do
		assert(plot.Toilet:FindFirstChild(name),"Missing toilet component: "..name)
	end
	local profile={DisplaySlots=100,Displays={}}
	for slot=1,100 do profile.Displays[tostring(slot)]="AlienToilet" end
	plot.Profile=profile
	for page=1,20 do
		plot.Page=page
		World:RenderDisplays(plot)
		local count=P.Count(plot.Model)+maxItem
		assert(count<400,"Plot with transient drop exceeds budget: "..count)
		maxPlot=math.max(maxPlot,count)
		assert(plot.Displays:FindFirstChild("Slot"..((page-1)*5+1)),"Display page lost a slot")
	end
	validate(plot.Model)
	plot.Model:Destroy()
end
validate(root)
print(string.format("Headless visual checks passed: hub %d, worst plot + transient drop %d, largest toilet %d, largest item %d; all tiers/items and all 100 display slots",hubCount,maxPlot,maxToilet,maxItem))
'@
try {
    [System.IO.File]::WriteAllText($generatedPath, $harness, [System.Text.UTF8Encoding]::new($false))
    & luau $generatedPath
    if ($LASTEXITCODE -ne 0) { throw 'Headless visual construction checks failed' }
} finally {
    # The fixed generated file is inside the resolved workspace; no recursive cleanup.
    if (Test-Path -LiteralPath $generatedPath) { Remove-Item -LiteralPath $generatedPath }
}
