Bot_List = {
    ["jqhvka"] = {
        world_pabrik = "GSSWH",
        door_id_world_pabrik = "Z1612",
        pos_break_x = 4,
        pos_break_y = 15,
        rangePNB = 5,
    },
    ["ivmgmk"] = {
        world_pabrik = "CMDUY",
        door_id_world_pabrik = "Z1612",
        pos_break_x = 4,
        pos_break_y = 15,
        rangePNB = 5,
    }
}
-- jika lebih dari satu atau dua copy aja confignya

--=[] KONFIGURASI ID BLOCK AND TREE PABRIK []=--
tree_id = 881
block_id = 880

--=[] KONFIGURASI RANGE []=--
rangePT = 5
rangeHT = 5

--=[] KONFIGURASI GRIND []=--
auto_grind = true
pos_grind_x = 0
pos_grind_y = 18
amount_to_save_item_grind = 4
world_save_item_grind = "WPACK999"
door_id_world_save_item_grind = "Z1612"

--=[] KONFIGURASI STORAGE SEED []=--
world_storage_seed = "WSEED999"
door_id_world_storage_seed = "Z1612"

--=[] KONFIGURASI AUTO BUY PACK []=--
auto_buyPack = true
world_save_pack = "WPACK999"
door_id_world_save_pack = "Z1612"
pack_name = "world_lock"
pack_price = 2000
pack_item_id = {242}
min_pack_buy = 1
minimal_gems = 2000

--=[] KONFIGURASI SIZE WORLD PABRIK []=--
start_pabrik_x = 1
end_pabrik_x = 98
start_pabrik_y = 15

--=[] KONFIGURASI DELAY []=--
delay_path = 150
delay_place = 100
delay_punch = 100
delay_plant = 100
delay_harvest = 100
delay_reconnect = 10000
delay_join_world = 5000

--=[] KONFIGURASI TRASH []=--
trash_item_list = {5024,5026,5028, 5032, 5034, 5036, 5038, 5040, 5042, 5044, 7162, 7164} -- id trash item

local bot = getBot()
local world = bot:getWorld()
local inventory= bot:getInventory()
local status = getBot().status
local wantGrind, tryPabrik = false, false
bot.auto_reconnect = false
bot.auto_trash = false



--=[] random sleep []=--
function randomSleep(mins, maxs)
	return sleep(math.random(mins, maxs))
end

--=[] parameter disconnect []=--
function disconnected(status)
    local disconnectStatus = {
        [BotStatus.offline] = true,
        [BotStatus.account_banned] = true,
        [BotStatus.location_banned] = true,
        [BotStatus.version_update] = true,
        [BotStatus.server_overload] = true,
        [BotStatus.too_many_login] = true,
        [BotStatus.maintenance] = true,
        [BotStatus.server_busy] = true,
        [BotStatus.guest_limit] = true,
        [BotStatus.http_block] = true,
        [BotStatus.invalid_account] = true,
        [BotStatus.error_connecting] = true,
        [BotStatus.changing_subserver] = true,
        [BotStatus.logon_fail] = true,
    }
    return disconnectStatus[status] == true
end

--=[] reconnect []=--
function reconnecting()
    while disconnected(status) do
        print("Bot " .. getBot().name .. " terputus, mencoba reconnect...")
        status = getBot().status
        if status == BotStatus.account_banned or status == BotStatus.maintenance then
            print("Tidak bisa reconnect, status bot: " .. tostring(status))
            break
        end
        bot:connect()
        randomSleep(delay_reconnect, delay_reconnect + 5000)
    end
end

--=[] join world []=--
function joinWorld(currentWorld, id)
	while not disconnected(status) and bot:getWorld() and bot:getWorld().name ~= currentWorld do
		print("Bot " .. getBot().name .. " rejoin ke world...")
		status = getBot().status
		if status == BotStatus.account_banned or status == BotStatus.maintenance then
            print("Tidak bisa rejoin, status bot: " .. tostring(status))
            break
        end
        bot:warp(currentWorld .. "|" .. id)
        randomSleep(delay_join_world, delay_join_world + 1000)
        if world:getTile(bot.x, bot.y).fg ~= 6 then
        	break
        end
	end
end

--=[] scan object float []=--
function scanFloat(id)
    local count = 0
    for _, obj in pairs(getObjects()) do
        if obj.id == id then
            count = count + obj.count
        end
    end
    return count
end

