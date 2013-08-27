--@import see.net.Http
--@import see.net.Url
--@import see.io.IOException

function OmegleSession.__static()
    OMEGLE_INDEX = STR"http://omegle.com/"
    OmegleSession.EVENT_DISCONNECTED = STR"strangerDisconnected"
    OmegleSession.EVENT_TYPING = STR"typing"
    OmegleSession.EVENT_MESSAGE = STR"gotMessage"
end

--[[
    Starts a new Omegle session. Blocks until session is established or the connection fails.
    @returns boolean True if found a partner with common interests, or false otherwise.
    @throws IOException If the connection failed.
]]
function OmegleSession:init(...)
    local interests = {...}
    local intString = String.new()

    if #interests > 0 then
        intString:add(STR('%22', interests[1], '%22'))
    end

    for i = 2, #interests do
        intString:add(STR(',%20%22', interests[i], '%22'))
    end

    local response = Http.sync(Url.new(STR(OMEGLE_INDEX, "start", '?firstevents=1&topics=[', intString, ']')))
    if response.responseCode ~= 200 then
        throw(IOException.new(STR("Failed to start session. Response code: ", response.responseCode)))
    end

    local loc = response.body:find("clientID")
    self.id = response.body:sub(loc + 8 + 4, response.body:find('"', loc + 8 + 4) - 1)

    if #interests > 0 then
        response = Http.sync(Url.new(STR(OMEGLE_INDEX, "events")), STR("id=", self.id))
        loc = response.body:find("commonLikes")
        
        if loc then
            self.commonLikes = Array.new()
            local likeString = response.body:sub(loc + 11 + 4, response.body:find("]", loc + 11 + 4) - 1)

            local f = 1
            local g
            repeat
                g = likeString:find('"', f + 1)
                self.commonLikes:add(likeString:sub(f + 1, g - 1))
                f = likeString:find('"', g + 1)
            until not f
        end
    end
end

function OmegleSession:send(message)
    local response = Http.sync(Url.new(STR(OMEGLE_INDEX, "send")), STR("msg=", message, "&id=", self.id))
    if response.responseCode ~= 200 then
        throw(IOException.new(String.new("Failed to send message. Response code: ", response.responseCode)))
    end
end

function OmegleSession:disconnect()
    local response = Http.sync(Url.new(STR(OMEGLE_INDEX, "disconnect")), STR("id=", self.id))
    if response.responseCode ~= 200 then
        throw(IOException.new(String.new("Failed to send disconnect message. Response code: ", response.responseCode)))
    end
end

function OmegleSession:requestEvent()
    Http.async(Url.new(STR(OMEGLE_INDEX, "events")), STR("id=", self.id))
end

function OmegleSession:extractEvent(body)
    body = cast(body, String)
    if body:find("strangerDisconnected") then
        return { type = OmegleSession.EVENT_DISCONNECTED }
    elseif body:find("typing") then
        return { type = OmegleSession.EVENT_TYPING }
    elseif body:find("gotMessage") then
        local mStart = body:find("gotMessage")
        local mEnd = mStart + 9
        return { type = OmegleSession.EVENT_MESSAGE, message = body:sub(mEnd + 5, body:find("]", mEnd + 1) - 2) }
    end
end