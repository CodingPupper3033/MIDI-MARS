.data
buffer:			.space 4
max_ms_before_delay:	.word 2
fileName:		.asciiz "J:\\Programming\\Assembly\\MIPS\\MIDI Player\\fireflies.mid"
#fileName:		.asciiz "J:\\Programming\\Assembly\\MIPS\\MIDI Player\\Never Gonna Give You Up.mid"
unableToOpenFile:	.asciiz "Aborting - Unable to open the file"
malformedFile:		.asciiz "Aborting - Malformed File"
wrongFormat:		.asciiz "Warning  - Only MIDI Format 1 is supported. Proceed with caution."
numberTracksText:	.asciiz "Message  - The number of tracks found is: "
newLine:		.asciiz "\n"
forwardSlash:		.asciiz "/"
headerReadingText:	.asciiz "Message  - Reading MIDI Header\n"
headerReadText:		.asciiz "Message  - The MIDI Header has successfully been read\n"
trackReadingText:	.asciiz "Message  - Reading MIDI Tracks\n"
fileReadText:		.asciiz "Message  - File has been read successfully!\n"
mergingText:		.asciiz "Message  - Merging Tracks\n"
mergedText:		.asciiz "Message  - Tracks have been merged\n"
trackNameText:		.asciiz "Message  - Track found: "
timeSignatureText:	.asciiz "Message  - Time Signature: "
unknownMeta:		.asciiz "Skipping - Unknown Meta Event: "
unknownChunk:		.asciiz "Skipping - Unknown Chunk (reversed endian): "
unknownTrackEvent:	.asciiz "Aborting - Unknown Track Event: "
noteEndedNotStarted:	.asciiz "Aborting - Malformed Track, Note Off event with no corresponding Note On event\n"


.text
#  Setup
move $s0, $0
move $s1, $0
move $s2, $0
move $s3, $0
move $s4, $0
move $s5, $0
move $s6, $0
move $s7, $0

# Open File
li $v0, 13
la, $a0, fileName
li, $a1, 0
li $a2, 0
syscall
move $s0, $v0		# s0: File Descriptor

bge $v0, 0, FILE_OPEN # Ensure file is open
li $v0, 55
la $a0, unableToOpenFile
li $a1, 0
syscall # If not, error
li $v0, 10
syscall # And exit


FILE_OPEN: # File was successfully opened
# s0: File Descriptor

# Reading the Header
la $a0, headerReadingText
li $v0, 4
syscall

# Read Header
li $v0, 14
move $a0, $s0
la $a1, buffer
li $a2, 4
syscall

lw $t0, buffer
beq $t0, 0x6468544d, HEADER_FOUND# Did we get a valid header?

j MALFORMED_FILE


HEADER_FOUND:
# s0: File Descriptor

# Read Header Length
move $a0, $s0
jal GET_CHUNK_LENGTH

beq $v0, 6, HEADER_LENGTH_FOUND # Correct header length?
j MALFORMED_FILE


HEADER_LENGTH_FOUND:
# s0: File Descriptor
# Read MIDI Format
li $v0, 14
move $a0, $s0
la $a1, buffer
sw $0, 0($a1) # Clear buffer
li $a2, 2
syscall

lw $t0, buffer
beq $t0, 0x0100, FORMAT_FOUND # Correct MIDI Format?
li $v0, 55
la $a0, wrongFormat
li $a1, 2
syscall # Unable to find format of 1
# Proceed.. (despite format)


FORMAT_FOUND:
# s0: File Descriptor
# Read Number of Tracks
li $v0, 14
move $a0, $s0
la $a1, buffer
sw $0, 0($a1) # Clear buffer
li $a2, 2
syscall

# Record Track Length
lw $a0, buffer
jal SWAP_ENDIAN
move $s1, $v0
srl $s1, $s1, 16

# Print Track Length
la $a0, numberTracksText
li $v0,  4
syscall

move $a0, $s1
li $v0, 1
syscall

la $a0, newLine
li $v0, 4
syscall

# Create Array of pointers for tracks
sll $a0, $s1, 2
li $v0, 9
syscall
move $s6, $v0

NUMBER_TRACKS_FOUND:
# s0: File Descriptor
# s1: Number of Tracks
# s6: Array of Track End Node Ptrs
li $v0, 14
move $a0, $s0
la $a1, buffer
sw $0, 0($a1) # Clear buffer
li $a2, 2
syscall
lw $a0, buffer
jal SWAP_ENDIAN
move $s2, $v0
srl $s2, $s2, 16

andi $t0, $s2, 0x80
beq $t0, 0, DIVISION_FOUND# Make sure division is in ticks/.25 note. I don't support the other one
j MALFORMED_FILE


DIVISION_FOUND:
# s0: File Descriptor
# s1: Number of Tracks
# s2: Divisions per quarter note
# s6: Array of track trail ptrs
#Header is finished being read
li $v0, 4
la $a0, headerReadText
syscall

la $a0, trackReadingText
li $v0, 4
syscall

READ_CHUNK:
# s0: File Descriptor
# s1: Number of Tracks
# s2: Divisions per quarter note
# s3: Tempo (if found)
# s6: Array of track trail ptrs

# Read Chunk Type
li $v0, 14
move $a0, $s0
la $a1, buffer
li $a2, 4
syscall
beq $v0, 0, FILE_FINISHED# Check if file is finished being read

lw $t0, buffer

beq $t0, 0x6b72544d, READ_TRACK # MTrk Chunk

# No known chunk found
la $a0, unknownChunk
li $v0, 4
syscall
move $a0, $t0
li $v0, 24
syscall
j SKIP_CHUNK 


SKIP_CHUNK:
#a0: file descriptor
move $a0, $s0
jal GET_CHUNK_LENGTH# Get Chunk length (to skip)
move $t0, $v0

li $t1, 0
SKIP_CHUNK_LOOP:
beq $t1, $t0, SKIP_CHUNK_END
# Read a byte at a time
li $v0, 14
move $a0, $s0
la $a1, buffer
li $a2, 1
syscall

addi $t1, $t1, 1
j SKIP_CHUNK_LOOP

SKIP_CHUNK_END:
j READ_CHUNK


MALFORMED_FILE:
# s0: File Descriptor
li $v0, 55
la $a0, malformedFile
li $a1, 0
syscall
move $a0, $s0

# Close File
li $v0, 16
syscall

# Program done, exit
li $v0, 10
syscall


READ_TRACK:
# a0: file descriptor
# s0: File Descriptor
# s1: Number of Tracks
# s2: Divisions per quarter note
# s3: Tempo (if found)
# s4: Milliseconds into track (found using delta-time, tempo, & divisions)
# s5: Track converting
# s6: Array of Track End Node Ptrs
# s7: Previous MIDI Event
move $s4, $0
jal READ_CHUNK_DATA
move $a0, $v0


READ_TRACK_EVENT:
# a0: Addr to read from
# s0: File Descriptor
# s1: Number of Tracks
# s2: Divisions per quarter note
# s3: Tempo (if found)
# s4: Milliseconds into track (found using delta-time, tempo, & divisions)
# s5: Track converting
# s6: Array of Track End Node Ptrs
# s7: Previous MIDI Event
jal READ_VARIABLE_LENGTH

# Record delta time
move $a0, $v0

jal DELTA_TIME_TO_MS
add $s4, $s4, $v0

move $a1, $v1	# Next data addr
addi $a1, $a1, 1
lbu $t1, -1($a1) # Event byte

# Determmine event type (in the order listed in the documentation)

# Meta Events
beq $t1, 0xFF, READ_META_EVENT

# Channel Voice Messages
andi $t0, $t1, 0xF0 # First nibble is Status
andi $t2, $t0, 0x80 # Is this a repeated command?

bnez $t2, READ_CHANNEL_VOICE#Status byte omitted?
move $t0, $s7
subi $a1, $a1, 1
j READ_CHANNEL_VOICE # Yes, but fixed


READ_META_EVENT:
# a1: Next Datta Addr
# s0: File Descriptor
# s1: Number of Tracks
# s2: Divisions per quarter note
lbu $t0, 0($a1)
addi $a1, $a1, 1

