.data
lexdict9: .asciiz "lexdict9.txt"
lexdict:  .asciiz "lexdict.txt"
main:

generatearray:

checkarray:

strcpr:#takes arguments a0=the address of the first string, a1=the address of the second string. returns v0=1 if strings match, v0=0 if they do not.
	lb $t0, ($a0)
	lb $t1, ($a1)
	bneq $t1, $t0, strcprfalse
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
			
	
checkuserinput

ui:

shuffle:


