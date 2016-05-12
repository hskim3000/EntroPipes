--[[
	EntroPipes r4
	© 2015 - 2016 Alfonso Saavedra "Son Link"
	Under the GNU/GPL 3 license
	http://github.com/son-link/EntroPipes
	http://son-link.github.io
]]

-- Weight and heigth of the puzzle
W = 8
H = 6

-- Inicial posotion of the pipe 
initX = 32
initY = 8

limitX = 0

gameState = 0 -- 0: Main screen, 1: playing, 2: the puzzle is resolve, 3: Game Over, 4 show Top score, 5 paused, 6 select grid size
ifWin = true -- For check if the player complete the puzzle


puzzles = {} -- table whit the puzzles
newPipe = {} -- This table contain the actual puzzle
numPuzzle = 1 -- count for change actual puzzle for the next is the actual is resolve
puzzle = ''

math.randomseed(os.time()) -- Need for randomize
timeLimit = 120 -- Time limit on start game (2 minutes)
totalTime = 0
score = 0
totalScore = 0
scoreText = 'Score:' -- Show the score
scores = {}
totalPuzzles = 0

defaultScores = {
	['4x4'] = {1000,800,600,400,200},
	['6x4'] = {1000,800,600,400,200},
	['6x6'] = {1000,800,600,400,200},
	['8x6'] = {1000,800,600,400,200}
}

require 'table_save'
scores = table.load('scores')

local CScreen = require "cscreen"
local scaleProportion = 1
local tx = 0
local ty = 0
local fsv = 1

if not scores and (love.filesystem.exists and not love.filesystem.exists('scores')) then
	table.save(defaultScores, 'scores')
	scores = defaultScores
end

 -- the background image
local bg

function love.load()
	windowWidth = 320
    windowHeight = 240
	love.window.setMode(windowWidth, windowHeight, {resizable=true, centered=true})
	love.window.setTitle("EntroPipes")
	love.window.setIcon(love.image.newImageData('icon_small.png'))
	CScreen.init(320,240, true)
	CScreen.setColor(155,188,15,255)
	
	-- Filter for scale
	love.graphics.setDefaultFilter('nearest', 'nearest')
	
	-- Change the scale game on Android
	if love.system.getOS() == "Android" then
		local x,y = love.graphics.getDimensions()
		love.window.setMode(x, y)
		love.resize(x,y)
	end
    
	-- set font
	font = love.graphics.newFont("PixelOperator8.ttf", 12)
	love.graphics.setFont(font)	

	--preload images for the pipes
	pipes = {
		['pipe_0'] = love.graphics.newImage("img/0.png"),
		['pipe_1'] = love.graphics.newImage("img/1.png"),
		['pipe_2'] = love.graphics.newImage("img/2.png"),
		['pipe_3'] = love.graphics.newImage("img/3.png"),
		['pipe_4'] = love.graphics.newImage("img/4.png"),
		['pipe_5'] = love.graphics.newImage("img/5.png"),
		['pipe_6'] = love.graphics.newImage("img/6.png"),
		['pipe_7'] = love.graphics.newImage("img/7.png"),
		['pipe_8'] = love.graphics.newImage("img/8.png"),
		['pipe_9'] = love.graphics.newImage("img/9.png"),
		['pipe_A'] = love.graphics.newImage("img/A.png"),
		['pipe_B'] = love.graphics.newImage("img/B.png"),
		['pipe_C'] = love.graphics.newImage("img/C.png"),
		['pipe_D'] = love.graphics.newImage("img/D.png"),
		['pipe_E'] = love.graphics.newImage("img/E.png"),
		['pipe_F'] = love.graphics.newImage("img/F.png")
	}
	
	-- Background image and dialogs
	mainBG = love.graphics.newImage("img/main_screen.png")
	gameBG = love.graphics.newImage("img/bg.png")
	win_dialog = love.graphics.newImage("img/win_dialog.png")
	top_score_bg = love.graphics.newImage("img/top_score_bg.png")
	gameMode = love.graphics.newImage("img/select_grid_size.png")
	pause_button = love.graphics.newImage("img/pause_button.png")
	
	-- set default background
	bg = mainBG
end

function love.update(dt)
	if gameState == 1 then
		bg = gameBG
		TimerCount(dt)
	end
end

function love.draw()
	CScreen.apply()
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(bg, 0, 0)
	if gameState == 1 then
		bg = gameBG
		CScreen.setColor(15,56,15,255)
		-- print the pipes
		for y = 0, H -1 do
			for x = 0, W -1 do
				piece = newPipe[y*W+x]
				img = pipes['pipe_'..piece.value]
				love.graphics.draw(img, piece.x, piece.y)

			end
		end
		
		love.graphics.setColor(139, 172, 15, 255)
		love.graphics.print("Time: "..math.ceil(timeLimit), 32, 216)
		love.graphics.print("Score: "..totalScore, 136, 216)
	elseif gameState == 2 then
		-- Puzzle complete
		love.graphics.draw(win_dialog, 80, 40)
		love.graphics.setColor(139, 172, 15, 255)
		love.graphics.printf("Complete!", 0, 56, 320, 'center')
		love.graphics.printf("Time: "..math.ceil(timeLimit-30), 0, 80, 320, 'center')
		love.graphics.printf("Score: "..score, 0, 96, 320, 'center')
		love.graphics.printf("Press screen", 0, 128, 320, 'center')
		love.graphics.printf("to continue.", 0, 144, 320, 'center')
	elseif gameState == 3 then
		-- Time over
		love.graphics.draw(win_dialog, 80, 40)
		love.graphics.setColor(139, 172, 15, 255)
		love.graphics.printf("GAME OVER!", 0, 56, 320, 'center')
		love.graphics.printf("Score: "..totalScore, 0, 80, 320, 'center')
		love.graphics.printf("Resolved: "..totalPuzzles, 0, 96, 320, 'center')
		love.graphics.printf("Press screen", 0, 128, 320, 'center')
		love.graphics.printf("to continue.", 0, 144, 320, 'center')
	elseif gameState == 4 then
		-- Show the top 5 scores
		love.graphics.draw(top_score_bg, 80, 32)
		love.graphics.setColor(139, 172, 15, 255)
		love.graphics.printf("Top score", 0, 48, 320, 'center')
		posY = 64
		scores2 = scores[W..'x'..H]
		for i = 1, 5 do
			if tonumber(scores2[i]) == totalScore then
				love.graphics.setColor(48, 98, 48, 255)
				love.graphics.print(i..". "..scores2[i], 120, posY)
			else
				love.graphics.setColor(139, 172, 15, 255)
				love.graphics.print(i..". "..scores2[i], 120, posY)
			end
			posY = posY + 12
		end
		love.graphics.printf("Press screen", 0, 136, 320, 'center')
		love.graphics.printf("to continue.", 0, 152, 320, 'center')
	elseif gameState == 5 then
		-- Game paused
		love.graphics.draw(win_dialog, 80, 40)
		love.graphics.setColor(139, 172, 15, 255)
		love.graphics.printf("PAUSE", 0, 56, 320, 'center')
		love.graphics.draw(pause_button, 104, 80)
		love.graphics.printf("Continue", 0, 88, 320, 'center')
		love.graphics.draw(pause_button, 104, 120)
		love.graphics.printf("Exit", 0, 128, 320, 'center')
	elseif gameState == 6 then
		-- Select grid size
		love.graphics.draw(gameMode, 80, 40)
	else
		CScreen.setColor(155,188,15,255)
		bg = mainBG
	end
	CScreen.cease()
end

function genPuzzle()
	-- this function generate the puzzle
	puzzle = puzzles[numPuzzle]
	posX = initX
	posY = initY
	for i = 1, (W*H) do
		value = string.sub(puzzle,i,i)
		newPipe[i-1] = {value = value, img = pipes['pipe_'..value],x = posX, y = posY}
		if posX == limitX then
			posX = initX
			posY = posY + 32
		else
			posX = posX + 32
		end
	end
	randPipes()
end

