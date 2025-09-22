# MIDI MIPS
This project plays a provided MIDI file using the MIDI syscalls the MARS emulator provides. 

To accomplish this the program:
1. Reads the MIDI Headers
2. Reads each audio track, converting start/end times to start and total times.
3. Combines each track into one big array
4. Plays the array sequentially

## Examples:
Playing Owl City - Fireflies:
![Fireflies](./Example%20Videos/Fireflies.mp4)

Playing Rick Astley - Never Gonna Give You Up
![Never Gonna Give You Up](./Example%20Videos/Never%20Gonna%20Give%20You%20Up.mp4)

## Notes:
This project was fueled by a desire to play Owl City - Fireflies using MIPS. I have gotten the project to a point where I believe that Fireflies is distinguishable, and will leave it there. Other files may (and usually don't) work very well.
