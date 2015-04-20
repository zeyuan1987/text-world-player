-- Layer to create quests and act as middle-man between Evennia and Agent
require 'utils'

local DEFAULT_REWARD = -1

quests = {'You are hungry.', 'You are sleepy.', 'You are bored.', 'You are getting fat.'}
quest_actions = {'eat', 'sleep', 'watch' ,'exercise'}
quest_index = torch.random(1, #quests)

actions = {"eat", "watch", "sleep", "exercise"} -- hard code in
objects = {} -- read from build file

symbols = {}
symbol_mapping = {}

--Function to parse the output of the game (to extract rewards, etc. )
function parse_game_output(text)
	-- extract REWARD if it exists
	-- text is a list of sentences
	local reward = nil
	local text_to_agent = {quests[quest_index]}
	for i=1, #text do
		if string.match(text[i], "REWARD") then
			if string.match(text[i], quest_actions[quest_index]) then
				reward = string.match(text[i], "%d+")
			end
		else
			table.insert(text_to_agent, text[i])
		end

	end
	if not reward then
		reward = DEFAULT_REWARD
	end
	return text_to_agent, reward	
end

-- build game command to send to the game
function build_command(action, object)
	return action .. ' ' ..object
end


function parseLine( list_words, start_index)
	-- parse line to update symbols and symbol_mapping
	local sindx	
	for i=start_index,#list_words do			
		word = split(list_words[i], "%a+")[1]
		word = word:lower()	
		if symbol_mapping[word] == nil then
			sindx = #symbols + 1
			symbols[sindx] = word
			symbol_mapping[word] = sindx
		end
	end
end

-- read in text data from file with sentences (one sentence per line) - nicely tokenized
function makeSymbolMapping(filename)
	local file = io.open(filename, "r");
	local data = {}
	local parts
	for line in file:lines() do
		list_words = split(line, "%S+")
		if list_words[1] == '@detail' or list_words[1] == '@desc' then
			parseLine(list_words, 4)
		elseif list_words[1] == '@create/drop' then
			-- add to actionable objects			
			table.insert(objects, split(list_words[2], "%a+")[1])
		end
	end
end
