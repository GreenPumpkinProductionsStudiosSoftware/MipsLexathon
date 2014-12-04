.data
lexdict9: .asciiz "lexdict9.txt"
lexdict:  .asciiz "lexdict.txt"

.text
main:

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
	li $t1, 10 #IMPORTANT: windows users (AKA everyone else) need to change this to eleven before running.
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

checkuserinput:

ui:

shuffle:

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
checkanswo:#checks to determine whether the *answo* is in the solution list. Argumants: a0: location
findsolutions:

