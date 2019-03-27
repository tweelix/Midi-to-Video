--[[
	* Description: A Macro that acts like a sort of "Video Sampler"
	* Usage: 1.Copy your desired video sample to the clipboard (Ctrl+C)
	* 2. Open a MIDI Take in the MIDI Editor 
	*	3. Run the script from the midi editor and choose your options
	* WARNING: Only use apply pitchbends on a single channel MIDI File
	* WARNING: You may not get the expected output if the script tries to "Squash"
	* your sample too much, especially combined with a very low pitch. The Low Note
	* Protection attempts to contain this problem but it is not a perfect solution
--]]


--[[
 * ReaScript Name: VideoSampler
 * Author: Tweelix
 * Licence: GPL v3
 * REAPER: 5.0
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2019-03-27)
	+ Initial Release
--]]

--initialising
track=1
NTracks=1
track_isfree={[1]=true}
track_whenfree={[1]=0}

includeStretch=true
includePitch=true
includeDynamics=true
includelowprotection=true
filterchannelten=true
Transposeall=0
sortbypitch=true

lownoteprotection = {[-1]=9,[-2]=9,[-3]=8,[-4]=8,[-5]=7,[-6]=7,[-7]=6,[-8]=6,[-9]=5,[-10]=5,[-11]=5,[-12]=5,[-13]=4.5,[-14]=4.25,[-15]=4,[-16]=3.75,[-17]=3.5,[-18]=3.75,[-19]=3,[-20]=3,[-21]=2.9,[-22]=2.7,[-23]=2.5,[-24]=2.5,[-25]=2.2,[-26]=2.2,[-27]=2,[-28]=2,[-29]=1.8,[-30]=1.7,[-31]=1.6,[-32]=1.5,[-33]=1.5,[-34]=1.5,[-35]=1.3,[-36]=1.2}

function getUserParameters()
	
	retval,retvals_csv = reaper.GetUserInputs("Parameters", 9, "Stretch Notes,Pitch Notes,Include Dynamics,Low Note Protection,Filter Channel 10,Transpose in semitones,Sort by pitch,Pitch bend (EXPERIMENTAL),Bend Range", "true,true,true,true,true,0,true,false,2")
	local stretch=""
	local pitch = ""
	local dynamics = ""
	local protection = ""
	local transposestring = ""
	local filter = ""
	local sort=""
	local bendrangestring=""
	local bend=""
    stretch,pitch,dynamics,protection,filter,transposestring,sort,bend,bendrangestring = retvals_csv:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
	Transposeall=tonumber(transposestring)
	bendrange=tonumber(bendrangestring*2)
	if stretch == "true" then includeStretch = true elseif stretch == "false" then includeStretch=false else error('invalid input') end
	if pitch == "true" then includePitch = true elseif pitch == "false" then includePitch=false else error('invalid input') end
	if dynamics== "true" then includeDynamics = true elseif dynamics == "false" then includeDynamics=false else error('invalid input') end
	if protection == "true" then includelowprotection = true elseif protection == "false" then includelowprotection=false else error('invalid input') end
	if filter == "true" then filterchannelten = true elseif filter == "false" then filterchannelten=false else error('invalid input') end
	if sort == "true" then sortbypitch = true elseif sort == "false" then sortbypitch=false else error('invalid input') end
	if bend == "true" then dopitchbend = true elseif bend == "false" then dopitchbend=false else error('invalid input') end
	
	if retval then
		return true
	else
		return false
	end

end

function placenote(start,pitch,length,velocity)

	reaper.SetEditCurPos(start, false, false)
	reaper.Main_OnCommand(40058, 0) --paste
	local actp= (pitch-60)+Transposeall
	local volume=velocity/127
	local mediaitem=reaper.GetSelectedMediaItem(0,0)
	local mediatake=reaper.GetActiveTake(mediaitem)
	
	if includePitch then
		reaper.SetMediaItemTakeInfo_Value(mediatake, "D_PITCH", actp)
	end
	if includeStretch then
		local medialength=reaper.GetMediaItemInfo_Value(mediaitem, "D_LENGTH")
		local stretch=1/(length/medialength)
		
		if includelowprotection and includePitch then
			if actp<0 and actp>(-37) and stretch>lownoteprotection[actp] then
				stretch=lownoteprotection[actp]
			elseif stretch>1 and actp<(-36) then
				stretch=1
			end
		end
		
		reaper.SetMediaItemTakeInfo_Value(mediatake, "D_PLAYRATE", stretch)
		reaper.SetMediaItemInfo_Value(mediaitem, "D_LENGTH", length)
	end
	if includeDynamics then
		reaper.SetMediaItemTakeInfo_Value(mediatake, "D_VOL", volume)
	end
end

function tablelength(T)
	local count = 0
	for _,EUIEU in pairs(T) do 
		for _ in pairs(EUIEU) do
			count = count + 1
		end
	end
	return count
end

function gototrack(desiredtrack)

	if track>desiredtrack then

		for a=1,(track-desiredtrack) do
			reaper.Main_OnCommand(40286, 0)	
		end
		
	elseif track<desiredtrack then

		for b=1,(desiredtrack-track) do
			reaper.Main_OnCommand(40285, 0)
		end

	end
	
	track=desiredtrack

end

function createtrack()
	reaper.Main_OnCommand(40702, 0) --create new track
	
	track=NTracks+1
	NTracks=NTracks+1
	table.insert(track_isfree,true)
	table.insert(track_whenfree,0)
	
	
end

function pairsByKeys (t)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a)
      local i = 0      -- iterator variable
      local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
      end
      return iter
	  end

function initialise()

	if not getUserParameters() then error("no parameters selected") end
	local notelist={}
	take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
	if not take then error("Please run this script in the MIDI Editor")	end
	_,notes,ccs = reaper.MIDI_CountEvts(take)
	
	if dopitchbend then
		pitchbenddata={}
		
		for i=0,ccs do

			_,_,_,ccpos,ccchanmsg, ccchan, ccmsg2, ccmsg3 = reaper.MIDI_GetCC(take, i)
			if ccchanmsg==224 then 
				--reaper.ShowConsoleMsg("pos: "..tostring(ccpos).." chanmsg: "..tostring(ccchanmsg).." chan: "..tostring(ccchan).." msg2: "..tostring(ccmsg2).." msg 3 "..tostring(((((ccmsg3-64)/128)*bendrange)/48)+0.5))
				--reaper.ShowConsoleMsg("\n")
				local pitchposition=reaper.MIDI_GetProjTimeFromPPQPos(take,ccpos)
				
				local pitchbendvalue=((((ccmsg3-64)/128)*bendrange)/48)+0.5
				
				pitchbenddata[pitchposition]=pitchbendvalue
				
			end
			
		end
	end
	
	for i = 0,notes do
	
		if reaper.MIDI_GetNote(take,i) then
			_,_,_,ppqpos,endppqpos,channel,pitch,velout = reaper.MIDI_GetNote(take,i)
			
			position=reaper.MIDI_GetProjTimeFromPPQPos(take,ppqpos)
			endposition=reaper.MIDI_GetProjTimeFromPPQPos(take,endppqpos)
			--reaper.ShowConsoleMsg(channel..",")
			
			if not notelist[position] then
				notelist[position]={}
			end
			local note={["pitch"]=pitch,["end"]=endposition,["vel"]=velout}
			if filterchannelten then
				if channel~=9 then
					table.insert(notelist[position],note)
				end
			else
				table.insert(notelist[position],note)
			end
			if sortbypitch then
				function compare(a,b)
					return a.pitch > b.pitch
				end
				table.sort(notelist[position], compare)
			end
		end
		
	end

	orderednotes={}
	for name, line in pairsByKeys(notelist) do
   	local t={}
     --reaper.ShowConsoleMsg(tostring(name).." "..tostring(line).."\n")
	 local t={[name]=line}
	 table.insert(orderednotes,t)
	  
    end
	--Nobj=tablelength(orderednotes)
	
	
	
	
end

local function checkforfreetracks(currenttime)

	for i,j in ipairs(track_isfree) do
		if not j then 
			if track_whenfree[i]<=currenttime then
				track_isfree[i]=true
				track_whenfree[i]=0
			end
		end
	end
end

function placepitchbend(position,value)

return

end

function applypitchbends()

	for i = 1, NTracks do
		gototrack(i)
		local localtrack=reaper.GetSelectedTrack(0,0)
		reaper.TrackFX_AddByName(localtrack,"ReaPitch", false, -1)

		local envelope = reaper.GetFXEnvelope(localtrack,0,3, true)
		
		for position,value in pairs(pitchbenddata) do
			reaper.InsertEnvelopePoint(envelope, position ,value,1 , 0,true)
		end
		
	end 

end

-- Main function
function main()

	initialise()
	reaper.ShowConsoleMsg("Placing Notes \n")
	counter=0
	reaper.Main_OnCommand(40702, 0) --create new track

	for number,kek in ipairs(orderednotes) do
		--reaper.ShowConsoleMsg("")
		--reaper.ShowConsoleMsg("Placing Notes:"..tostring(counter).."/"..tostring(notes-1))

		for start,object in pairs(kek) do
			for _,notee in ipairs(object) do
				counter=counter+1
				
				checkforfreetracks(start)
				
				gototrack(1)
			
				local currentpitch=notee.pitch
				local currentend=notee["end"]
				local currentvel=notee.vel
				local currentlength=currentend-start
				
				
				if track_isfree[track] then
					
					placenote(start,currentpitch,currentlength,currentvel)
					track_isfree[track]=false
					track_whenfree[track]=currentend
					
				else
					while not track_isfree[track] do
						
						if not track_whenfree[track+1] then
							createtrack()
							break
						end
						
						gototrack(track+1)
					end
					placenote(start,currentpitch,currentlength,currentvel)
					track_isfree[track]=false
					track_whenfree[track]=currentend
				end
			end
		end
	end
	if dopitchbend then
		reaper.ShowConsoleMsg("Applying Pitch Bends \n")
		applypitchbends()
	end
	
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.


main()
reaper.ShowConsoleMsg("COMPLETE")

reaper.Undo_EndBlock("My action", -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)