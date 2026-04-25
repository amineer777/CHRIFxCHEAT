local ESP = loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-ESP-Library-9570", true))("there are cats in your walls let them out let them out let them out")

local Players = game:GetService("Players")

ESP.Settings.TeamBased = false
ESP.Settings.TeamColors = false

local TS = require(game:GetService("ReplicatedStorage").TS)

local function IsHostile(Character)
   local Player = TS.Characters:GetPlayerFromCharacter(Character)
   
   if not Player then return false end
   
   local TeamPlayer = game.Teams:FindFirstChild(Player.Name, true)
   
   return TeamPlayer and TeamPlayer.Parent ~= game.Teams:FindFirstChild(game.Players.LocalPlayer.Name, true).Parent or false
end

ESP:AddListener(workspace.Characters, function(Child) task.wait(1) return IsHostile(Child) end, {
   Descendants = false,
   Type = "Model",
   Custom = {
       Name = "Enemy",
       Settings = {
           Boxes = {
               Color = Color3.new(1, 0, 0)
           },
           Tracers = {
               Color = Color3.new(1, 0, 0)
           }
       }
   }
})
