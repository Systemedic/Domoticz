--Source: https://ehoco.nl/jaarlijkse-energie-en-waterkosten-domoticz/
-- Tijd en datum bepalen
local time = os.date("*t")

commandArray = {}

if time.hour == 23 and time.min == 59 then
    
-- Debugging
debug_on = "true"  -- Zet debugging aan met "true" of uit met "false"

-- IDX van de virtuele sensoren
IDXs    = 303                           -- Stroomkosten huidig jaar
IDXg    = 304                           -- Gaskosten huidig jaar
--IDXw    = 267                         -- Waterkosten huidig jaar
IDXasg  = 305                           -- Afrekening Stroom & Gas
--IDXaw   = 269                         -- Afrekening Water
IDXarsg = 306                           -- Afr. Stroom & Gas Realtime
--IDXarw  = 271                         -- Afrekening Water Realtime

-- Diverse tarieven
voorschot_Stroom_Gas    = 1440.00       -- voorschot Stroom & Gas per jaar in Euro's
--voorschot_Water         =  196.00     -- voorschot Water per jaar in Euro's
levkos_stroom           =   29.40       -- vaste leveringskosten Stroom per jaar
levkos_gas              =   29.40       -- vaste leveringskosten gas per jaar
energiebelasting        = -380.30       -- Verminderde_energiebelasting per jaar
netbeheerkosten_stroom  =  232.32       -- Netbeheerkosten_stroom per jaar
netbeheerkosten_gas     =  155.14       -- Netbeheerkosten_gas per jaar
--vastrecht_water         =   76.78     -- vastrecht_water per jaar

-- Ingangsdatum contract Stroom & Gas / Water
dag_stroom      = 19                    -- 1 voor eerste dag, 2 voor tweede dag, etc.
maand_stroom    = 2                     -- 1 voor januari, 2 voor februari, 3 voor maart, etc.
--dag_water       = 1                   -- 1 voor eerste dag, 2 voor tweede dag, etc.
--maand_water     = 9                   -- 1 voor januari, 2 voor februari, 3 voor maart, etc.

---------------------------------------------------------------------------------------
--------------------------- HIERONDER NIETS WIJZIGEN !!!!!! ---------------------------
---------------------------------------------------------------------------------------

--Functie datum sinds contractperiode
function timedifference (s)   --- tijdverschil bepalen sinds laatste schakeling in sec
   year = string.sub(s, 1, 4)
   month = string.sub(s, 6, 7)
   day = string.sub(s, 9, 10)
   hour = string.sub(s, 12, 13)
   minutes = string.sub(s, 15, 16)
   seconds = string.sub(s, 18, 19)
   t1 = os.time()
   t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
   difference = os.difftime (t1, t2)
   return difference
end

-- Functie afronding
function round(num, dec)
    if num == 0 then
        return 0
    else
        local mult = 10^(dec or 0)
        return math.floor(num * mult + 0.5) / mult
    end
end

--NIEUWE CONTRACTPERIODE STROOM EN GAS
-- Bepalen of een nieuw contractperiode ingaat
if (time.month == maand_stroom and time.day == dag_stroom and time.hour == 23 and time.min == 59) then
        StroomkostenJaar = tonumber(0)
        GaskostenJaar = tonumber(0)
        print ("Nieuw contractperiode van STROOM & GAS is ingegaan!")
        commandArray[1]={['SendNotification']='Nieuw contractperiode van STROOM & GAS is ingegaan! Pas eventueel de tarieven aan!'}
    else
        StroomkostenJaar  = tonumber(uservariables["Stroomkosten_Jaar"])
        GaskostenJaar     = tonumber(uservariables["Gaskosten_Jaar"])
end

--NIEUWE CONTRACTPERIODE WATER
--if (time.month == maand_water and time.day == dag_water and time.hour == 23 and time.min == 59) then
--       WaterkostenJaar = tonumber(0)
--        print ("Nieuw contractperiode van WATER is ingegaan!") 
--        commandArray[2]={['SendNotification']='Nieuw contractperiode van WATER is ingegaan! Pas eventueel de tarieven aan!'}
--    else
--        WaterkostenJaar = tonumber(uservariables["Waterkosten_Jaar"])
--end

-- Kosten van vandaag ophalen
local StroomkostenDag = tonumber(otherdevices['Stroomkosten P1'])
local GaskostenDag    = tonumber(otherdevices['Gaskosten P1'])
--local WaterkostenDag  = tonumber(otherdevices['Waterkosten'])

-- Kosten berekenen vanaf begin contractperiode
local SKJ = StroomkostenJaar + StroomkostenDag
local GKJ = GaskostenJaar + GaskostenDag
--local WKJ = WaterkostenJaar + WaterkostenDag

-- Kosten bereken te betalen / te ontvangen einde contractperiode
local aSG = StroomkostenJaar + StroomkostenDag + GaskostenJaar + GaskostenDag - voorschot_Stroom_Gas + levkos_stroom + levkos_gas + energiebelasting + netbeheerkosten_stroom + netbeheerkosten_gas
--local aW = WaterkostenJaar + WaterkostenDag - voorschot_Water + vastrecht_water

-- REALTIME KOSTEN VS VOORSCHOT (STROOM & GAS
local datum_stroom_nu = {year=time.year, month=time.month, day=time.day, hour=0, min=0, sec=0}
local datum_stroom_contract = {year=time.year, month=maand_stroom, day=dag_stroom, hour=0, min=0, sec=0}
if ((os.time(datum_stroom_contract)-os.time(datum_stroom_nu))/86400) > 0 then
     contractdagen_stroom = ((os.time(datum_stroom_nu)-os.time(datum_stroom_contract))/86400)+366
        else
     contractdagen_stroom = ((os.time(datum_stroom_nu)-os.time(datum_stroom_contract))/86400)+1
end
local arSG = round((StroomkostenJaar + StroomkostenDag + GaskostenJaar + GaskostenDag + (levkos_stroom + levkos_gas + energiebelasting + netbeheerkosten_stroom + netbeheerkosten_gas - voorschot_Stroom_Gas)/365*contractdagen_stroom),2)

-- REALTIME KOSTEN VS VOORSCHOT (WATER)
--local datum_water_nu = {year=time.year, month=time.month, day=time.day, hour=0, min=0, sec=0}
--local datum_water_contract = {year=time.year, month=maand_water, day=dag_water, hour=0, min=0, sec=0}
--if ((os.time(datum_water_contract)-os.time(datum_water_nu))/86400) > 0 then
--     contractdagen_water = ((os.time(datum_water_nu)-os.time(datum_water_contract))/86400)+366
--        else
--     contractdagen_water = ((os.time(datum_water_nu)-os.time(datum_water_contract))/86400)+1
--end
--local arW = round((WaterkostenJaar + WaterkostenDag + (vastrecht_water - voorschot_Water)/365*contractdagen_water),2)

if debug_on == "true" then
    print ("Contract stroom/gas loopt "..round(contractdagen_stroom,0).. " dagen")
--    print ("Contract water loopt "..round(contractdagen_water,0).. " dagen")  -- water

end

-- User variables bijwerken    
commandArray[3]={['Variable:Stroomkosten_Jaar'] = tostring(SKJ)}
commandArray[4]={['Variable:Gaskosten_Jaar']    = tostring(GKJ)}
--commandArray[5]={['Variable:Waterkosten_Jaar']  = tostring(WKJ)}      -- water

-- Devices kosten op jaarbasis bijwerken
commandArray[6]={['UpdateDevice'] = IDXs..'|0|'..tostring(SKJ)}
commandArray[7]={['UpdateDevice'] = IDXg..'|0|'..tostring(GKJ)}
--commandArray[8]={['UpdateDevice'] = IDXw..'|0|'..tostring(WKJ)}       -- water

-- Devices te betalen / te ontvangen einde contractperiode bijwerken
commandArray[9]={['UpdateDevice']  = IDXasg..'|0|'..tostring(aSG)}
--commandArray[10]={['UpdateDevice'] = IDXaw..'|0|'..tostring(aW)}      -- water

-- Devices te betalen / te ontvangen realtime bijwerken
commandArray[11]={['UpdateDevice'] = IDXarsg..'|0|'..tostring(arSG)}
--commandArray[12]={['UpdateDevice'] = IDXarw..'|0|'..tostring(arW)}    -- water
end    

return commandArray
