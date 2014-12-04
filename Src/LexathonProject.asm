.data
lexdict9: .asciiz "lexdict9.txt"
lexdict:  .asciiz "lexdict.txt"
dictionary: .asciiz "aardvark\nkiwi\nabbot\nsuper\nbanana\ncream\nzebra\ndog\nfox\nfish\nwaffle\npig\nbird"

.text
main:
	addi $a0, $0, 0x10040000 #loads dictionary into 0x10040000, don't know if we actually want it there
	jal generatearray
	jal drawgrid
	jal getplausiblewords
	li $v0, 4
	addi $a0, $a0, 0x1005a000
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
	li $a0, 1     #random number generator id will be one.
	li $v0, 40
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

checkarray:
	
strcpr:#takes arguments a0=the address of the first string, a1=the address of the second string. returns v0=1 if strings match, v0=0 if they do not.
	#stack push
	addiu $sp, $sp, -16
	sw $t0, 0($sp)
	sw $t1, 4($sp)
	sw $a0, 8($sp)
	sw $a1, 12($sp)

	lb $t0, ($a0)
	lb $t1, ($a1)
	bne $t1, $t0, strcprfalse
	beq $t1, $0, strcprtrue #if t1 is equal to 0 and we know t1 and t0 are equal, then we can conclude that we have reached the end of the strings and that the strings are equal. note that in order for this function to work, both strings must be null-terminated.
	addiu $a0, $a0, 1
	addiu $a1, $a1, 1
	j strcpr
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
		addiu $sp, $sp, 16
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
		lb $t2, dictionary($t3) # loads next byte in dictionary
		addi $t1, $t1 1 # $t1++
		addi $t3, $t3 1 # $t3++
		beq $t2, $t0, found # branches if letter is found
		beq $t2, 0x0000000a, newline # branches if byte is new line
		beq $t2, 0x00000000, end # signals that all data has been read
		j wordloop
	found:
		sub $t3, $t3, $t1 # decrements counter back to last new line
		foundloop:
			lb $t2, dictionary($t3) # loads next byte in dictionary
			sb $t2, 0x1005a000($t4) # adds byte to plausible word list
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
		
		
	