function love.keypressed(key)
	if key == "escape" then
		if gameState == 1 then
			gameState = 5
		elseif gameState > 3 then
			love.event.quit()
		end
	end
end

function love.mousepressed(posx, posy, button)
	if gameState == 0 then
		gameState = 6
	elseif gameState == 2 then
		genPuzzle()
	elseif gameState == 3 then
		saveScore()
	elseif gameState == 4 then
		timeLimit = 180
		totalTime = 0
		totalScore = 0
		totalPuzzles = 0
		gameState = 0
		
	elseif gameState == 5 then
		if posx >= calcx(104) and posx <= calcx(216) and posy >= calcy(80) and posy <= calcy(104) then
			gameState = 1
		elseif posx >= calcx(104) and posx <= calcx(216) and posy >= calcy(120) and posy <= calcy(144) then
			love.event.quit()
		end
	elseif gameState == 6 then
		puzzles = {}
		numPuzzle = 1
		if posx >= calcx(104) and posx <= calcx(144) and posy >= calcy(80) and posy <= calcy(104) then
			W = 4
			H = 4
			initX = 94
			initY = 40
			limitX = 190
			appendFileLines('puzzles/4x4.txt', puzzles)
			shuffle(puzzles)
			gameState = 1
			genPuzzle()
		elseif posx >= calcx(104) and posx <= calcx(144) and posy >= calcy(120) and posy <= calcy(144) then
			W = 6
			H = 4
			initX = 64
			initY = 40
			limitX = 224
			appendFileLines('puzzles/6x4.txt', puzzles)
			shuffle(puzzles)
			gameState = 1
			genPuzzle()
		elseif posx >= calcx(176) and posx <= calcx(216) and posy >= calcy(80) and posy <= calcy(104) then
			W = 6
			H = 6
			initX = 64
			initY = 8
			limitX = 224
			appendFileLines('puzzles/6x6.txt', puzzles)
			shuffle(puzzles)
			gameState = 1
			genPuzzle()
		elseif posx >= calcx(176) and posx <= calcx(216) and posy >= calcy(120) and posy <= calcy(144) then
			W = 8
			H = 6
			initX = 32
			initY = 8
			limitX = 256
			appendFileLines('puzzles/8x6.txt', puzzles)
			shuffle(puzzles)
			gameState = 1
			genPuzzle()
		end
	elseif gameState == 1 then
		-- walk the pipes array and check wath pipe is pressed
		for y = 0, H-1 do
			for x = 0, W-1 do
				piece = newPipe[y*W+x]
				if posx >= calcx(piece.x) and posx <= calcx(piece.x + 32) and posy >= calcy(piece.y) and posy <= calcy(piece.y + 32) then
					if piece.value ~= 'F' and piece.value ~= 0 then
						if piece.value == 1 then
							newPipe[y*W+x].value = 2
							break
						elseif piece.value == 2 then
							newPipe[y*W+x].value = 4
							break
						elseif piece.value == 3 then
							newPipe[y*W+x].value = 6
							break
						elseif piece.value == 4 then
							newPipe[y*W+x].value = 8
							break
						elseif piece.value == 5 then
							newPipe[y*W+x].value = 'A'
							break
						elseif piece.value == 6 then
							newPipe[y*W+x].value = 'C'
							break
						elseif piece.value == 7 then
							newPipe[y*W+x].value = 'E'
							break
						elseif piece.value == 8 then
							newPipe[y*W+x].value = 1
							break
						elseif piece.value == 9 then
							newPipe[y*W+x].value = 3
							break
						elseif piece.value == 'A' then
							newPipe[y*W+x].value = 5
							break
						elseif piece.value == 'B' then
							newPipe[y*W+x].value = 7
							break
						elseif piece.value == 'C' then
							newPipe[y*W+x].value  = 9
							break
						elseif piece.value == 'D' then
							newPipe[y*W+x].value = 'B'
							break
						elseif piece.value == 'E' then
							newPipe[y*W+x].value = 'D'
							break
						end
					end
				end
			end
		end
		calculateEntropy()
	end
end

