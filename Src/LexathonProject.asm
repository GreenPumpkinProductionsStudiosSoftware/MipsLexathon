# lexdict9 is loaded at 0x10040000, lexdict is loaded at 0x1005a000, the plausible words list is loaded at 0x100bad20
#solutions list is loaded at 0x10110000, solution to compare loaded at 0x10058d00

#KERNEL DATA#####################################################################################################################
.ktext 0x80000180 #this lets you code in the interrupt section!
#need to make it so this branches dependent on whether the interrupt was caused by the keyboard or the timer or the display.
#Kernel instructions are only called under two conditions:
#	1.Keypress (exception code 0)
#	2.Clock interrupt (thrown every second when clock interrupt bit is set to one.) 
#         (Exception code 13)
#Both of these interrupts are thrown through the KeyboardandDisplayEmulator class. 
#saved registers are reserved for kernel data.

mfc0 $s1, $13 # $13 is cause register
srl $s1, $s1, 2
andi $s1, $s1, 31 # $a0=exception code
beq $s1, $0, keyboardInterrupt #Clock interrupt is not 0, and that is all we care about.

clockInterrupt:
	li $s1, timer
	subi $s1, $s1, 1
	sw $s1, timer

keyboardInterrupt:
	#checkIndexBuffer
	#set t5 to a number that stores the first byte of the inputBuffer
	lb $t5, inputBuffer($0)
	beq $t5, $0, loadChar
	eret

loadChar:
	lbu $k0, 0xffff0004 #loads the character typed into the keyboard
	addi $s6, $0, 13 #loads enter
	beq $k0, $s6, compareByEnter

addCharIntoBuffer:
	#checkIndexBuffer Location
	addi $t5, $0, 1
	lb $k1, inputBuffer($t5)
	addi, $k1, $k1, 3
	#write
	sb $k0, inputBuffer($k1)
	eret #returns to the program

compareByEnter:
	#set read byte to 1
	addi $k1, $0, 1
	sb $k1, inputBuffer($0)
	eret
#END KERNEL DATA :3##############################################################################################################

.data
lexdict9: .asciiz "lexdict9.txt"
lexdict:  .asciiz "lexdict.txt"
inputBuffer: .byte 0,0,'A','C','E','R','T','V','B','G','Y'
timer: .word 100
lost: .asciiz "\nYou lost lolol"
winrar: .asciiz "like a baws"
answerCount: .word 0
timeString: .asciiz "000 seconds"

.text
startInput:
li $t0, 0xffff0000
li $t1, 0x00000002
sw $t1 0($t0) #stores a 1 into the KDE's keyboard interrupt-enable bit (the second bit in 0xffff0000). before this instruction, pressing buttons on they keyboard won't do anything.

main:
	addi $a0, $0, 0x10040000 #loads dictionary9 into 0x10040000, don't know if we actually want it there
	jal generatearray
	move $t0, $v0
	
	li $v0, 13	
	la $a0, lexdict
	li $a1, 0
	li $a2, 0
	syscall
	move $a0, $v0
	addi $a1, $0, 0x1005a000 # loads dictionary into 0x1005a000
	jal readfile
	
	move $v0, $t0
	jal drawgrid
	jal getplausiblewords
	jal createsolutionsstring
	li $v0, 4
	la $a0, 0x10110000
	syscall
	li $v0, 10
	syscall

clockLoop:
	la $a3, timer($0)
	beqz $a3, lostCondition
	#jal drawgui
	j clockLoop

lostCondition:
	li $v0, 4
	la $a0, lost
	syscall
	li $v0, 10
	syscall

wonCondition:
	li $v0, 4
	la $a0, winrar
	li $v0, 10
	syscall

checkToFindAnswerCount:
	#loop through array of characters, when letter=13, add 1
	lb $a0, answerCount
	li $a2, 10
	li $t1, 0
	answerCounter:
	lb $a1, answerCount($t1)
	bne $a1, $a2, ansCtr
	addi $a0, $a0, 1
	ansCtr:
	addi $t1, $t1, 1
	beqz $a1, wonCondition
	j answerCounter

checkInput:



