local HttpService: HttpService = game:GetService("HttpService")
local CoreGui: CoreGui = game:GetService("CoreGui")
local RunService: RunService = game:GetService("RunService")

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
    if frame.Name ~= "ChatBubbleFrame" then return end

    local msg: string = frame:FindFirstChild("Text").Text

    task.spawn(function()
        local translated: string = translateMessage(msg)
        if not translated or msg == translated then return end

        local textLabel = frame:FindFirstChild("Text")
        if not textLabel then return end

        
        -- [[ RESCALING CHAT BUBBLE ]] --
        textLabel.TextWrapped = true
        textLabel.AutomaticSize = Enum.AutomaticSize.None

        local MAX_WIDTH = 320
        local PADDING_X = 28
        local PADDING_Y = 18

        textLabel.Text = translated
        frame.BackgroundColor3 = Color3.fromRGB(226, 208, 255)

        local bounds = textLabel.TextBounds
        frame.Size = UDim2.fromOffset(math.min(bounds.X + PADDING_X, MAX_WIDTH), bounds.Y + PADDING_Y)
    end)

end)