beq $t0, 0x03, READ_META_EVENT_TRACK_NAME	# Track Name
beq $t0, 0x04, SKIP_META_EVENT			# Instrument Name - Not needed
beq $t0, 0x21, SKIP_META_EVENT			# MIDI port - I know of it; just don't care.
beq $t0, 0x2F, READ_META_EVENT_END_OF_TRACK	# End of Track
beq $t0, 0x51, READ_META_EVENT_SET_TEMPO	# Set Tempo
beq $t0, 0x58, READ_META_EVENT_TIME_SIGNATURE

# Unknown meta event
la $a0, unknownMeta
li $v0, 4
syscall

move $a0, $t0
li $v0, 34
syscall

la $a0, newLine
li $v0, 4
syscall

# Skip it, assuming variable length
SKIP_META_EVENT:
move $a0, $a1
jal READ_VARIABLE_LENGTH

add $a0, $v0, $v1
j READ_TRACK_EVENT


READ_META_EVENT_TRACK_NAME:
# a1: Next Datta Addr
# s0: File Descriptor
# s1: Number of Tracks
# s2: Divisions per quarter note

move $a0, $a1
jal READ_VARIABLE_LENGTH
move $t0, $v0 # Store string length
move $t1, $v1 # Store the next addr to read from

# Allocate memory for the string
move $a0, $t0
addi $a0, $a0, 1 # Add space for \0
li $v0, 9
syscall
move $t2, $v0 # Store addr of memory

li $t3, 0 # Loop variable
READ_META_EVENT_TRACK_NAME_LOOP:
beq $t0, $t3, READ_META_EVENT_TRACK_NAME_END

# Read section
lb $t4, 0($t1)
move $t5, $t2
add $t5, $t5, $t3
sb $t4, 0($t5)

addi $t1, $t1, 1
addi $t3, $t3, 1
j READ_META_EVENT_TRACK_NAME_LOOP

READ_META_EVENT_TRACK_NAME_END:
# Add null termination
add $t0, $t0, $t2
sb $0, 0($t0)

# Print track name
la $a0, trackNameText
li $v0, 4
syscall

move $a0, $t2
li $v0, 4
syscall

la $a0, newLine
li $v0, 4
syscall

move $a0, $t1
j READ_TRACK_EVENT


READ_META_EVENT_END_OF_TRACK:
#Increase track we're on by 1
addi $s5, $s5, 1
j READ_CHUNK


READ_META_EVENT_SET_TEMPO:
# a1: Next Datta Addr
# s0: File Descriptor
# s1: Number of Tracks
# s2: Divisions per quarter note
move $t0, $0
lbu $t1, 1($a1)
add $t0, $t0, $t1
sll $t0, $t0, 8
lbu $t1, 2($a1)
add $t0, $t0, $t1
sll $t0, $t0, 8
lbu $t1, 3($a1)
add $t0, $t0, $t1

move $s3, $t0
addi $a0, $a1, 4
j READ_TRACK_EVENT


READ_META_EVENT_TIME_SIGNATURE:
# a1: Next Datta Addr
# s0: File Descriptor
# s1: Number of Tracks
# s2: Divisions per quarter note
# Text
la $a0, timeSignatureText
li $v0, 4
syscall

# Numerator
lb $a0, 1($a1)
li $v0, 1
syscall

# Slash
la $a0, forwardSlash
li $v0, 4
syscall

# Denominator
li $a0, 1
lb $t0, 2($a1)
sllv $a0, $a0, $t0
li $v0, 1
syscall

# New Line
la $a0, newLine
li $v0, 4
syscall

lbu $t0, 0($a1)
add $a0, $a1, $t0
addi $a0, $a0, 1
j READ_TRACK_EVENT


READ_CHANNEL_VOICE:
# Save command
move $s7, $t0

# Determine Command
beq $t0, 0x80, READ_CHANNEL_VOICE_NOTE_OFF
beq $t0, 0x90, READ_CHANNEL_VOICE_NOTE_ON
beq $t0, 0xB0, READ_CHANNEL_VOICE_CONTROL_CHANGE
beq $t0, 0xC0, READ_CHANNEL_VOICE_PROGRAM_CHANGE
beq $t0, 0xE0, READ_CHANNEL_VOICE_PITCH_WHEEL_CHANGE

