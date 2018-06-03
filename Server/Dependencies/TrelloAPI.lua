-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Trello API Documentation: 	https://trello.com/docs/																									     --
--								https://developers.trello.com/advanced-reference																			     --
--																																							     --
-- App Key Link: 			 	https://trello.com/app-key																						    			 --
-- Token Link:   			 	https://trello.com/1/connect?name=Trello_API_Module&response_type=token&expires=never&scope=read,write&key=YOUR_APP_KEY_HERE     --
--																																				  				 --
-- Trello API module created by Sceleratis for use in Adonis & EISS. You can use this if you wish; I only ask that you give credit.						  		 --
-- This is currently a work in progress.																										  				 --
-------------------------------------------------------------------------------------------------------------------------------------------------------------------



local http = game:service("HttpService")

function checkHttp()
	local y,n = pcall(function()
		local get = http:GetAsync('http://trello.com')
	end)
	if y and not n then return true else return false end
end

function decode(str)
	return http:JSONDecode(str)
end

function encode(str)
	return http:JSONEncode(str)
end

function urlEncode(str)
	return http:UrlEncode(str)
end

function httpGet(url)
	return http:GetAsync(url,true)
end

function httpPost(url,data,type)
	return http:PostAsync(url,data,type)
end

function trim(str)
	return str:match("^%s*(.-)%s*$")
end

function getListObj(list,name)
	if not name then error("Missing search term") end
	for i,v in pairs(list) do
		if type(name) == "table" then
			for k,n in pairs(name) do
				if trim(v.name):lower()==trim(n):lower() then
					return v
				end
			end
		elseif type(name) == "string" then
			if trim(v.name):lower()==trim(name):lower() then
				return v
			end
		end
	end
end


function Trello(appKey, token)
	if not checkHttp() then
		error("Could not connect to trello.com! Make sure HTTP is enabled.")
	end
	
	local appKey = appKey or ""
	local token = token or ""
	local base = "https://api.trello.com/1/"
	local toks = "key="..appKey.."&token="..token
	
	local api
	api = {
		
		http = http;
		
		getListObj = getListObj;		
		
		checkHttp = checkHttp;
		
		urlEncode = urlEncode;
		
		encode = encode;
		
		decode = decode;
		
		httpGet = httpGet;
		
		httpPost = httpPost;
		
		trim = trim;
		
		epochToHuman = function(epoch)
			return decode(httpGet("http://www.convert-unix-time.com/api?timestamp="..epoch.."&returnType=json&format=iso8601")).utcDate
		end;
		
		getBoard = function(boardId)
			return decode(httpGet(api.getUrl("boards/"..boardId)))
		end;
		
		getLists = function(boardId)
			return decode(httpGet(api.getUrl("boards/"..boardId.."/lists")))
		end;
		
		getList = function(boardId, name)
			local lists = api.getLists(boardId)
			return getListObj(lists,name)
		end;
		
		getCards = function(listId)
			return decode(httpGet(api.getUrl("lists/"..listId.."/cards")))
		end;
		
		getCard = function(listId, name)
			local cards=api.getCards(listId)
			return getListObj(cards,name)
		end;
		
		getComments = function(cardId)
			return decode(httpGet(api.getUrl("cards/"..cardId.."/actions?filter=commentCard")))
		end;
		
		delComment = function(cardId, comId)
			-- No PUT/DELETE :(  (?)
		end;
		
		makeComment = function(cardId, text)
			return decode(httpPost(api.getUrl("cards/"..cardId.."/actions/comments"),"&text="..urlEncode(text),2))
		end;
		
		getCardField = function(cardId,field)
			return decode(httpGet(api.getUrl("cards/"..cardId.."/"..field)))
		end; -- http://prntscr.com/923fmw
		
		getBoardField = function(boardId,field)
			return decode(httpGet(api.getUrl("boards/"..boardId.."/"..field)))
		end; -- http://prntscr.com/923gq3
		
		getListField = function(listId,field)
			return decode(httpGet(api.getUrl("lists/"..listId.."/"..field)))
		end; -- http://prntscr.com/923uyb
		
		getLabel = function(boardId,name)
			local labels = api.getBoardField(boardId,"labels")
			return getListObj(labels,name)
		end;
		
		makeCard = function(listId,name,desc,extra)
			local extra = extra or ""
			return decode(httpPost(api.getUrl("lists/"..listId.."/cards"),"&name="..urlEncode(name).."&desc="..urlEncode(desc)..extra,2))
		end;
		
		makeList = function(boardId,name,extra)
			local extra = extra or ""
			return decode(httpPost(api.getUrl("boards/"..boardId.."/lists"),"&name="..urlEncode(name)..extra,2))
		end;
		
		doAction = function(method,subUrl,data)
			if method:lower()=="post" then
				return decode(httpPost(api.getUrl(subUrl),data,2))
			elseif method:lower()=="get" then
				return decode(httpGet(api.getUrl(subUrl)))
			end
		end;
		
		getUrl = function(str)
			local toks=toks
			if str:find("?") then
				toks="&"..toks
			else
				toks="?"..toks
			end
			return base..str..toks
		end;
	}	
	return api
end

return Trello

																																																												--[[
--_____________________________________________________________________________________________________________________--
--_____________________________________________________________________________________________________________________--																					
--_____________________________________________________________________________________________________________________--
--_____________________________________________________________________________________________________________________--																						
--																					                                   --	

								   ___________              .__  .__          
				 				   \__    ___/______   ____ |  | |  |   ____  
				 				     |    |  \_  __ \_/ __ \|  | |  |  /  _ \ 
				 				     |    |   |  | \/\  ___/|  |_|  |_(  <_> )
				 			  	     |____|   |__|    \___  >____/____/\____/ 
				 		  		                          \/                  
								___________      .__         .___                   
								\_   _____/_____ |__|__  ___ |   | ____   ____      
								 |    __)_\____ \|  \  \/  / |   |/    \_/ ___\     
								 |        \  |_> >  |>    <  |   |   |  \  \___     
								/_______  /   __/|__/__/\_ \ |___|___|  /\___  > /\ 
								        \/|__|            \/          \/     \/  \/
							  --------------------------------------------------------
							  Epix Incorporated. Not Everything is so Black and White.
							  --------------------------------------------------------
						
					 ______  ______  ______  __      ______  ______  ______  ______ __  ______    
					/\  ___\/\  ___\/\  ___\/\ \    /\  ___\/\  == \/\  __ \/\__  _/\ \/\  ___\   
					\ \___  \ \ \___\ \  __\\ \ \___\ \  __\\ \  __<\ \  __ \/_/\ \\ \ \ \___  \  
					 \/\_____\ \_____\ \_____\ \_____\ \_____\ \_\ \_\ \_\ \_\ \ \_\\ \_\/\_____\ 
					  \/_____/\/_____/\/_____/\/_____/\/_____/\/_/ /_/\/_/\/_/  \/_/ \/_/\/_____/ 

--_____________________________________________________________________________________________________________________--
--_____________________________________________________________________________________________________________________--																					
--_____________________________________________________________________________________________________________________--
--_____________________________________________________________________________________________________________________--
--																					                                   --																														  ]]