--=[] trash []=--
function scanTrash()
    print("WANT TO TRASH")
    if disconnected(status) then return end   
    for _, item in pairs(trash_item_list) do
        local count = inventory:getItemCount(item)
        if count >= 100 then
            return true
        end
    end
    return false
end
--
function trashItem()
    if disconnected(status) then return end    
    for _, item in pairs(trash_item_list) do
        while not disconnected(status) and inventory:getItemCount(item) > 100 do
            local amount = inventory:getItemCount(item)
            bot:trash(item, amount)
            print("Membuang " .. amount .. " dari item " .. item)
            randomSleep(100, 200)
        end
    end
end

--=[] buy pack []=--
function scanBuyPack()
    if disconnected(status) then return end
    if getBot().gem_count >= minimal_gems then
        return true
    end
    return false
end

function buyPack()
    if disconnected(status) then return end
    local countBuy = 0
    while true do
        countBuy = countBuy + 1
        bot:buy(pack_name)
        randomSleep(500, 1000)
        if countBuy == min_pack_buy then
            break
        end
    end
    joinWorld(world_save_pack, door_id_world_save_pack)
    sleep(100)
    for _, packItem in pairs(pack_item_id) do
        local attempt = 0
        while not disconnected(status) and inventory:getItemCount(packItem) >= 1 do
            attempt = attempt + 1
            local amount = inventory:getItemCount(packItem)
            bot:drop(packItem, amount)
            randomSleep(100, 150)
            if inventory:getItemCount(packItem) == 0 then
                break
            end
            if attempt >= 2 then
                local bot_x = math.floor(bot.x)
                local bot_y = math.floor(bot.y)
                bot:findPath(bot_x + 1, bot_y)
                sleep(100)
                attempt = 0
            end
        end
    end
end

--=[] pnb []=--
function pnb()
    local myName = getBot().name
    local cfg = Bot_List[myName]
    if not cfg then
        print("Config untuk bot " .. myName .. " tidak ditemukan!")
        return
    end

    local posBreakX, posBreakY = cfg.pos_break_x, cfg.pos_break_y
    local rangePNB = cfg.rangePNB or 3   -- default 3 kalau tidak di-set di config
    print("Start PNB untuk bot:", myName, "range:", rangePNB, "pos:", posBreakX, posBreakY)

    -- fungsi buat generate range posisi
    local function getPosRange(x, y, range)
        if range < 1 then range = 1 end
        if range > 5 then range = 5 end

        local posRange = {}
        local offset = math.floor(range / 2)
        for dx = -offset, offset do
            table.insert(posRange, {x + dx, y - 1})
        end
        return posRange
    end

    -- ambil posisi otomatis dari rangePNB
    local posRange = getPosRange(posBreakX, posBreakY, rangePNB)
    print("Posisi yang dipakai untuk PNB:")
    for i, p in ipairs(posRange) do
        print("   ", i, "-> x:", p[1], "y:", p[2])
    end

    -- ====== PLACE terlebih dahulu ======
    for _, pos in ipairs(posRange) do
        local x, y = pos[1], pos[2]
        print("Cek PLACE di:", x, y, "fg:", world:getTile(x, y).fg)

        while not disconnected(status)
          and not scanTrash()
          and not needGrind
          and inventory:getItemCount(block_id) > 0
          and world:getTile(x, y).fg == 0 do

            print("Place block di:", x, y, " sisa block:", inventory:getItemCount(block_id))
            bot:place(x, y, block_id)
            randomSleep(delay_place - 50, delay_place)

            if inventory:getItemCount(block_id) <= 0 then
                print("Habis block saat place!")
                break
            end
        end
    end

    -- ====== BREAK setelah semua PLACE selesai ======
    for _, pos in ipairs(posRange) do
        local x, y = pos[1], pos[2]
        print("Cek BREAK di:", x, y, "fg:", world:getTile(x, y).fg)

        while not disconnected(status)
          and not scanTrash()
          and not needGrind
          and world:getTile(x, y).fg == block_id do

            print("Hit block di:", x, y)
            bot:hit(x, y)
            randomSleep(delay_punch, delay_punch + 25)

            if inventory:getItemCount(block_id) <= 0 then
                print("Habis block saat break!")
                break
            end
        end

        print("Collect drop di sekitar")
        takeAllItem()
    end

    print("Selesai PNB untuk bot:", myName)
end
        