function shuffle(t)
	-- Shuflle the table indicated on the parameter
    local rand = math.random 
    assert(t, "table.shuffle() expected a table, got nil")
    local iterations = #t
    local j
    
    for i = iterations, 2, -1 do
        j = rand(i)
        t[i], t[j] = t[j], t[i]
    end
end

function randArray(values)
	-- return a random value from the array indicated
	return (values[math.random(1, #values)])
end

function randPipes()
	-- randomice the pipes
	for y = 0, H-1 do
		for x = 0, W-1 do
			if string.match(newPipe[y*W+x].value,'[369C]') then
				newPipe[y*W+x].value = randArray({3,6,9,'C'})
			elseif string.match(newPipe[y*W+x].value, '[1248]') then
				newPipe[y*W+x].value = randArray({1,2,4,8})
			elseif string.match(newPipe[y*W+x].value, '[7BDE]') then
				newPipe[y*W+x].value = randArray({7,'B','D','E'})
			elseif string.match(newPipe[y*W+x].value,'[5A]') then
				newPipe[y*W+x].value = randArray({5,'A'})
			end
		end
	end
	gameState = 1
end

function calculateEntropy()
	-- Calculate the entropy. If 0 the puzzle is resolve
	entropy = 0;
	entropyLocal = 0
	for y = 0, H-1 do
		for x = 0, W-1 do
			entropyLocal = 0
			if  ( ( checkUp(newPipe[y*W+x].value) ) and ( ( y == 0 ) or ( not checkDown(newPipe[(y-1)*W+x].value) ) ) ) then entropyLocal = entropyLocal + 1 end
			if  ( ( checkDown(newPipe[y*W+x].value) ) and ( ( y == H-1 ) or ( not checkUp(newPipe[(y+1)*W+x].value) ) ) ) then  entropyLocal = entropyLocal + 1 end
			if  ( ( checkRight(newPipe[y*W+x].value) ) and ( ( x == W-1 ) or ( not checkLeft(newPipe[y*W+x+1].value) ) ) ) then  entropyLocal = entropyLocal + 1 end
			if  ( ( checkLeft(newPipe[y*W+x].value) ) and ( ( x == 0 ) or ( not checkRight(newPipe[y*W+x-1].value) ) ) ) then  entropyLocal = entropyLocal + 1 end
			entropy = entropy + entropyLocal;
		end
	end
	if entropy == 0 then
		score = math.ceil(timeLimit) * 10
		totalScore = totalScore + score
		totalTime = totalTime + timeLimit
		timeLimit = timeLimit + 30
		totalPuzzles = totalPuzzles + 1
		if numPuzzle < #puzzles then
			numPuzzle = numPuzzle + 1
			gameState = 2
		else
			saveScore()
		end
	end
end

function checkUp(tile) return (string.match("13579BDF", tile) ) end
function checkDown(tile) return ( string.match("4567CDEF", tile) ) end
function checkRight(tile) return ( string.match("2367ABEF", tile) ) end
function checkLeft(tile) return (string.match("89ABCDEF", tile) ) end

function TimerCount(dt)
	timeLimit = timeLimit - dt
	if timeLimit <= 0 then
		gameState = 3
	end
end

function appendFileLines(file, t)
	-- append lines from the file on the indicated table
	if love.filesystem.lines then
		-- Love
		for line in love.filesystem.lines(file) do
			table.insert(t, line)
		end
	else
		-- LovePotion
		for line in io.lines(file) do
			table.insert(t, line)
		end
	end
end

function saveScore()
	-- Save score
	oldScore = scores[W..'x'..H]
	table.insert(oldScore, totalScore)
	table.sort(oldScore, function(a,b) return tonumber(a) > tonumber(b) end)
	newScores = {}
	for i = 1, 5 do
		table.insert(newScores, oldScore[i])
	end
	scores[W..'x'..H] = newScores
	table.save(scores, 'scores2')
	gameState = 4
end

function love.resize(width, height)
	tx, ty, fsv = CScreen.update(width, height)
end

function calcx(x)
	return (x*fsv)+tx
end

function calcy(y)
	return (y*fsv)+ty
end