#Loads the dictionary into a specified address, selects a random word, jumbles it, and returns the starting address of the word. 
#arguments: a0=address to start loading the dictionary. returns $v0, the address of the selected (and jumbled)word. 
generatearray:
	#stack push
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $t0, 4($sp)
	sw $t1, 8($sp)
	sw $a1, 12($sp)

	move $t0, $a0
	
	li $v0, 13
	la $a0, lexdict9
	li $a1, 0
	li $a2, 0
	syscall
	
	#load the entire file into the provided address 
	move $a0, $v0
	move $a1, $t0
	jal readfile

	#get the system time so i can use it as a seed
	li $v0, 30
	syscall

	#set the seed
	move $a1, $a0 #seed will be system time.
	li $a0, 1     #random number generator id will be one.  li $v0, 40
	syscall
		
	#generate random number	
	li $v0, 42
	li $a1, 9199
	syscall	
	
	#jumble the word at the appropriate address.	
	li $t1, 11 #IMPORTANT: windows users (AKA everyone else) need to change this to eleven before running.
	multu $a0, $t1
	mflo $a0
	addu $a0, $a0, $t0
	li $a1, 9
	jal jumble  
	
	move $v0, $a0
	
	#stack pop
	lw $ra, 0($sp)
	lw $t0, 4($sp)
	lw $t1, 8($sp)
	lw $a1, 12($sp)
	addiu $sp, $sp, 16
	jr $ra
	
strcpr:#takes arguments a0=the address of the first string, a1=the address of the second string. returns v0=1 if strings match, v0=0 if they do not.
	#stack push
	addiu $sp, $sp, -20
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $a0, 8($sp)
	sw $a1, 12($sp)
	sw $t2, 16($sp)
	
	strcprloop:	
		li $t2, 10
		lb $t0, ($a0)
		lb $t1, ($a1)
		bne $t1, $t0, strcprfalse
		beq $t1, $t2, strcprtrue #if t1 is equal to \n and we know t1 and t0 are equal, then we can conclude that we have reached the end of the strings and that the strings are equal. 
					 #note that in order for this function to work, both strings must be \n-terminated.
		addiu $a0, $a0, 1
		addiu $a1, $a1, 1
		j strcprloop
	strcprfalse:
		addu $v0, $0, $0
		j strcprexit	
	strcprtrue:
		addiu $v0, $0, 1
		j strcprexit
	strcprexit:
		#stack pop
		lw $t0, 0($sp)
		lw $t1, 4($sp)
		lw $a0, 8($sp)
		lw $a1, 12($sp)
		lw $t2, 16($sp)
		addiu $sp, $sp, 20 
		jr $ra			
	
readfile: #reads all lines from a file file. arguments: a0= file descriptor a1=address of input buffer.  returns v0, the file status
	#stack push	
	addiu $sp, $sp, -12
	sw $a2, 0($sp)
	sw $a0, 4($sp)
	sw $a1, 8($sp)
	
	addiu $a2, $0, 16 #read EVERY character
	readlineloop:
		li $v0, 14
		syscall
		beq $v0, $0 readlineend #a status of zero means that the read has hit end of file	
		addiu $a1, $a1, 16 #store the next character in the next byte.	
	j readlineloop
	readlineend:
		#stack pop
		lw $a2, 0($sp)
		lw $a0, 4($sp)
		lw $a1, 8($sp)
		addiu $sp, $sp, 12
		jr $ra	

jumble:#jumbles a string. arguments: a0:address of string to jumble. a1:length of string.
	#stack push
	addiu $sp, $sp, -24
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)	
	sw $a0, 12($sp)
	sw $a1, 16($sp)
	sw $v0, 20($sp)

	move $t1, $a0 #address now also contained in t1.
	addu $t0, $a0, $a1 #t0 now contains the final address in the string
	addiu $a1, $a1, -1#alignment for starting the string with the 1st character instead of the 0th
	jumbleloop:	
		beq $t1, $t0, endjumble #we flop each character in the thing once.
		li $v0, 42 

		move $a0, $a1

		syscall #generate a random number between 0 and the length of the string starting at 1
		
		addiu $a0, $a0, 1 #alignment for starting the string with the 1st character instead of the 0th
		subu $t2, $t0, $a0 #the character in address $t1 will be flipped with the character in the address $t2
		lb $a0, ($t2) #flips each character in the string with another random character in the string.
		lb $v0, ($t1)
		sb $a0, ($t1)
		sb $v0, ($t2)	
		addiu $t1, $t1, 1
	j jumbleloop
	endjumble:
		#stack pop
		lw $t0, 0($sp)
		lw $t1, 4($sp)
		lw $t2, 8($sp)	
		lw $a0, 12($sp)
		lw $a1, 16($sp)
		lw $v0, 20($sp)
		addiu $sp, $sp, 24
		jr $ra
	
