Radio = {}
Radio.songQueue = {}
Radio.maxQueue = 10
Radio.timer = nil
Radio.streamData = {}
Radio.isStreaming = false
Radio.buyLock = {}
Radio.songDownloading = nil
Radio.artists = { 
	'Ed Sheeran - Perfect (Official Music Video)', 'Sam Smith - Too Good At Goodbyes (Official Video)', 'Camila Cabello - Havana ft. Young Thug',
	'Rita Ora - Anywhere (Official Video)', 'ZAYN - Dusk Till Dawn ft. Sia', 'Taylor Swift - Look What You Made Me Do', 'Eminem - River (Audio) ft. Ed Sheeran',
	'Migos, Nicki Minaj, Cardi B - MotorSport (Official)', 'Charlie Puth - "How Long" [Official Video]', 'Stefflon Don, French Montana - Hurtin Me (Official Video)',
	'Not3s - My Lover (Official Video)', 'J Hus - Bouff Daddy (Official Video)', 'Lil Pump - "Gucci Gang" (Official Music Video)',
	'Clean Bandit - I Miss You feat. Julia Michaels [Official Video]', 'G-Eazy & Halsey - Him & I (Official Video)', 'Avicii - Lonely Together ft. Rita Ora',
	'Dua Lipa - New Rules (Official Music Video)', 'Dappy - Trill (Prod by B.O Beatz) [Official Video]', 'Luis Fonsi, Demi Lovato - Échame La Culpa',
	'Bebe Rexha - Meant to Be (feat. Florida Georgia Line) [Official Music Video]', 'Katy Perry - Swish Swish (Official) ft. Nicki Minaj',
	'Giggs - Linguo feat. Donaeo (Official Video)', 'Sia - Santas Coming For Us', 'Jaykae - Moscow (Music Video) - Prod. Bowzer Boss',
	'Maroon 5 - What Lovers Do ft. SZA', 'Jason Derulo - Tip Toe feat French Montana (Official Music Video)', 'Joyner Lucas - Im Not Racist',
	'Krept & Konan - Get A Stack (Official Video) ft. J Hus', 'P!nk - Beautiful Trauma (Official Video)', 'Craig David - I Know You (Audio) ft. Bastille',
	'N.E.R.D & Rihanna - Lemon', 'James Arthur - Naked', 'Jaden Smith - Icon', 'Logic - 1-800-273-8255 ft. Alessia Cara, Khalid',
	'DJ Khaled - Wild Thoughts ft. Rihanna, Bryson Tiller', 'Imagine Dragons - Whatever It Takes', 'Wretch 32 - Tell Me ft. Kojo Funds, Jahlani',
	'Machine Gun Kelly, X Ambassadors & Bebe Rexha - Home (from Bright: The Album) [Music Video]', 'DJ Snake, Lauv - A Different Way',
	'Kygo - Stargazing ft. Justin Jesso', 'Mabel - Finders Keepers (Official Video) ft. Kojo Funds', 'Demi Lovato - Tell Me You Love Me',
	'Lil Uzi Vert - The Way Life Goes Remix (Feat. Nicki Minaj) [Official Music Video]', 'Davido - FIA (Official Video)', 'MK - 17 (Lyric Video)',
	'Skrapz - High Spec ft Chip (Official Video)', 'CNCO, Little Mix - Reggaetón Lento (Remix) [Official Video]', 'Flo Rida feat Maluma - Hola (Official Video)',
	'Maluma - Corazón (Official Video) ft. Nego do Borel', 'NF - Let You Down', 'Jax Jones - Breathe (Visualiser) ft. Ina Wroldsen',
	'Khalid - Young Dumb & Broke (Official Video)', 'Calvin Harris - Feels (Official Video) ft. Pharrell Williams, Katy Perry, Big Sean',
	'Guru Randhawa: Lahore (Official Video) Bhushan Kumar | Vee | DirectorGifty | T-Series', 'Tory Lanez - Shooters'
}

function Radio.main()
	Radio.randomSong()
end
addEventHandler ("onResourceStart", resourceRoot, Radio.main)

function getCleanPlayerName(p)
    return string.gsub(getPlayerName(p), '#%x%x%x%x%x%x', '')
