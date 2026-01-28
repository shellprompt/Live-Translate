local HttpService: HttpService = game:GetService("HttpService")
local CoreGui: CoreGui = game:GetService("CoreGui")
local RunService: RunService = game:GetService("RunService")
local TextChatService: TextChatService = game:GetService("TextChatService")
local Players: Players = game:GetService("Players")

local localPlayer = game.Players.LocalPlayer
-- [[ THESE MAY CHANGE IN THE FUTURE. CREATE AN ISSUE IF IT HAS ]] --
local ChatContainer: Frame = CoreGui.ExperienceChat.appLayout.chatWindow.scrollingView.bottomLockedScrollView.RCTScrollView.RCTScrollContentView
local BubbleChatContainer: Frame = CoreGui.ExperienceChat.bubbleChat

-- [[ DOCUMENTATION: https://ftapi.pythonanywhere.com/ ]] --
local base_url: string = "https://ftapi.pythonanywhere.com"

-- [[ FOR EXPERIENCE CHAT, PRESERVING RICH TEXT ]] --
local function splitRichText(original: string)
    local prefix, message = original:match("^(.*</font>%s*)(.*)$")
    return prefix, message
end

local function SendChatMessage(message)
    local textChannel = TextChatService.TextChannels.RBXGeneral
    textChannel:SendAsync(message)
end 

local translatedCache = {}

local function translateMessage(text: string): string
    local url: string = string.format("%s/translate?dl=en&text=%s", base_url, text)

    local resp = request({
        Url = url,
        Method = "GET",
    })

    local body: string = resp.Body

    if translatedCache[text] then
        return translatedCache[text]
    end

    -- [[ JSON RESPONSE CLEANING. REQUIRED ]] --
    if body:sub(1,3) == "\239\187\191" then
        body = body:sub(4)
    end

    body = body:gsub("^%s+", ""):gsub("%s+$", "")
    ----------------------------------

    local success, result = pcall(function()
        return game:GetService("HttpService"):JSONDecode(body)
    end)

    if not success then
        warn("Parsing Failed.")
        return text
    end

    if result['source-language'] == result['destination-language'] then
        return text
    else
        -- [[ E.G. "[DE] what's up" ]] --
        translatedCache[text] = string.format("[%s] %s", string.upper(result['source-language']), result['destination-text'])
        
        task.delay(15, function()
            translatedCache[text] = nil
        end)

        return string.format("[%s] %s", string.upper(result['source-language']), result['destination-text'])
    end
end


local function translateCommand(text: string, target_lang: string): string
    if not target_lang or not text then return end

    local url: string = string.format("%s/translate?sl=auto&dl=%s&text=%s", base_url, target_lang, text)

    local resp = request({
        Url = url,
        Method = "GET",
    })

    local body: string = resp.Body

    if translatedCache[text] then
        return translatedCache[text]
    end

    -- [[ JSON RESPONSE CLEANING. REQUIRED ]] --
    if body:sub(1,3) == "\239\187\191" then
        body = body:sub(4)
    end

    body = body:gsub("^%s+", ""):gsub("%s+$", "")
    ----------------------------------

    local success, result = pcall(function()
        return game:GetService("HttpService"):JSONDecode(body)
    end)

    if not success then
        warn("Parsing Failed.")
        return text
    end

    return result['destination-text']
end

ChatContainer.ChildAdded:Connect(function(frame)
    if not frame:IsA("Frame") then return end
    if not frame.TextMessage:WaitForChild("PrefixText", 1) then return end

    local body: TextLabel = frame:WaitForChild("TextMessage", 1) and frame.TextMessage:WaitForChild("BodyText", 1)

    if not body then return end

    local original: string = body.Text

    local prefix, msg = splitRichText(original)
    if not prefix or not msg then return end

    body.Text = prefix

    task.spawn(function()
        local translated: string = translateMessage(msg)
        if not translated then return end

        body.Text = prefix .. translated
    end)
end)

BubbleChatContainer.DescendantAdded:Connect(function(frame: Frame)
    if frame.Name ~= "ChatBubbleFrame" then
        return
    end

    local billboard: BillboardGui = frame:FindFirstAncestorOfClass("BillboardGui")
    if not billboard then
        return
    end 

    if not string.match(billboard.Name, "^BubbleChat_%d+$") then
        if not billboard.Adornee then return end
        local plr: Player = Players:GetPlayerFromCharacter(billboard.Adornee.Parent)
        if plr then
            frame.Parent.Parent = BubbleChatContainer:FindFirstChild(string.format("BubbleChat_%s", tostring(plr.UserId))):FindFirstChild("BubbleChatList")
        end
        return
    end

    local msg: string = frame:FindFirstChild("Text").Text

    task.spawn(function()
        local translated: string = translateMessage(msg)
        if not translated or msg == translated then return end
        local textLabel: TextLabel = frame:FindFirstChild("Text")
        if not textLabel then return end

        
        TextChatService:DisplayBubble(billboard.Adornee, translated)
        frame.Parent:Destroy()
    end)
end)

localPlayer.Chatted:Connect(function(message: string)
    local args: {string} = string.split(message:lower(), " ")

    if args[1] == "/e" and args[2] == "translate" then
        local target_lang: string = args[3]
        if not target_lang then return end
        
        local text = table.concat(args, " ", 4)

        if text == "" then return end
        TextChatService.TextChannels.RBXGeneral:DisplaySystemMessage(string.format("Translating message: %s", text))

        local translated: string = translateCommand(text, target_lang)

        TextChatService.TextChannels.RBXGeneral:DisplaySystemMessage(string.format("Translated message: %s", translated))

        SendChatMessage(translated)
    end
end)
