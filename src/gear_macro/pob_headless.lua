#@
-- This wrapper allows the program to run headless on any OS (in theory)
-- It can be run using a standard lua interpreter, although LuaJIT is preferable


-- Callbacks
local callbackTable = { }
local mainObject
local function runCallback(name, ...)
	if callbackTable[name] then
		return callbackTable[name](...)
	elseif mainObject and mainObject[name] then
		return mainObject[name](mainObject, ...)
	end
end
function SetCallback(name, func)
	callbackTable[name] = func
end
function GetCallback(name)
	return callbackTable[name]
end
function SetMainObject(obj)
	mainObject = obj
end

-- Image Handles
local imageHandleClass = { }
imageHandleClass.__index = imageHandleClass
function NewImageHandle()
	return setmetatable({ }, imageHandleClass)
end
function imageHandleClass:Load(fileName, ...)
	self.valid = true
end
function imageHandleClass:Unload()
	self.valid = false
end
function imageHandleClass:IsValid()
	return self.valid
end
function imageHandleClass:SetLoadingPriority(pri) end
function imageHandleClass:ImageSize()
	return 1, 1
end

-- Rendering
function RenderInit() end
function GetScreenSize()
	return 1920, 1080
end
function SetClearColor(r, g, b, a) end
function SetDrawLayer(layer, subLayer) end
function SetViewport(x, y, width, height) end
function SetDrawColor(r, g, b, a) end
function DrawImage(imgHandle, left, top, width, height, tcLeft, tcTop, tcRight, tcBottom) end
function DrawImageQuad(imageHandle, x1, y1, x2, y2, x3, y3, x4, y4, s1, t1, s2, t2, s3, t3, s4, t4) end
function DrawString(left, top, align, height, font, text) end
function DrawStringWidth(height, font, text)
	return 1
end
function DrawStringCursorIndex(height, font, text, cursorX, cursorY)
	return 0
end
function StripEscapes(text)
	return text:gsub("^%d",""):gsub("^x%x%x%x%x%x%x","")
end
function GetAsyncCount()
	return 0
end

-- Search Handles
function NewFileSearch() end

-- General Functions
function SetWindowTitle(title) end
function GetCursorPos()
	return 0, 0
end
function SetCursorPos(x, y) end
function ShowCursor(doShow) end
function IsKeyDown(keyName) end
function Copy(text) end
function Paste() end
function Deflate(data)
	-- TODO: Might need this
	return ""
end
function Inflate(data)
	-- TODO: And this
	return ""
end
function GetTime()
	return 0
end
function GetScriptPath()
	return ""
end
function GetRuntimePath()
	return ""
end
function GetUserPath()
	return ""
end
function MakeDir(path) end
function RemoveDir(path) end
function SetWorkDir(path) end
function GetWorkDir()
	return ""
end
function LaunchSubScript(scriptText, funcList, subList, ...) end
function AbortSubScript(ssID) end
function IsSubScriptRunning(ssID) end
function LoadModule(fileName, ...)
	if not fileName:match("%.lua") then
		fileName = fileName .. ".lua"
	end
	local func, err = loadfile(fileName)
	if func then
		return func(...)
	else
		error("LoadModule() error loading '"..fileName.."': "..err)
	end
end
function PLoadModule(fileName, ...)
	if not fileName:match("%.lua") then
		fileName = fileName .. ".lua"
	end
	local func, err = loadfile(fileName)
	if func then
		return PCall(func, ...)
	else
		error("PLoadModule() error loading '"..fileName.."': "..err)
	end
end
function PCall(func, ...)
	local ret = { pcall(func, ...) }
	if ret[1] then
		table.remove(ret, 1)
		return nil, unpack(ret)
	else
		return ret[2]
	end	
end
function ConPrintf(fmt, ...)
	-- Optional
	--print(string.format(fmt, ...))
end
function ConPrintTable(tbl, noRecurse) end
function ConExecute(cmd) end
function ConClear() end
function SpawnProcess(cmdName, args) end
function OpenURL(url) end
function SetProfiling(isEnabled) end
function Restart() end
function Exit() end

dofile("Launch.lua")

runCallback("OnInit")
runCallback("OnFrame") -- Need at least one frame for everything to initialise

if mainObject.promptMsg then
	-- Something went wrong during startup
	print(mainObject.promptMsg)
	io.read("*l")
	return