shuffle: # $v0 is address of word to jumble
	addiu $sp, $sp, -4 # store $ra in the stack
	sw $ra, ($sp)

	move $a0, $v0  # sets $a0 to address of word to jumble
	addi $a1, $0, 0x00000009 # sets $a1 to 9, the length of the string
	jal jumble	# jumbles word
	
	lw $ra, ($sp) # reloads return address
	addiu $sp, $sp, 4
	jr $ra
	
#Finds all words in the dictionary that contain the central letter		
#arguments: $v0=address of puzzle string
getplausiblewords:
	lb $t0, 0($v0) # loads letter to search for into $t0
	li $t1, 0 # initializes register to count how many chars have been looked at since last new line
	li $t3, 0 # initializes register to count how many chars have been looked at total
	li $t4, 0 # index in plausible word list
	wordloop:
		lb $t2, 0x1005a000($t3) # loads next byte in dictionary
		addi $t1, $t1 1 # $t1++
		addi $t3, $t3 1 # $t3++
		beq $t2, $t0, found # branches if letter is found
		beq $t2, 0x0000000a, newline # branches if byte is new line
		beq $t2, 0x00000000, end # signals that all data has been read
		j wordloop
	found:
		sub $t3, $t3, $t1 # decrements counter back to last new line
		foundloop:
			lb $t2, 0x1005a000($t3) # loads next byte in dictionary
			sb $t2, 0x100bad20($t4) # adds byte to plausible word list
			addi $t3, $t3, 1 # $t3++
			addi $t4, $t4, 1 # $t4++
			beq $t2, 0x0000000a, newline # branches if byte is new line
			beq $t2, 0x00000000, end # signals that all data has been read
			j foundloop
	newline:
		move $t1, $0 # resets counter to 0
		j wordloop
	end:
		jr $ra

#Creates a \f-terminated string containing the solution to the given puzzle
#Arguments: $v0=address of puzzle string
createsolutionsstring:
	move $a0, $v0 # puts address of string into $a0
	move $t0, $0 # resets counter for number of characters in possible solution string
	move $t1, $0 # prepares counter for solutions list
	move $t3, $0 # counter for copy location
	
	addiu $sp, $sp, -4 # saves return address
	sw $ra, ($sp)
	
	createloop:
		lb $t2, 0x100bad20($t0) # loads byte for comparison
		sb $t2, 0x10058d00($t3) # moves byte to copy location
		sb $t2, 0x10058d20 ($t3) # restores byte
		addi $t0, $t0, 1 #$t0++
		addi $t3, $t3, 1 #$t3++
		beq $t2, 0x0000000a, callcombochecker
		beq $t2, 0x00000000, endsolutions # ends if bottom is reached
		j createloop
		callcombochecker:
			la $a1, 0x10058d00 #loads address of where word is loaded
			jal combochecker
			beq $v0, 1, matchfound # branch if combochecker finds a possible solution
			move $t3, $0 # resets counter for copy location
			j createloop
		matchfound:
			move $t3, $0 #resets counter
			matchfoundloop:
				lb $t2, 0x10058d20($t3) # loads next byte
				sb $t2, 0x10110000($t1) # adds byte to solutions list
				addi $t1, $t1, 1 # $t1++
				addi $t3, $t3, 1 #$t0++
				beq $t2, 0x0000000a, matchend # branches if byte is new line
				beq $t2, 0x00000000, matchend # branches if no more data
				j matchfoundloop
			matchend:
				move $t3, $0
				j createloop
	endsolutions:
		addi $t2, $0, 0x000000c # puts a null terminator at the end of the solutions list
		sb $t2, 0x10110000($t1)
		lw $ra, ($sp) # reloads return address
		addiu $sp, $sp, 4
		move $v0, $a0 # restores address of jumbled word to $v0
		jr $ra