function loopPnb()
	if disconnected(status) then return end
    while true do
    	pnb()
    	sleep(50)
    	if disconnected(status) or needGrind or inventory:getItemCount(block_id) <= 0 or inventory:getItemCount(tree_id) >= 200 or scanTrash() then
			break
		end
    end
    if needGrind() then
        wantGrind = true
    end
    if not disconnected(status) and scanTrash() then
    	trashItem()
    end
    if not disconnected(status) and auto_buyPack then
        if not disconnected(status) and scanBuyPack() then
            buyPack()
        end
    end
end

--=[] take float []=--
function performActionTakeItem(x, y, itemID, delay)
	local pkt = GameUpdatePacket.new()
	pkt.type = 11
	pkt.int_data = itemID
	pkt.pos_x = x
	pkt.pos_y = y
	bot:sendRaw(pkt)
	sleep(delay)
end

function takeItem(itemID)
	for _, obj in pairs(world:getObjects()) do
		if obj.id == itemID then
			local objX = math.floor(obj.x / 32)
			local objY = math.floor(obj.y / 32)
			if math.abs(bot.x - objX) <= 64 and math.abs(bot.y - objY) <= 64 then
				performActionTakeItem(obj.x, obj.y, obj.oid, 100)
				break
			end
		end
	end
end

function takeAllItem()
    for _, obj in pairs(world:getObjects()) do
	    local objX = math.floor(obj.x / 32)
	    local objY = math.floor(obj.y / 32)
	    if math.abs(bot.x - objX) <= 64 and math.abs(bot.y - objY) <= 64 then
	        performActionTakeItem(obj.x, obj.y, obj.oid, 100)
	        break
		end
	end
end

function takeFloat(id)
    if disconnected(status) then return end
    for _, obj in pairs(world:getObjects()) do
        if obj.id == id then
            bot:findPath(math.floor(obj.x / 32), math.floor(obj.y / 32))
            sleep(200)
            takeItem(id)
            if inventory:getItemCount(id) >= 200 then
                break
            end
        end
    end
end

--=[] plant []=--
function plantTree()
    if disconnected(status) then return end
    for x = start_pabrik_x, end_pabrik_x do
        if disconnected(status) then return end
        local tile1 = world:getTile(x, start_pabrik_y)
        local tile2 = world:getTile(x, start_pabrik_y + 1)

        -- cek tile kosong di atas tanah
        if not disconnected(status) and tile1 and tile2 and tile1.fg == 0 and tile2.fg ~= 0 then
            bot:findPath(x, start_pabrik_y)
            randomSleep(delay_path, delay_path + 50)
            -- tanam sesuai range (ke kanan dari posisi x)
            for i = 0, rangePT do
                local px = x + i
                local t = world:getTile(px, start_pabrik_y)
                if not disconnected(status) and t and t.fg == 0 then
                    bot:place(px, start_pabrik_y, tree_id)
                    randomSleep(delay_plant, delay_plant + 25)
                    if inventory:getItemCount(tree_id) <= 0 then
                        return
                    end
                end
            end
        end
    end
end

--=[] harvest []=--
function harvestTree()
    if disconnected(status) then return end
    for x = start_pabrik_x, end_pabrik_x do
        if disconnected(status) then return end
        local tile = world:getTile(x, start_pabrik_y)
        if not disconnected(status) and not needGrind() and tile and tile.fg == tree_id and tile:canHarvest() then
            bot:findPath(x, start_pabrik_y)
            randomSleep(delay_path, delay_path + 50)
            for i = 0, rangeHT do
                local px = x + i
                local t = world:getTile(px, start_pabrik_y)
                if not disconnected(status) and not needGrind() and t and t.fg == tree_id and t:canHarvest() then
                    bot:hit(px, start_pabrik_y)
                    randomSleep(delay_harvest, delay_harvest + 50)
                    takeAllItem()
                    if needGrind() then
                        wantGrind = true
                        return
                    end
                end
            end
        end
    end
end
    
--=[] grind []=--
function grind(countGrind)
    if disconnected(status) then return end
    bot:findPath(pos_grind_x, pos_grind_y)
    randomSleep(delay_path * 2, delay_path * 3)
    bot:place(pos_grind_x, pos_grind_y, block_id)
    sleep(200)
    sendPacket(2, "action|dialog_return\ndialog_name|grinder\ntilex|" .. pos_grind_x .. "|\ntiley|" .. pos_grind_y .. "|\ncount|" .. countGrind .. "\nitemID|" .. block_id .. "|")
    sleep(200)
end

function needGrind()
    print("STOP NEED GRIND")
    if disconnected(status) then return end
    if inventory:getItemCount(tree_id) >= 200 then
        return true
    end
    return false