# Unknown track event, stop
la $a0, unknownTrackEvent
li $v0, 4
syscall

move $a0, $t1
li $v0, 34
syscall

la $a0, newLine
li $v0, 4
syscall

li $v0, 10
syscall


READ_CHANNEL_VOICE_NOTE_OFF:
# a1: Next Datta Addr
# s0: File Descriptor
# s1: Number of Tracks
# s2: Divisions per quarter note
# s3: Tempo (if found)
# s4: Milliseconds into track (found using delta-time, tempo, & divisions)
# s5: Track converting
# s6: Array of Track End Node Ptrs

# Save data addr
move $t0, $a1

# Prepare arguments for end note
move $a0, $s4	# End time
lbu $a1, 0($t0)# Pitch

addi $sp, $sp, -4
sw $t0, 0($sp)
jal LL_END_NOTE
lw $t0, 0($sp)
addi $sp, $sp, 4

addi $a0, $t0, 2
j READ_TRACK_EVENT


READ_CHANNEL_VOICE_NOTE_ON:
# a1: Next Datta Addr
# s0: File Descriptor
# s1: Number of Tracks
# s2: Divisions per quarter note
# s3: Tempo (if found)
# s4: Milliseconds into track (found using delta-time, tempo, & divisions)
# s5: Track converting
# s6: Array of Track End Node Ptrs

# Save data addr
move $t0, $a1

# Prepare arguments for new note
move $a0, $s4	# Start time
lbu $a1, 0($t0)# Pitch
move $a2, $0	# Instument is not yet implemented (don't know how)
lbu $a3, 1($t0)# Volume

# Add note
addi $sp, $sp, -4
sw $t0, 0($sp)
jal LL_NEW_NOTE
lw $t0, 0($sp)
addi $sp, $sp, 4

addi $a0, $t0, 2
j READ_TRACK_EVENT


READ_CHANNEL_VOICE_CONTROL_CHANGE:
# a1: Next Datta Addr
# s0: File Descriptor
# s1: Number of Tracks
# s2: Divisions per quarter note

# Skips message - not currently in-scope of this project
addi $a0, $a1, 2
j READ_TRACK_EVENT


READ_CHANNEL_VOICE_PROGRAM_CHANGE:
# a1: Next Datta Addr
# s0: File Descriptor
# s1: Number of Tracks
# s2: Divisions per quarter note

# Skips message - not currently in-scope of this project
addi $a0, $a1, 1
j READ_TRACK_EVENT


READ_CHANNEL_VOICE_PITCH_WHEEL_CHANGE:
# a1: Next Datta Addr
# s0: File Descriptor
# s1: Number of Tracks
# s2: Divisions per quarter note

# Skips message - not currently in-scope of this project
addi $a0, $a1, 2
j READ_TRACK_EVENT


FILE_FINISHED:
# s0: File Descriptor
# s1: Number of Tracks
# s5: Track converting
# s6: Array of Track End Node Ptrs

# Alert that the file has been read
li $v0, 4
la $a0, fileReadText
syscall

# Close File
move $a0, $s0
li $v0, 16
syscall

# Starting to merge tracks
la $a0, mergingText
li $v0, 4
syscall


MERGE_SORT:
# s1: Number of Tracks
# s6: Array of Track End Node Ptrs

# Setup for loop
lw $t0, 0($s6)	# Sorted Linked List
move $t3, $0	# Tail PTR
move $t4, $0	# Counter

MERGE_SORT_START:
# Add to Counter
addi $t4, $t4, 1
# End of count?
beq $t4, $s1, MERGE_SORT_END

# Move t0 to list 1, and fetch list 2
move $t1, $t0 # Linked List 1
move $t0, $0  # Sorted Linked List

sll $t5, $t4, 2
add $t5, $t5, $s6
lw $t2, 0($t5) # Linked List 2

MERGE_SORT_LOOP:
# Check if at the end
beq $t1, $t2, MERGE_SORT_START # Should only be equal when both links are null/$0