#Determines whether the characters in one \n-terminated string are a subset of the characters in another. 
#Arguments: a0=address of first string. a1=address of subset(?). returns v0=1 if a1 is a subset
combochecker: 	
	addiu $sp, $sp, -24
	sw $t0, ($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $t3, 12($sp)
	sw $a0, 16($sp)
	sw $a1, 20($sp)

	li $t1, 10 #ASCII 10 = '\n'. Used as constant; we will need to make this comparison frequently
	checka0loop:
		lb $t3, ($a0) #character being searched for in subset string is in $t3
		beq $t3, $t1, comboloopexit #if that character is \n, then we have hit the end of the string.
		move $t0, $a1
		checka1loop:
			lb $t2, ($t0)
			beq $t2, $t1, a1loopexit #if read hits \n, time to search for a different character
			bne $t2, $t3, noclearchar
				sb $0 ($t0) #executes if we have found the character we are looking for 
				j a1loopexit
			noclearchar:
				addiu $t0, $t0, 1
				j checka1loop
		a1loopexit:
			addiu $a0, $a0, 1
			j checka0loop
	comboloopexit:
	#then it sums up the string
	move $t0, $a1	
	move $t3, $0	
	sumchars:
		lb $t2 ($t0)
		beq $t2, $t1, combosetv0
		addu $t3, $t3, $t2
		addiu $t0, $t0, 1
		j sumchars
	combosetv0:
		bne $t3, $0 comboreturn0 
			li $v0, 1 #executes if $t3=0
			j comboexit
		comboreturn0:
			move $v0, $0 #executes if $t3!=0, meaning there are non-null characters in the string.
			j comboexit
	comboexit:
		lw $t0, ($sp)
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		lw $t3, 12($sp)
		lw $a0, 16($sp)
		lw $a1, 20($sp)
		addiu $sp, $sp, 24
		jr $ra

#checks to determine whether the *answo* is in the \f-terminated solution list. 
#Argumants: a0: address of inputted string, a1: the starting address of the solutions list. returns v0=0 if no match is found, returns v0= address of word in list if found.
checkanswo:
	addiu $sp, $sp, -24
	sw $t0, ($sp)
	sw $t1, 4($sp)
	sw $a0, 8($sp)
	sw $a1, 12($sp)
	sw $ra, 16($sp)
	sw $t2, 20($sp)

	li $t1, 10
	li $t2, 13
	loope:
		jal strcpr #compares the word.
		bne $v0, $0, searchpositive #if that word is the same as the one the user typed in, then that solution is valid.
		findnextword:#finds the next word by checking each byte until it finds a \n, and then increments a1 to the address after it.
			addiu $a1, $a1, 1
			lb $t0, ($a1) 
			beq $t0, $t2, loopeagain
			beq $t0, $t1, loopeagain #if the character at $a1 is an \n or \r, then we're ready to read a word.
			j findnextword	
			loopeagain:	
				addiu $a1, $a1, 1 #IMPORTANT: windows users change this to a two before running. I think.
				lb $t0, ($a1)
				beq $t0, $t2, searchnegative	#this is important becuase it ensures we don't try and read past the end of the word list. The last word in the lest should end with a \n,
								#which would normally set the program back to loope. this prevents this by checking for the terminating character, which we have assigned to be
								#\f 	
				j loope
	searchpositive:
		move $v0, $a1
		j answoexit
	searchnegative:
		move $v0, $0
		j answoexit
	answoexit:
		lw $t0, ($sp)
		lw $t1, 4($sp)
		lw $a0, 8($sp)
		lw $a1, 12($sp)
		lw $ra, 16($sp)
		lw $t2, 20($sp)
		addiu $sp, $sp, 24
		jr $ra
	
nullterminate:#converts a \n-terminated string into a null-terminated string. arguments: a0= address of string to NULL THE TERMINATE
	addiu $sp, $sp, -12
	sw $t0, ($sp)
	sw $t1, 4($sp)
	sw $a0, 8($sp)

	li $t1, 10	
	nullterminateloop:
		lb $t0, ($a0)
		beq $t0, $t1, nullify
		addiu $a0, $a0, 1
		j nullterminateloop
	nullify:
		sb $0, ($a0)
		
		lw $t0, ($sp)
		lw $t1, 4($sp)
		lw $a0, 8($sp)
		addiu $sp, $sp, 12
		jr $ra

drawgui: #prints grid display
	li $t1, 2
	la $t0, inputBuffer($t1)
	li $v0, 11
	lb  $a0, 1($t0) #prints first character
	syscall
	addi $a0, $0, 0x00000020 # prints a space
	syscall
	lb $a0, 2($t0) #prints second character
	syscall
	addi $a0, $0, 0x00000020 # prints a space
	syscall
	lb $a0, 3($t0) #prints third character
	syscall
	addi $a0, $0, 0x0000000A # prints new line
	syscall
	lb $a0, 4($t0) # prints fourth character
	syscall
	addi $a0, $0, 0x00000020 # prints a space
	syscall
	lb $a0, 0($t0) # prints middle character
	syscall
	addi $a0, $0, 0x00000020 # prints a space
	syscall
	lb $a0, 5($t0) # prints sixth character
	syscall
	addi $a0, $0, 0x0000000A # prints new line
	syscall
	lb $a0, 6($t0) # prints seventh character
	syscall
	addi $a0, $0, 0x00000020 # prints a space
	syscall
	lb $a0, 7($t0) # prints eighth character
	syscall
	addi $a0, $0, 0x00000020 # prints a space
	syscall
	lb $a0, 8($t0) # prints ninth character
	syscall
	addi $a0, $0, 0x0000000A # prints new line
	syscall
	addi $a0, $0, 0x0000000A # prints new line
	syscall
	jr $ra


userInputSection:
#time for all the input stuff

findsolutions:
#when the user enters a valid solution to the puzzle, this happens. 
#Arguments: a0=the address of the word in the solution list that needs to be moved. a1= address of \f-terminated found solutions list to append to.
horfdorf:
	addiu $sp, $sp, -20	
	sw $t0, ($sp)
	sw $t1, 4($sp)
	sw $t2, 8($sp)
	sw $a0, 12($sp)
	sw $a1, 16($sp)

	li $t1, 13 # form feed character for reference
	li $t2, 10 #newline character, for reference	
	findendofsolutions:
		lb $t0, ($a1)
		beq $t0, $t1, copy 
		addiu $a1, $a1, 1
		j findendofsolutions
	copy: #the address to the end of the solutions list is now in #a1
		li $t0, 44 #add a comma	
		sb $t0, ($a1)
		li $t0, 32 #add a space 
		sb $t0, 1($a1)
		addiu $a1, $a1, 2 #the string is now formatted and ready to append to. :3
		realcopy:
			lb $t0 ($a0)
			beq $t0, $t2, endhorf # exits copy when the loop hits the newline in the original string.
			sb $t0, ($a1)
			sb $0, ($a0)
			addiu $a0, $a0, 1
			addiu $a1, $a1, 1
			j realcopy
	endhorf:
		sb $t1, 1($a1) #terminate the solutions list with a \f
		li $t0, 12 #carriage return
		sb $t0, ($a0) #change the \n in the original string to a carriage return to make victory condition easier to determine
		
		lw $t0, ($sp)
		lw $t1, 4($sp)
		lw $t2, 8($sp)
		lw $a0, 12($sp)
		lw $a1, 16($sp)	
		addiu $sp, $sp, 20
		jr $ra
#Debug subroutines:
#drawgrid: # prints 3x3 grid of the word at the address stored in $v0
#	move $t0, $v0 #moves address of selected jumbled word to $t0
#	li $v0, 11
#	lb  $a0, 1($t0) #prints first character
#	syscall
#	addi $a0, $0, 0x00000020 # prints a space
#	syscall
#	lb $a0, 2($t0) #prints second character
#	syscall
#	addi $a0, $0, 0x00000020 # prints a space
#	syscall
#	lb $a0, 3($t0) #prints third character
#	syscall
#	addi $a0, $0, 0x0000000A # prints new line
#	syscall
#	lb $a0, 4($t0) # prints fourth character
#	syscall
#	addi $a0, $0, 0x00000020 # prints a space
#	syscall
#	lb $a0, 0($t0) # prints middle character
#	syscall
#	addi $a0, $0, 0x00000020 # prints a space
#	syscall
#	lb $a0, 5($t0) # prints sixth character
#	syscall
#	addi $a0, $0, 0x0000000A # prints new line
#	syscall
#	lb $a0, 6($t0) # prints seventh character
#	syscall
#	addi $a0, $0, 0x00000020 # prints a space
#	syscall
#	lb $a0, 7($t0) # prints eighth character
#	syscall
#	addi $a0, $0, 0x00000020 # prints a space
#	syscall
#	lb $a0, 8($t0) # prints ninth character
#	syscall
#	addi $a0, $0, 0x0000000A # prints new line
#	syscall
#	addi $a0, $0, 0x0000000A # prints new line
#	syscall
#	move $v0, $t0	#puts address of word back into $v0
#	jr $ra

getTimeString: #put into t4 the seconds, gets each number and makes a string
la $t4, timer
li $t5, 10
li $t6, 3
div $t4, $t5
mflo $t4
mfhi $t5
addi $t4, $t4, timeString($t6)
sb $t7, 
sb $t4, timeString($0)
li $t7, 10
div $t5, $t7
mflo $t4
mfhi $t5
addi $t4, $t4, 48
addi $t5, $t5, 48
li $t7, 1
sb $t4, timeString($t7)
li $t4, 2
sb $t5, timeString($t4)
jr $ra