end

function Radio.downloadCallback(data, error)
	if not Radio.songDownloading.data or not Radio.songQueue[1].data then
		Radio.randomSong()
	end

	if Radio.songDownloading.data.title ~= Radio.songQueue[1].data.title then return end
	--[[ triggerClientEvent(root, "onDownloadFinished", root) ]]
	triggerClientEvent(root, "onClientRadioSongStart", root, Radio.songQueue[1].data, Radio.songQueue[1].player)
	outputConsole(Radio.songQueue[1].data.duration * 1000)
	Radio.timer = setTimer(Radio.handleSongEnd, (Radio.songQueue[1].data.duration * 1000) + 2000, 1)
	Radio.reset()
end

function Radio.downloadSong()
	Radio.songDownloading = Radio.songQueue[1]
	--[[ outputChatBox("#FF6464[RADIO] #ffffffDownloading song, please wait!", root, 255, 255, 255, true) ]]
	fetchRemote(Radio.songQueue[1].data.streamUrl, Radio.downloadCallback, "", false)
end

function Radio.searchCallback(data, error, player)
	data = "["..data.."]"
	local response = fromJSON(data)
  
	triggerClientEvent(player, "onClientRadioSearchResult", player, response)
end

function Radio.search(value)
	fetchRemote("http://localhost:3000/search?q="..(value:gsub(" ","%%20")), Radio.searchCallback, "", false, client)
end
addEvent("onRadioSongSearch", true)
addEventHandler("onRadioSongSearch", root, Radio.search)

function Radio.randomSongCallback(data, error)
	data = "["..data.."]"
	local response = fromJSON(data)
	local song = response[1]

	if not song or (not song.duration and not song.stream) then 
		outputChatBox("#FF6464[RADIO] #ffffffCurrent song is bugged. Switching to next one.", client, 255, 255, 255, true)
		Radio.randomSong()
	end

	table.insert(Radio.songQueue, {data = song, player = "Server"})
	Radio.downloadSong()
end

