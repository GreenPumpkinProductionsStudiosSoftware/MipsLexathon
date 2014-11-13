.data
lexdict9: .asciiz "lexdict9.txt"
lexdict:  .asciiz "lexdict.txt"
.text
main:

generatearray:#DOESN'T TAKE YOUR ARGUMENTS.
	li $v0, 13	
	la $a0, lexdict9
	li $a1, 0
	li $a2, 0
	syscall
	
	#load the entire file into 0x10040000	
	move $a0, $v0
	li $a1, 0x10040000
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
	#li $v0, 42
	#li $a1, 9200
	#syscall	
	
	#li $t1, 20
	#mul $a0, $a0, $t1
	#addi $a0, $a0, 0x10040000
	li $a0, 0x10040000
	li $a1, 9
	
	jal jumble  
	jal shuffle
	jr $ra #i think that should be all you really need to do.





checkarray:
	
strcpr:#takes arguments a0=the address of the first string, a1=the address of the second string. returns v0=1 if strings match, v0=0 if they do not.
	lb $t0, ($a0)
	lb $t1, ($a1)
	bne $t1, $t0, strcprfalse
	beq $t1, $0, strcprtrue #if t1 is equal to 0 and we know t1 and t0 are equal, then we can conclude that we have reached the end of the strings and that the strings are equal. note that in order for this function to work, both strings must be null-terminated.
	addiu $a0, $a0, 1
	addiu $a1, $a1, 1
	j strcpr
	strcprfalse:
		addu $v0, $0, $0
		jr $ra
	strcprtrue:
		addiu $v0, $0, 1
		jr $ra
			
	
readfile: #reads all lines from a file file. arguments: a0= file descriptor a1=address of input buffer.  returns v0, the file status
	addiu $a2, $0, 16 #read EVERY character
	readlineloop:
		li $v0, 14
		syscall
		
		beq $v0, $0 readlineend #a status of zero means that the read has hit end of file	
		addiu $a1, $a1, 16 #store the next character in the next byte.	
	j readlineloop
	readlineend:	
		jr $ra	
jumble:#jumbles a string. arguments: a0:address of string to jumble. a1:length of string.
	move $t0, $a0 #address now contained in t0. this will be used for reference.
	move $t1, $a0 #address now also contained in t1. 
	sll $a1, $a1, 1 #shift one left aka multiply by two, because characters take up two bytes. 
	addu $t5, $a0, $a1 #t5 now contains the final address in the string
	jumbleloop:	
		beq $t1, $t5, endjumble #we flop each character in the thing once.
		li $v0, 42 
		move $a0, $a1
		syscall #generate a random number between 
		
		addu $t2, $a0, $t0 #the character in address $t1 will be flipped with the character in the address $t2
		lb $t3, ($t2)#flips each character in the string with another random character in the string.
		lb $t4, ($t1)
		sb $t3, ($t1)
		sb $t4, ($t2)
		lb $t3, 1($t2)
		lb $t4, 1($t1)
		sb $t3, 1($t1)
		sb $t4, 1($t2)
		addiu $t1, $t1, 2
	j jumbleloop
	endjumble:
		jr $ra
checkuserinput:

ui:

shuffle:


