--@import me.yevano.omegle.OmegleSession
--@import see.hook.Hooks
--@import see.net.Http
--@import see.concurrent.ThreadPool
--@import see.io.Terminal

function OmegleClient.main(args)
    local threadPool = ThreadPool.new()
    local session = OmegleSession.new(args:unpack())
    local connected = true
    local typing = false
    local connectionHook

    if session.commonLikes then
        local intString = String.new()
        if session.commonLikes:length() > 0 then
            intString:add(session.commonLikes[1])
        end
        for i = 2, session.commonLikes:length() do
            intString:add(STR(", ", session.commonLikes[i]))
        end
        System.print(STR("Found partner with common interests: ", intString, "."))
    end

    System.print(STR("Connected to ", session.id))
    session:requestEvent()

    local sendString = String.new()
    connectionHook = Hooks.add("http_success", function(url, handle)
        local event = session:extractEvent(handle.readAll())
        if event then
            if event.type == OmegleSession.EVENT_MESSAGE then
                Terminal.clearLine()
                System.print(STR("Stranger: ", event.message))
                drawInput(typing, sendString)
            elseif event.type == OmegleSession.EVENT_TYPING then
                typing = not typing
            elseif event.type == OmegleSession.EVENT_DISCONNECTED then
                System.print("Stranger disconnected.")
                connected = false
                Hooks.remove(connectionHook)
            end
        end
        session:requestEvent()
    end)

    Hooks.add("char", function(c)
        sendString:add(c)
        drawInput(typing, sendString)
    end)

    Hooks.add("key", function(k)
        if k == 28 then
            session:send(sendString)
            System.print(STR("You: ", sendString))
            sendString = String.new()
            drawInput(typing, sendString)
        elseif k == 14 then
            if sendString:length() == 0 then return end
            sendString:remove(-1, 1)
            drawInput(typing, sendString)
        elseif k == 157 then
            connected = false
            session:disconnect()
            System.print("You have disconnected.")
        end
    end)

    while connected do
        Hooks.run()
    end
end

function drawInput(typing, message)
    local pos = Terminal.getPos()
    local size = Terminal.getSize()
    Terminal.setPos(1, size.y)
    Terminal.write(typing and "T" or " ")
    Terminal.clearLine()
    if message:length() > size.x - 1 then
        Terminal.write(message:sub(-(size.x - 1), -1):lstr())
    else
        Terminal.write(message:lstr())
    end
    Terminal.setPos(pos.x, pos.y)
end