# Check if one is empty
beqz $t1, MERGE_SORT_SWAP# T1 = 0
beqz $t2, MERGE_SORT_HEAD# T2 = 0

#Compare Time Start
lw $t5, 4($t1)
lw $t6, 4($t2)

sltu $t5, $t5, $t6
beqz $t5, MERGE_SORT_HEAD

MERGE_SORT_SWAP:
# Swap $t1 and $t2 as we want to take node from $t1
move $t5, $t1
move $t1, $t2
move $t2, $t5

MERGE_SORT_HEAD:
# Empty t0, set it to t1
bnez $t0, MERGE_SORT_TAIL
move $t0, $t1
j MERGE_SORT_LINK

MERGE_SORT_TAIL:
# Non-empty t0, link the tail to the new
sw $t1, 0($t3)

MERGE_SORT_LINK:
move $t3, $t1
lw $t1, 0($t1)
j MERGE_SORT_LOOP

MERGE_SORT_END:
# Change Backward pointers to forward
move $t1, $0

RELINK_LOOP:
# s1: Number of Tracks
# s6: Array of Track End Node Ptrs
beqz $t0, RELINK_END

lw $t2, 0($t0)
sw $t1, 0($t0)
move $t1, $t0
move $t0, $t2
j RELINK_LOOP

RELINK_END:
move $s2, $t1

la $a0, mergedText
li $v0, 4
syscall


PLAY_SONG:
# s1: Number of Tracks
# s2: Start Pointer
la $s0, max_ms_before_delay

PLAY_NOTE:
# End?
beq $s2, $0, PROGRAM_DONE

# Get note from pointer
lbu $a0, 12($s2)
#lbu $a2, 13($s2)
li $a2, 1
lbu $a3, 14($s2)
lw $a1, 8($s2)

beqz $a1, NOTE_PLAYED # Too long

li $v0, 31
syscall

NOTE_PLAYED:
# Determine whether we immeditly play or skip
lw $t0, 4($s2)
lw $s2, 0($s2)
lw $t1, 4($s2)

sub $a0, $t1, $t0
li $v0, 32

bgt $a0, $s0, PLAY_NOTE #Note too short
syscall
j PLAY_NOTE


PROGRAM_DONE:
li $v0, 10
syscall


SWAP_ENDIAN:
# a0: value to swap
# v0: swapped value
li $v0, 0 # Reset output
li $t0, 0 # Loop count

SWAP_ENDIAN_LOOP:
beq $t0, 4, SWAP_ENDIAN_END
andi $t1, $a0, 0xFF
srl $a0, $a0, 8
sll $v0, $v0, 8
add $v0, $v0, $t1 

addi $t0, $t0, 1
j SWAP_ENDIAN_LOOP

SWAP_ENDIAN_END:
jr $ra


GET_CHUNK_LENGTH:
#a0: file descriptor
#v0: chunk length
li $v0, 14
la $a1, buffer
li $a2, 4
syscall

addi $sp, $sp, -4
sw $ra, 0($sp)
lw $a0, buffer
jal SWAP_ENDIAN
lw $ra, 0($sp)
addi $sp, $sp, 4

jr $ra


READ_CHUNK_DATA:
#a0: file descriptor
#v0: addr of read data
#v1: data size

# Get size to read
addi $sp, $sp, -4
sw $ra, 0($sp)
jal GET_CHUNK_LENGTH
lw $ra, 0($sp)
addi $sp, $sp, 4

move $t0, $v0 # Chunk length

# Allocate memory for that size
li $v0, 9
move $a0, $t0
syscall
move $t1, $v0

# Read the chunk from file
li $v0, 14
move $a0, $s0
move $a1, $t1
move $a2, $t0
syscall

bne $v0, $t0, MALFORMED_FILE

move $v0, $t1
move $v1, $t0
jr $ra


