#BASIC INTERRUPT EXAMPLE
#In order to use the following program correctly, you'll need to go into the tools menu and open up
#the "Keyboard and Display Emulator" from the dropdown menu. Assemble the program, run it, and press
#The "Connect to MIPS" button on the dialog. Once the emulator is connected,  anything you type in the
#bottom box (the input box) should appear in the top (display box).

#This is accomplished using an interrupt handler, which is not all that difficult to implement. A
#polling method could also be implemented to accomplish the same task, with somewhere between a 100
#to 200 percent chance of MARS exploding in your face while using it. So don't.

#I reccomend reading the Keyboard and Display Emulator's (KDE's) "Help" dialog to read how it works.
#If you don't, I've placed a summary in the Test folder titled "howtokde.txt"

#This is probably how we are going to go about doing the display. The print subroutine will be part of kernel mode data,
#and will be called every time a key is pressed. In the mean time the program will be running in a loop that will trigger
#a trap every time more than a second passes, which will be handled by the same interrupt handler as the one that handles a keypress.
#the alternative would be to write a clock device that would write the system time to a pair of registers in MMIO. Daleb would do that.
#Because the KDE does not support most control characters by default, I have written a very slightly
#modified jar file (currently in my Src folder) that allows the use of '\f' (ASCII 12) to clear the screen and the keyboard input box.


#INTERRUPT HANDLER (only runs when a key is pressed):
.ktext 0x80000180 #kernel mode instruction data follows. "0x80000180" signifies the location of the instructions in memory. This address is required by MARS.
#uncomment the two following lines to see the custom jarfile in action.
li $k0, 13
sb $k0, 0xffff000c
lbu $k0, 0xffff0004 #loads the character typed into the keyboard
sb $k0, 0xffff000c #stores that character into the display byte.
eret #returns to the program

#Program Proper (execution starts here):
.text
li $t0, 0xffff0000
li $t1, 0x00000002
sw $t1 0($t0) #stores a 1 into the KDE's keyboard interrupt-enable bit (the second bit in 0xffff0000). before this instruction, pressing buttons on they keyboard won't do anything.
loop:
j loop #loops over and over again so you can see the interrupts in action.