end

function loopTakeToGrind()
    while true do
        sleep(100)
        if disconnected(status) or scanFloat(block_id) <= 1 then
            break
        end
        takeFloat(block_id)
        sleep(200)
        if inventory:getItemCount(block_id) >= 200 then
            grind(4)
        elseif inventory:getItemCount(block_id) < 200 or inventory:getItemCount(block_id) >= 150 then
            grind(3)
        elseif inventory:getItemCount(block_id) < 150 or inventory:getItemCount(block_id) >= 100 then
            grind(2)
        elseif inventory:getItemCount(block_id) < 100 or inventory:getItemCount(block_id) >= 50 then
            grind(3)
        end
        sleep(1000)
    end
end

function mainGrind()
    if disconnected(status) then return end
    if scanReadHT() then
        harvestTree()
    end
    sleep(100)
    loopTakeToGrind()
    sleep(100)
    plantTree()
    sleep(100)
    waittingToHT()
    sleep(100)
    harvestTree()
    sleep(100)
    loopTakeToGrind()
    sleep(100)
    tryPabrik = true
end
        
        

--=[] save flour []=--
function scanFlour()
    if disconnected(status) then return end
    if inventory:getItemCount(4562) >= amount_to_save_item_grind then
        return true
    end
    return false
end

function saveFlour()
    if disconnected(status) then return end
    joinWorld(world_save_item_grind, door_id_world_save_item_grind)
    sleep(100)
    local attempt = 0
    while not disconnected(status) and inventory:getItemCount(4562) > 1 do
        attempt = attempt + 1
        local amount = inventory:getItemCount(4562)
        bot:drop(4562, amount)
        sleep(100)
        if inventory:getItemCount(4562) == 0 then
            break
        end
        if  attempt >= 2 then
            local bot_x = math.floor(bot.x)
            local bot_y = math.floor(bot.y)
            bot:findPath(bot_x + 1, bot_y)
            sleep(100)
            attempt = 0
        end
    end
end

function scanReadHT()
    if disconnected(status) then return end
    for x = start_pabrik_x, end_pabrik_x do
        local tile = world:getTile(x, start_pabrik_y)
        if not disconnected(status) and tile and tile.fg == tree_id and tile:canHarvest() then
            return true
        end
    end
    return false
end

function waittingToHT()
    if disconnected(status) then return end
    while not disconnected(status) do
        randomSleep(1000, 1500)
        if scanReadHT() then
            break
        end
    end
end

function scanPlantTree()
    if disconnected(status) then return end
    for x = start_pabrik_x, end_pabrik_x do
        local tile = world:getTile(x, start_pabrik_y)
        if not disconnected(status) and tile and tile.fg == tree_id and tile.fg ~= 0 then
            return true
        end
    end
    return false
end
    
function mainPabrik()
    local myName = getBot().name
    local configs = Bot_List[myName]
    if not configs then
        print("Config untuk bot " .. myName .. " tidak ditemukan!")
        return
    end

    if disconnected(status) or needGrind() then return end

    joinWorld(configs.world_pabrik, configs.door_id_world_pabrik)

    if not disconnected(status) and not needGrind() and scanFloat(block_id) >= 1 then
        sleep(200)
        takeFloat(block_id)
        sleep(100)
        bot:findPath(configs.pos_break_x, configs.pos_break_y)
        sleep(delay_path * 3)
        loopPnb()
    else
        if not disconnected(status) and not needGrind() and not scanPlantTree() then
            if inventory:getItemCount(tree_id) <= 0 then
                joinWorld(world_storage_seed, door_id_world_save_pack)
                sleep(100)
                takeFloat(tree_id)
                sleep(100)
                joinWorld(configs.world_pabrik, configs.door_id_world_pabrik)
                plantTree()
                sleep(100)
            else
                plantTree()
                sleep(100)
            end
        end
        waittingToHT()
        harvestTree()
        sleep(100)
        takeFloat(block_id)
        sleep(100)
        bot:findPath(configs.pos_break_x, configs.pos_break_y)
        sleep(delay_path * 3)
        loopPnb()
    end
    tryPabrik = true
end
mainPabrik()
-- loop utama
while true do
    sleep(100)
    if disconnected(status) then
        reconnecting()
        sleep(500)
        tryPabrik = true
    end
    if wantGrind then
        mainGrind()
        wantGrind = false
    end
    if tryPabrik then
        mainPabrik()
        tryPabrik = false
    end
    randomSleep(1000, 2000)
end