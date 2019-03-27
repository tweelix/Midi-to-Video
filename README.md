# Midi-to-Video
A Macro for Reaper using the ReaScript API to simulate a sort of "Video Sampler"

# Instructions:

1. Copy your desired video sample to the clipboard (Ctrl+C)
1. Open a MIDI Take in the MIDI Editor 
1. Run the script from the midi editor and choose your options
  
__WARNING__: Only use the apply pitchbends feature on a single channel MIDI Take
  
__WARNING__: You may not get the expected output if the script tries to "Squash" your sample too much, especially combined with a very low pitch. The Low Note Protection feature attempts to contain this problem but it is not a perfect solution
