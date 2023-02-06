# FWAV V1.1
 Flashjacks Wave Loader


First:
sjasm.exe FWAV.asm FWAV.COM


Sources:

https://retromsx.com


Synthesis “FWAV.COM”

It consists of a system to play WAVs in full PCM and ADPCM format. This module allows you to play songs, pause them, fast-forward, slow-down and stop them, all resident, which means that neither the MSX nor the SD card slows down. But the thing does not stop there. Also by means of a .LST file we can program a battery of songs to a series of conditions that allows us to replace the original songs of the games, leaving only those audio channels that interest us.

It really seems like pure magic and the end result is spectacular as there is no need to patch the game because Flashjacks works by monitoring the RAM and Z80 of the MSX and not the game program.

The FWAV instructions are as follows:

FWAV AUDIO.WAV or LIST.LST or commands.

The FWAV commands are as follows:

/s STOP. Stops any resident songs.

/p PLAY. Play or continue the song either individually or from a list.

/t PAUSE. Pause the song.

/n NEXT. Advances a song in the list.

/b BACK. Go back one song in the list. 

In addition, we have a system through a programmable list .LST.

This listing consists of instructions. Each instruction always starts with ¨@¨ and ends with “;”. Later, comments can be placed to improve its understanding.

Within the instruction the parameters are separated by “,” following an ascending order.
	


In the first position is the order numeral which should never be repetitive between instructions. It has a limit of 40h instructions (Numbers always in hexadecimal). That is, 64 + the 0 = 65 independent instructions.

In the second position is the command to execute, these being the possible ones:
- 00 or others not mentioned: Not applicable. It doesn't do anything.
- 01 Load a song without a loop when the condition is met.
- 02 Load a looped song when the condition is met.
- 03 FadeOutL length of the current song when the condition is met.
- 04 Stop stops the current song when the condition is met.
- 05 Pause ON. Pauses the current song when the condition is met.
- 06 PauseOFF It recovers after the pause when the condition is fulfilled.
- 07 VolLevel. Adjusts the overall audio level of the WAV. This is used to level the audio of the song with the effects.
- 08 Short FadeOutC of the current song when the condition is met.
- 09 ChangeMuteChannel. It only changes the mutes of all channels when the condition is met without affecting the current song. If the condition is not met, it loads the mutes of the current song.
- 0A LoadPrevMus. Load the previous song when the condition is met.
- 0B Conditional Mute. It changes to the mute value of this instruction only when it meets the condition and when it doesn't, it restores the previous state. This is recovered to its previous state unlike command 09.
- 0C Load looped song but with conditional mute, loading the previous value of Premute and saving the mute value from this instruction to use when the conditional mute returns. In short, it would be a simultaneous 02 + 0B instruction.

In the third position is the file name of the song in 8 + 3 character format.

In the fourth position is the RAM address in 16bits(64kB) to monitor.

In the fifth position is the RAM value where the instruction would act.

In the sixth instruction is the PSG+SCC mute where the bits: 01234 correspond in order to the 5 corresponding SCC channels and bits 567 correspond in order to the 3 PSG channels. Watch out! The number of the bits goes from greater to lesser weight to complete a byte 765 channel 321 PSG and 43210 channel 54321 SCC.

In the seventh instruction corresponds to the FM channels. 0123456 are the first 6 FM channels and 7 corresponds to channel 7 and 8 plus percussion. Same as the SCCPSG. The numeral is from highest to lowest weight 7-6543210.


As you can see, it is a very powerful tool that allows our WAVs (always in PCM or ADPCM) to infiltrate the game. You have to find those RAM positions where the game records the number of the song, program it and that's it. With this, we can infer a wide variety of games and place the songs that we see fit.

A milestone in the history of MSX !!!

And a second life to our favorite games.