end

-- The build module; once a build is loaded, you can find all the good stuff in here
local build = mainObject.main.modes["BUILD"]

-- Here's some helpful helper functions to help you get started
local function newBuild()
	mainObject.main:SetMode("BUILD", false, "Help, I'm stuck in Path of Building!")
	runCallback("OnFrame")
end
local function loadBuildFromXML(xmlText)
	mainObject.main:SetMode("BUILD", false, "", xmlText)
	runCallback("OnFrame")
end
local function loadBuildFromJSON(getItemsJSON, getPassiveSkillsJSON)
	mainObject.main:SetMode("BUILD", false, "")
	runCallback("OnFrame")
	local charData = build.importTab:ImportItemsAndSkills(getItemsJSON)
	build.importTab:ImportPassiveTreeAndJewels(getPassiveSkillsJSON, charData)
	-- You now have a build without a correct main skill selected, or any configuration options set
	-- Good luck!
end


-- ############################################################################################################

function parseJson(json)
	local func, errMsg = loadstring("return "..jsonToLua(json))
	if errMsg then
		return nil, errMsg
	end
	setfenv(func, { }) -- Sandbox the function just in case
	local data = func()
	if type(data) ~= "table" then
		return nil, "Return type is not a table"
	end
	return data
end

function downloadPage(url)
	-- Download the given page in the background, and calls the provided callback function when done:
	-- callback(pageText, errMsg)
	local curl = require("lcurl.safe")
	local page = ""
	local easy = curl.easy()
	easy:setopt_url(url)
	easy:setopt(curl.OPT_USERAGENT, "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36 Edg/87.0.664.66")
	easy:setopt(curl.OPT_ACCEPT_ENCODING, "")

	easy:setopt_writefunction(function(data)
		page = page..data
		return true
	end)
	local _, error = easy:perform()
	local code = easy:getinfo(curl.INFO_RESPONSE_CODE)
	easy:close()
	local errMsg
	if error then
		errMsg = error:msg()
	elseif code ~= 200 then
		errMsg = "Response code: "..code
	elseif #page == 0 then
		errMsg = "No data returned"
	end
	if errMsg then
		return nil, errMsg
	else
		return page
	end
end

local function downloadPassiveSkills(accountName, characterName, realmCode)
	return downloadPage("https://www.pathofexile.com/character-window/get-passive-skills?accountName="..accountName.."&character="..characterName.."&realm="..realmCode)
end

local function downloadItems(accountName, characterName, realmCode)
	return downloadPage("https://www.pathofexile.com/character-window/get-items?accountName="..accountName.."&character="..characterName.."&realm="..realmCode)
end

local function fetchCharacter(accountName, characterName, realmCode)
	print("Downloading passives and skills")
	local passivesSkillsJson = downloadPassiveSkills(accountName, characterName, realmCode)

	print("Downloading items")
	local itemsJson = downloadItems(accountName, characterName, realmCode)

	print("Parsing build")
	loadBuildFromJSON(itemsJson, passivesSkillsJson)
	print("Done")
end

print("Starting server")

local socket = require("lua\\ljsocket")
local host = "localhost"
local port = 13678

local info = assert(socket.find_first_address("*", port, {
	family = "inet",
	type = "stream",
	protocol = "tcp",
	flags = {"passive"}, -- fill in ip
}))

-- Create a SOCKET for connecting to server
local server = assert(socket.create(info.family, info.socket_type, info.protocol))
server:set_option("reuseaddr", 1)

assert(server:bind(info))
assert(server:listen())

local content = "hello from server"
while true do
	local client, err = server:accept()

	if client then
		assert(client:send(content))
		print("client connected ", client)
		local str, err = client:receive()
		if str then
			local parsedMessage = parseJson(str)

			if parsedMessage.type == "AddItem" then
				print("[Received]" .. parsedMessage.payload.name .. " " .. parsedMessage.payload.rarity)
			elseif parsedMessage.type == "FetchCharacter" then
				fetchCharacter(parsedMessage.payload.accountName, parsedMessage.payload.characterName, "pc")
			elseif parsedMessage.type == "Exit" then
				break
			else
				print("Invalid type" .. parsedMessage.type)
			end

			client:close()
		elseif err == "closed" then
			client:close()
		end
	end
end

-- ############################################################################################################
-- Probably optional
runCallback("OnExit")