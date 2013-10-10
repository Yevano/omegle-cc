--@import me.yevano.omegle.OmegleSession
--@import see.net.Http
--@import see.io.Terminal
--@import see.util.Color

function OmegleClient.main(args)
    local session = OmegleSession.new(args:unpack())
    local connected = true
    local typing = false

    if Terminal.isColor() then
        Terminal.setFG(Color.PURPLE)
    end

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

    while connected do
        local event = Events.pull("key", "char", "http_success")

        if event.ident == "key" then
            local k = event.key
            if k == 28 then
                session:send(sendString)
                if Terminal.isColor() then
                    Terminal.setFG(Color.BLUE)
                    System.write("You: ")
                    Terminal.setFG(Color.YELLOW)
                else
                    System.write("You: ")
                end
                System.print(sendString)
                sendString = String.new()
                drawInput(typing, sendString)
            elseif k == 14 then
                if sendString:length() ~= 0 then
                    sendString:remove(-1, 1)
                    drawInput(typing, sendString)
                end
            elseif k == 157 then
                connected = false
                session:disconnect()
                if Terminal.isColor() then
                    Terminal.setFG(Color.PURPLE)
                end
                System.print("You have disconnected.")
            end
        elseif event.ident == "char" then
            local c = event.char
            sendString:add(c)
            drawInput(typing, sendString)
        elseif event.ident == "http_success" then
            local omegleEvent = session:extractEvent(event.response.body)
            if omegleEvent then
                if omegleEvent.type == OmegleSession.EVENT_MESSAGE then
                    Terminal.clearLine()
                    if Terminal.isColor() then
                        Terminal.setFG(Color.RED)
                        System.write("Stranger: ")
                        Terminal.setFG(Color.YELLOW)
                    else
                        System.write("Stranger: ")
                    end
                    System.print(omegleEvent.message)
                    drawInput(typing, sendString)
                elseif omegleEvent.type == OmegleSession.EVENT_TYPING then
                    typing = not typing
                elseif omegleEvent.type == OmegleSession.EVENT_DISCONNECTED then
                    if Terminal.isColor() then
                        Terminal.setFG(Color.PURPLE)
                    end
                    System.print("Stranger disconnected.")
                    connected = false
                    return
                end
            end
            session:requestEvent()
        end
    end
end

function drawInput(typing, message)
    if Terminal.isColor() then
        Terminal.setFG(Color.WHITE)
    end

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