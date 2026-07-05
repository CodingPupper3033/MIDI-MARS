# MIDI MIPS

This project plays a provided MIDI file using the MIDI syscalls the MARS emulator provides. It requires the user to have their own instance of the MARS jar file and modify the `fileName` attribute in the configuration accordingly.

To accomplish this, the program follows these steps:

1. **Reading MIDI Headers**: The program begins by reading the MIDI file headers to extract essential metadata such as format type, number of tracks, and time division.
2. **Processing Audio Tracks**: Each audio track is read individually. The start/end times are converted into start and total times for accurate playback timing.
3. **Combining Tracks**: All individual tracks are combined into a single large array that holds all the notes and timing information.
4. **Playing the Sequence**: Finally, the program plays the sequence of notes stored in the combined array sequentially.

Note: Ensure you have your own MARS jar file installed and configured. Update the `fileName` attribute in the configuration file to point to the desired MIDI file you wish to play.

## Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/CodingPupper3033/MIDI-MARS.git
   cd MIDI-MARS
   ```

2. Download and install the MARS emulator from [MARS Downloads](https://courses.missouristate.edu/kenvollmar/mars/download.htm).

3. Update the `fileName` attribute in the configuration file to point to the desired MIDI file path.

## Examples:

Playing Owl City - Fireflies:
![Fireflies](./Example%20Videos/fireflies.mp4)

Playing Rick Astley - Never Gonna Give You Up
![Never Gonna Give You Up](./Example%20Videos/Never%20Gonna%20Give%20You%20Up.mp4)

## Additional Notes:

- **MIPS Emulation**: This project utilizes the MARS emulator to provide MIDI syscalls, which are essential for handling MIDI file playback. Ensure you have your own MARS jar file installed and configured.
  
- **File Configuration**: Update the `fileName` attribute in the configuration file to point to the desired MIDI file you wish to play.

- **Project Limitations**: Currently, the project is primarily focused on reproducing the song "Owl City - Fireflies" and may not work well with other MIDI files due to specific timing and formatting requirements.
  
- **Future Work**: Future improvements could include expanding support for various MIDI files, enhancing error handling, and optimizing performance.