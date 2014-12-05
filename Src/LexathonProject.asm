# lexdict9 is loaded at 0x10040000, lexdict is loaded at 0x1005a000, the plausible words list is loaded at 0x100bad20
#solutions list is loaded at 0x10110000, solution to compare loaded at 0x10058d00

.data
lexdict9: .asciiz "lexdict9.txt"
lexdict:  .asciiz "lexdict.txt"
sfound: .asciiz "found!\n"

.text
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

generatearray:#Loads the dictionary into a specified address, selects a random word, jumbles it, and returns the starting address of the word. arguments: a0=address to start loading the dictionary. returns $v0, the address of the selected word. 
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

	#get the system  time so i can use it as a seed
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
		beq $t1, $t2, strcprtrue #if t1 is equal to \n and we know t1 and t0 are equal, then we can conclude that we have reached the end of the strings and that the strings are equal. note that in order for this function to work, both strings must be \n-terminated.
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

	#move $t0, $a0 #address now contained in t0. this will be used for reference.
	move $t1, $a0 #address now also contained in t1.
	addu $t0, $a0, $a1 #t0 now contains the final address in the string
	addiu $a1, $a1, -1#alignment for starting the string with the 1st character instead of the 0th
	jumbleloop:	
		beq $t1, $t0, endjumble #we flop each character in the thing once.
		li $v0, 42 

		move $a0, $a1

		syscall #generate a random number between 0 and the length of the string starting at 1
		
		addiu $a0, $a0, 1#alignment for starting the string with the 1st character instead of the 0th
		subu $t2, $t0, $a0 #the character in address $t1 will be flipped with the character in the address $t2
		lb $a0, ($t2)#flips each character in the string with another random character in the string.
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
	la $a0, ($v0)  # sets $a0 to address of word to jumble
	addi $a1, $0, 0x00000009 # sets $a1 to 9, the length of the string
	jal jumble	# jumbles word
	jr $ra

drawgrid: # prints 3x3 grid of the word at the address stored in $v0
	move $t0, $v0 #moves address of selected jumbled word to $t0
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
	move $v0, $t0	#puts address of word back into $v0
	jr $ra
	
#drawclock:
	#sw 0xfff000c, timeVal
	
#drawwordlist: #if \n character, print comma #if print more than 80 characters, new line # words list not added #t0 is iterator
	
	#loop:
		#addi $t0, 0x00000001
		
		#beq $0, drawwordlistend
		#j loop
	#drawwordlistend:
		#jr $ra
		
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

createsolutionsstring:
	move $a0, $v0 # puts address of string into $a0
	move $t0, $0 # resets counter for number of characters in possible solution string
	move $t1, $0 # prepares counter for solutions list
	move $t3, $0 # counter for copy location
	createloop:
		lb $t2, 0x100bad20($t0) # loads byte for comparison
		sb $t2, 0x10058d00($t3) # moves byte to copy location
		addi $t0, $t0, 1 #$t0++
		addi $t3, $t3, 1 #$t3++
		beq $t2, 0x0000000a, callcombochecker
		beq $t2, 0x00000000, endsolutions # ends if bottom is reached
		j createloop
		callcombochecker:
			la $a1, 0x10058d00 #loads address of where word is loaded
			jal combochecker
			beq $v0, 0x00000001, matchfound # branch if combochecker finds a possible solution
			move $t3, $0 # resets counter for copy location
			j createloop
		matchfound:
			move $t3, $0 #resets counter
			matchfoundloop:
				lb $t2, 0x10058d00($t3) # loads next byte
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
		jr $ra

combochecker:#Determines whether the characters in one \n-terminated string are a subset of the characters in another. arguments: a0=address of first string. a1=address of subset(?). returns v0=1 if a1 is a subset 	
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
checkanswo:#checks to determine whether the *answo* is in the solution list. Argumants: a0: address of inputted string, a1: the starting address of the solutions list. returns v0=0 if no match is found, returns v0= address of word in list if found.
	addiu $sp, $sp, -20
	sw $t0, ($sp)
	sw $t1, 4($sp)
	sw $a0, 8($sp)
	sw $a1, 12($sp)
	sw $ra, 16($sp)

	li $t1, 10	
	loope:
		jal strcpr #compares the word.
		bne $v0, $0, searchpositive #if that word is the same as the one the user typed in, then that solution is valid.
		findnextword:#finds the next word by checking each byte until it finds a \n, and then increments a1 to the address after it.
			addiu $a1, $a1, 1
			lb $t0, ($a1)
			bne $t0, $t1, findnextword #if the character at $a1 is not a \n, keep looking for one.
				addiu $a1, $a1, 1 #IMPORTANT: windows users change this to a two before running. I think.
				lb $t0, ($a1)
				beq $t0, $0, searchnegative#this is important becuase it ensures we don't try and read past the end of the word list. The last word in the lest should end with a \n, and beyond there be dragons. Data dragons. Sucky MARS dragons.
							   #this would be if we wanted to null-terminate the solutions list. in reality this will probably be different. maybe instead of $0 ('\0' ) we terminate it with a form feed?
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
		addiu $sp, $sp, 20 
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