READ_VARIABLE_LENGTH:
#a0: addr of variable
#v0: output
#v1: next data address
li $v0, 0 # Prepare the output
move $v1, $a0
# Create the 32-bit word that could be the variable
rem $t1, $a0, 4		# t1: Offset
sub $t2, $a0, $t1	# t2: byte-aligned register addr
sll $t1, $t1, 3		# put offset in units of bits
# First Word
lw $t0, 0($t2)		# t0: word to search
srlv $t0, $t0, $t1
beqz $t1, READ_VARIABLE_LENGTH_CONVERT
# Second Word
li $t3, 32
sub $t3, $t3, $t1
lw $t1, 4($t2)
sllv $t1, $t1, $t3
# Combine
or $t0, $t0, $t1

READ_VARIABLE_LENGTH_CONVERT:
andi $t1, $t0, 0x7F # Mask the data
sll $v0, $v0, 7 # Move the output over
or $v0, $v0, $t1 # add the data

addi $v1, $v1, 1 # byte has been read, move output over

andi $t2, $t0, 0x80
beqz $t2, READ_VARIABLE_LENGTH_END # Check if the end bit is set
srl $t0, $t0, 8 # Otherwise check next byte
j READ_VARIABLE_LENGTH_CONVERT

READ_VARIABLE_LENGTH_END:# bye!
jr $ra


DELTA_TIME_TO_MS:
# a0: Delta Time
# s2: Divisions per quarter note
# s3: Tempo (if found o.w. 0)
# v0: Output in MS

#Uses floating point operations, determine if too slow

# f0: Delta time
la $t0, buffer
sw $a0, 0($t0)
lwc1 $f0, 0($t0)
cvt.d.w $f0, $f0

# f2: Divisions per quarter note
la $t0, buffer
sw $s2, 0($t0)
lwc1 $f2, 0($t0)
cvt.d.w $f2, $f2

# f4: Tempo
la $t0, buffer
sw $s3, 0($t0)
lwc1 $f4, 0($t0)
cvt.d.w $f4, $f4

# f6: 1000
la $t0, buffer
li $t1, 1000
sw $t1, 0($t0)
lwc1 $f6, 0($t0)
cvt.d.w $f6, $f6

# Calculate ms using delta-time * (tempo)/(divisions * 1000)
div.d $f8, $f4, $f2
div.d $f8, $f8, $f6
mul.d $f10, $f0, $f8 

cvt.w.d $f10, $f10
swc1 $f10, 0($t0)

lw $v0, 0($t0)
jr $ra


LL_NEW_NOTE:
# a0: Start time
# a1: Pitch (0-127)
# a2: Instrument (0-127)
# a3: Volume (0-127)
# s5: Track converting
# s6: Array of Track End Node Ptrs
# v0: Pointer to Node (Tail node)

move $t0, $a0
# Request Node memory
li $a0, 16
li $v0, 9
syscall

sll $t2, $s5, 2
add $t2, $s6, $t2 
lw $t1, 0($t2)

#Store data
sw $t1,  0($v0) # Backwards pointer
sw $t0,  4($v0) # Start time
sw $0 ,  8($v0) # Duration
sb $a1, 12($v0) # Pitch
sb $a2, 13($v0) # Instrument
sb $a3, 14($v0) # Volume
sb $0 , 15($v0) # MIDI Channel no (Not implemented)

# Update tail pointer
sw $v0, 0($t2)
jr $ra


LL_END_NOTE:
# a0: End time
# a1: Pitch (0-127)
# s5: Track converting
# s6: Array of Track End Node Ptrs
# v0: Pointer to Ended Node

sll $t2, $s5, 2
add $t2, $s6, $t2 
lw $t0, 0($t2)

LL_END_NOTE_LOOP:
# Load Pitch
lbu $t1, 12($t0)

# Correct Note?
beq $a1, $t1, LL_END_NOTE_FOUND

# Read Back Pointer
lw $t1, 0($t0)

# Check that back pointer is valid
beqz $t1, LL_END_NOTE_NO_START

# Jump back one node
move $t0, $t1
j LL_END_NOTE_LOOP

LL_END_NOTE_NO_START:
la $a0, noteEndedNotStarted
li $v0, 4
syscall
j MALFORMED_FILE


LL_END_NOTE_FOUND:
# Get Time Start
lw $t1, 4($t0)

# Calculate duration
subu $t1, $a0, $t1

# Save duration
sw $t1, 8($t0)

move $v0, $t1
jr $ra
