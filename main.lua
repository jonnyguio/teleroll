--[[

    Created by: João Guio
    Date:       14/11/2017

    https://github.com/jonnyguio/telegram-bot-api
    See MIT license regarding usage of code below.

]]--

telegramAPI = require 'telegram.api'
requests = require 'requests'

bot = telegramAPI.new(os.getenv("TELEROLL_TOKEN"), "url_query")

random_org_url = "https://api.random.org/json-rpc/1/invoke"
update_file_path = "./lastUpdate.txt"

function urlencode(str)
    if (str) then
       str = string.gsub (str, "\n", "\r\n")
       str = string.gsub (str, "([^%w ])",
          function (c) return string.format ("%%%02X", string.byte(c)) end)
       str = string.gsub (str, " ", "+")
    end
    return str    
end

updateFile = io.open(update_file_path, "r")
offset = (updateFile:read("*number") or 0) + 1
lastUpdate = offset - 1
updateFile:close()

_, updates = bot:getUpdates({["offset"] = offset})
if updates ~= nil then
    for k, update in pairs(updates["result"]) do
        messageText = update["message"]["text"] 
        if messageText:find("/roll") then
            print(messageText)
            times, dice, sign, sum = string.match(messageText, "/roll[@.* ]? (%d*)d(%d+)([+-]?)(%d*)")
            if dice ~= nil then
                times = tonumber(times) or 1
                times = times >> 0 -- forcing integer
                dice = tonumber(dice) >> 0 -- forcing integer
                sum = (tonumber(sum) or 0) >> 0 -- forcing integer
                if sign == "-" then
                    sum = sum * -1
                end
                print(times, dice)

                math.randomseed(os.time())
                random_org_json = {
                    ["jsonrpc"] = "2.0", 
                    ["method"] = "generateIntegers", 
                    ["params"] = {
                        ["apiKey"] = "fab223d8-8dd9-40b3-9405-9d1dca6da05e",
                        ["n"] = times,
                        ["min"] = 1, 
                        ["max"] = dice, 
                        ["replacement"] = true, 
                        ["base"] = 10},
                    ["id"] = math.random(1, 9999)
                }
                res = requests.get({url = random_org_url, data = random_org_json, headers= { ["Content-Type"] = "application/json"}})
                final = 0
                rollText = ""
                random_result = res.json()
                for k, v in pairs(random_result["result"]["random"]["data"]) do
                    final = final + (tonumber(v) >> 0)
                    print(k, #random_result["result"]["random"]["data"] - 1)
                    if k ~= #random_result["result"]["random"]["data"] then
                        rollText = rollText .. (tonumber(v) >> 0) .. ", " -- forcing integer
                    else
                        rollText = rollText .. (tonumber(v) >> 0) -- forcing integer
                    end
                end
                if sum ~= 0 then
                    final = final + sum
                    rollText = rollText .. ", ["
                    if sum > 0 then
                        rollText = rollText .. "+"
                    end
                    rollText = rollText .. sum .. "]"
                end
                io.write("Rolagem: " .. times .. "d" .. dice .. "\n" .. final .. "\t(" .. rollText .. ")\n")
                print(update["message"]["chat"]["id"])
                bot:sendMessage(update["message"]["chat"]["id"], urlencode("Rolagem: " .. times .. "d" .. dice .. "\n" .. final .. "\t(" .. rollText .. ")"))
            end
        end
        if tonumber(update["update_id"]) > lastUpdate then
            lastUpdate = tonumber(update["update_id"])
        end
    end
    updateFile = io.open(update_file_path, "w")
    updateFile:write(lastUpdate)
    updateFile:flush()
    updateFile:close()
end