function Radio.randomSong()
	local artist = Radio.artists[math.random(#Radio.artists)]
	fetchRemote("http://localhost:3000/search?q="..(artist:gsub(" ","%%20")), Radio.randomSongCallback, "", false)
end

function Radio.handleSongEnd(isSongSkipped, player, stream)
	if isSongSkipped then
		triggerClientEvent(root, "onClientRadioSongEnd", root, isSongSkipped, getCleanPlayerName(player))
	else
		triggerClientEvent(root, "onClientRadioSongEnd", root)
	end
	
	table.remove(Radio.songQueue, 1)

	if stream then return end
	
	if (#Radio.songQueue > 0) then
		if not Radio.songQueue[1].data.duration or not Radio.songQueue[1].data.streamUrl then 
			outputChatBox("#FF6464[RADIO] #ffffffCurrent song is bugged. Switching to next one.", client, 255, 255, 255, true)
			Radio.handleSongEnd()
		end

		Radio.downloadSong()
	else
		Radio.randomSong()
	end
end

function Radio.request(data)
	if Radio.buyLock[client] and getTickCount() - Radio.buyLock[client] < 300000 then
		outputChatBox("You already bought a song recently!", client, 255, 0, 128)
		return
	end
	
	if (#Radio.songQueue >= Radio.maxQueue) then
		outputChatBox("#FF6464[RADIO] #ffffffQueue is full. ("..#Radio.songQueue.."/"..Radio.maxQueue..") Please try again later.", client, 255, 255, 255, true)
		return
	end
	
	if not exports["CCS_stats"]:export_takePlayerMoney(client, 25000) then 
		outputChatBox("Error: You don't have enough money!", client, 255, 0, 128)
		return 
	end

	if data.duration > 360 then
		outputChatBox("Error: The song exceeds the 6 minute length!", client, 255, 0, 128)
		return
	end
	
	Radio.buyLock[client] = getTickCount()

	if Radio.songQueue[1] and Radio.songQueue[1].player == "Server" then
		if isTimer(Radio.timer) then killTimer(Radio.timer) end
		table.remove(Radio.songQueue, 1)
		triggerClientEvent(root, "onClientRadioSongEnd", root)
		table.insert(Radio.songQueue, {data = data, player = getCleanPlayerName(client)})
		outputChatBox("#FF6464[RADIO] #ffffffYour song is in queue position "..#Radio.songQueue.."/"..Radio.maxQueue, client, 255, 255, 255, true)
		Radio.downloadSong()
		return
	end
	
	if #Radio.songQueue == 0 then
		table.insert(Radio.songQueue, {data = data, player = getCleanPlayerName(client)})
		outputChatBox("#FF6464[RADIO] #ffffffYour song is in queue position "..#Radio.songQueue.."/"..Radio.maxQueue, client, 255, 255, 255, true)
		Radio.downloadSong()
	else
		table.insert(Radio.songQueue, {data = data, player = getCleanPlayerName(client)})
		outputChatBox("#FF6464[RADIO] #ffffffYour song is in queue position "..#Radio.songQueue.."/"..Radio.maxQueue, client, 255, 255, 255, true)
	end
end
addEvent("onRadioSongRequest", true)
addEventHandler("onRadioSongRequest", root, Radio.request)

function Radio.skipSong(player)
	if isTimer(Radio.timer) then killTimer(Radio.timer) end
	Radio.handleSongEnd(true, player)
end
addCommandHandler("skipsong", Radio.skipSong)

function Radio.skipYourSong(player) 
	local nickname = getCleanPlayerName(player)
	if Radio.songQueue[1].player == nickname then
		Radio.skipSong(player)
	end
end
addCommandHandler("skipyoursong", Radio.skipYourSong)

function Radio.getSongQueue(player)
	local queue
	
	if (#Radio.songQueue ~= 0) then
		outputChatBox("#FF6464[RADIO] #ffffffSong queue:", player, 255, 255, 255, true)
		for i, song in ipairs(Radio.songQueue) do	
			outputChatBox("#ffffff"..i..". "..song.data.title.." ("..song.player.."#ffffff)", player, 255, 255, 255, true)
		end
	else
		outputChatBox("#FF6464[RADIO] #ffffffSong queue is empty", player, 255, 255, 255, true)
	end
end
addCommandHandler("queue", Radio.getSongQueue)

function Radio.getCurrentSong()
	triggerClientEvent(client, "onClientJoinedRadio", client, Radio.songQueue[1])
end
addEvent("onPlayerJoinRadio", true)
addEventHandler("onPlayerJoinRadio", root, Radio.getCurrentSong)

function Radio.liveStream(link)
	if Radio.isStreaming then
		Radio.handleSongEnd(false)
	else
		Radio.handleSongEnd(false, nil, true)
		triggerClientEvent("onLiveStream", root, link)
	end
end

--[[ addCommandHandler("livedj", Radio.liveStream) ]]

Voteskip = {}
Voteskip.votes = {}
Voteskip.votedPlayers = {}
Voteskip.locked = false

function Radio.reset()
	Voteskip.votes = 0
	Voteskip.votedPlayers = {}
	Voteskip.locked = false
end

function Radio.voteSkip(player, c)
	local players = getElementsByType("player") 
	local playerName = getCleanPlayerName(player)
	local percentNeeded = 0.50

	if Voteskip.locked then return end

	if not Radio.songQueue[1] then return end

	if Voteskip.votedPlayers[getPlayerSerial(player)] then return end

	Voteskip.votes = Voteskip.votes + 1
	Voteskip.votedPlayers[getPlayerSerial(player)] = true

	local missing = math.ceil((#players * percentNeeded)) - Voteskip.votes
	missing = math.max(missing, 0)

	outputChatBox("#FF6464[RADIO] #ffffff"..playerName.." #ffffffused /voteskip ("..missing.." votes missing)", root, 255, 255, 255, true)

	if missing == 0 then
		Voteskip.locked = true
		outputChatBox("#FF6464[RADIO] #ffffffVoteskip passed", root, 255, 255, 255, true)
		if isTimer(Radio.timer) then killTimer(Radio.timer) end
		Radio.handleSongEnd()
	end

end
addCommandHandler("voteskip", Radio.voteSkip)