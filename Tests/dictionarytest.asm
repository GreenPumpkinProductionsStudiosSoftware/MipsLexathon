#7 November 2014. ~StarFruitMystic~
#Searches a file named "dictionary.txt" for a word input by the user. It does this by reading the file by byte, which is probably the most straightforward way to do it but is not very effective.
#We're probably just going to load the entire dictionary of words into the program. That would be the fastest way to do it, and even that would take a long time. 4M of memory is more than enough to store all the #owrds we need, I think.
#There's not much we can do in terms of fancy search algorithms because as far as i can tell bytes in a file can only be read in sequence. So no jumping around and starting the read in the middle of the file.
#
#Type in a word that's not in the dictionary and see how long it takes.
#Just remember we could have up to 200 words to do this on.
.data
dict: .asciiz "lexdict.txt" #IMPORTANT NOTE: make sure this is in the same folder as MARS
.text

main: 
	#syscall 13 (open file): a0= address of null-terminated string containg file name. a1=flags, a2=mode
	#flags: 0= read, 1=write
	#0= mode ignore
	#outputs v0, the file descriptor. 
	addiu $v0, $0, 13
	la $a0, dict
	addiu $a1, $0, 0
	li $a2, 0
	syscall
	addu $s0, $v0, $0 #storing file descriptor in s0. we will need it later.
	
	#user inputs stringbean	
	addiu $a0, $0, 0x10040000 #address of user input string (it's just an address in the heap. calling sbrk would give you this automatically, so I just did this.)
	li $a1, 10	
	li $v0, 8
	syscall
		
	readloop: #read line from dictionary, compare with user input. repeat.	
		#syscall 14 (read from file): a0=file descriptor a1= address of input buffer a2 = maximum number of characters to read	
		move $a0, $s0 #loading file descriptor for readline, or more specifically the syscall 14 in readline.
		addu $a1, $sp, $0 #the string being read is stored on the stack. why not?
		jal readline #reads a line from the file
		addu $s1, $v0, $0
		
		li $a0, 0x10040000	
		addu $a1, $sp, $0	
		jal strcpr #compares the line from the file with user input
		
		bne $v0, $0, DIE #if $v0 is not 0, it has to be one. your word has been found! congratulations.
		beq $s1, $0, DIE #if you have reached the end of the file, then you're word is not in the dictionary. too bad. 
	j readloop

readline: #reads line from a file. arguments: a0= file descriptor a1=address of input buffer.  returns v0, the file status
	addiu $a2, $0, 1 #read 1 characters
	readlineloop:	
		li $v0, 14
		syscall
		
		lb $t0, ($a1) #load the character that has been read into t0
		li $t1, 10
		beq $t0, $t1 readlineend #if the character read is newline, it's over. end the programme.	
		beq $v0, $0 readlineend #a status of zero means that the read has hit end of file	
		addiu $a1, $a1, 1 #store the next character in the next byte.	
	j readlineloop
	readlineend:	
		jr $ra	

strcpr:#takes arguments a0=the address of the first string, a1=the address of the second string. returns v0=1 if strings match, v0=0 if they do not.
	lb $t0, ($a0)
	lb $t1, ($a1)
	li $t2, 10 #I was going to have both strings null-terminated, but it turned out that it was easier just to have them both end with \n. \n is ascii 10, by the way. That's what this is.
	bne $t1, $t0, strcprfalse
	beq $t1, $t2, strcprtrue #if t1 is equal to 10 and we know t1 and t0 are equal, then we can conclude that we have reached the end of the strings and that the strings are equal. note that in order for this function to work, both strings must be null-terminated.
	addiu $a0, $a0, 1
	addiu $a1, $a1, 1
	j strcpr
	strcprfalse:
		addu $v0, $0, $0
		jr $ra
	strcprtrue:
		addiu $v0, $0, 1
		jr $ra
DIE:
#you're also supposed to close the file or something but i don't feel like it.

