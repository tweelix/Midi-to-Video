# Midi-to-Video
A Macro for Reaper using the ReaScript API to simulate a sort of "Video Sampler"

# Instructions:

1. Copy your desired video sample to the clipboard (Ctrl+C)
1. Open a MIDI Take in the MIDI Editor 
1. Run the script from the MIDI editor and choose your options

Currently I recommend, if you have a midi file with several instruments, having a seperate track for each instrument  and running the script on each seperately with their respective desired samples. Reaper can split MIDI files like this automatically on import to facilitate this. In future the Script may be able to do this automatically.

Note: Channel 10 is filtered by default. This usually contains percussion instruments. In order to use the script on these I recommend not only having channel 10 on a seperate track, but also splitting the MIDI so each percussion instrument has it's own track and running the script on these individually with different samples. 

# Input Parameters:
* Stretch Notes: Wether or not to stretch the sample to match the length of the notes in the MIDI file
* Pitch Notes: Wether or not to pitch the sample. Disable this for percussion for example
* Include Dynamics: Wether or not to include the dynamics from the MIDI file.
* Low Note Protection: An Eximental feature to try to prevent the script from "Squashing" a note too far, which causes problems with pitch shifting it in Reaper
* Filter Channel 10: True by default. Disable to use on percussion
* Transpose in semitones: If your Sample is not tuned to middle C this will transpose it by this many Semitones
* Sort by pitch: Wether or not the output of the script should be sorted by pitch.
* Pitch bend (EXPERIMENTAL): Incomplete feature. Only use on a single channel midi take. It will try to get pitch bend information from the MIDI input and apply it to the samples.
* Bend Range: Bend Range for the Pitch Bending Feature. 2 by default. Depending on the MIDI format you may have to change it. Try multiples of 2 until it sounds correct.
  
__WARNING__: Only use the *Apply Pitchbends* feature on a single channel MIDI Take
  
__WARNING__: You may not get the expected output if the script tries to "Squash" your sample too much, especially combined with a very low pitch. The *Low Note Protection* feature attempts to contain this problem but it is not a perfect solution

testtest
