
#program that offers three basic string functions: string length, put in lowercase a string, and delete m characters from a string s starting from position p with menu to a user to perform one of the three functions
.data
stringBuffer: .space 256
promptStringMsg: .asciiz "Please enter a string: "
menuChoiceA: .asciiz "\n1. function length\n"
menuChoiceB: .asciiz "2. put in lowercase\n"
menuChoiceC: .asciiz "3. Delete characters\n"
menuChoiceD: .asciiz "4. Quit\n"
menuPrompt: .asciiz "Please select an option: "

.text
main:
### print main menu and prompt input
	li $v0, 4
	# kept menu choices separate to be able to print them individualy
	la $a0, menuChoiceA
	syscall
	la $a0, menuChoiceB
	syscall
	la $a0, menuChoiceC
	syscall
	la $a0, menuChoiceD
	syscall

	
	# set arguments for prompt number
	li $a0, 1
	li $a1, 4
	la $a2, menuPrompt
	jal promptNumber # result is in $v0
	# save selection on stack
	beq $v0, 4, quit
	sw $v0, 0($sp)
	
	# prepare registers according to subroutine signature
	la $a0, stringBuffer
	li $a1, 256
	move $fp, $sp # save $sp to $fp before invoking
	jal promptString # resulting string's address stored in $a0
	
	# save the string address to $a0 and call the appropriate function
	lw $t0, 0($sp) # load the user choice from the stack
	la $ra, main # the jr instruction should come back here
	beq $t0, 1, stringLengthAndPrint
	beq $t0, 2, LowerCaseOfString
	beq $t0, 3, deleteCharacters
	
	# print $a0 back out
quit:	li $v0, 10
	syscall

### end print main meu and prompt input


# prompts the user to enter a string
# @param $a0 The string buffer start
# @param $a1 The length of the string
.data 
promptStr1: .asciiz "Please enter an integer in range "
promptStr2: .asciiz " and " 
promptStr3: .asciiz ":\n"
errorOutOfRangeStr: .asciiz "Out of range!\n"
.text
promptString:
	addi $sp, $sp, -12
	sw $a0, 0($sp) # push the address of the buffer onto the stack
	sw $a1, 4($sp) # push the length of the string onto the stack
	
	#prepare for read string dialog syscall
	# $a0 - The address of the prompt string
	# $a1 - The address of the output buffer
	# $a2 - The maximum length to read
	la $a0, promptStringMsg
	lw $a1, 0($sp)
	lw $a2, 4($sp)
	li $v0, 54
	syscall # $a1 is replaced with the status code.  0 means success
	
	lw $a0, 0($sp)
	
#### the string read has an uncessary \n at end.  Let's remove it
	sw $ra, 8($sp) # save current return address for future reference
	jal stringLength # length stored in $v0
	add $t0, $a0, $v0 # seek to end of string - the '\0' null byte
	sb $zero, -1($t0) # store '\0' one before the end

	lw $a1, 4($sp) # restore variables
	lw $ra, 8($sp)
	move $sp, $fp # pop stack frame
	jr $ra
	
# prompts the user for a number
# and will keep looping until it is between the specified range
# @param $a0 - The low end of the range, inclusive.
# @param $a1 - The high end of the range, inclusive.
# @param $a2 - Message to show on window
# @returns $v0 - The number the user entered that was finally accepted.
promptNumber:
	move $t0, $a0 # save the first argument
	move $t1, $a1 # save the second argument
	j promptNumberJmp # we don't want to print out of range on the first iteration

promptNumberLoop:	
	#print out of range
	la $a0, errorOutOfRangeStr
	li $v0, 4
	syscall
	
	
promptNumberJmp:	
### begin the message to show to user for prompt ###
	# print promptString first segment
	la $a0, promptStr1
	li $v0, 4
	syscall
	# printing the number of lower end of range
	move $a0, $t0 # move the argument 1 back to a0
	li $v0, 1 # load the code for the print integer service
	syscall # print the integer for the low end of the range
	#printing the second segment the promptString
	la $a0, promptStr2 # load address
	li $v0, 4 # load the code for the print string service
	syscall # print string
	# printing the number for the higher end of the rnage
	move $a0, $t1 # print service prints the number present in $a0
	li $v0, 1 # load the code for the number print service
	syscall # print the integer for the high end of the range
	# printing last segment of prompt string: the colon and new line
	la $a0, promptStr3
	li $v0, 4
	syscall
### end the message to show to user for prompt ###	
	move $a0, $a2 # show the $a3 string as the message prompt to user in the dialog box
	li $v0, 51 # number of the read integer service
	syscall # the result will be stored in $a0, status in $a1.  $a1 will be 0 if all is okay
	
	bnez $a1, promptNumberLoop # go back to loop if the input couldn't be parsed or was cancelled
	# check if the result is in range
	bgt $a0, $t1, promptNumberLoop # go back to loop if the number is greater than the high end.  The second argument was stored in $t1
	blt $a0, $t0, promptNumberLoop # go back to loop if the number is less than low end.  the first argument was stored in $t0
	
	# if the branch didn't occur then the number is in range
	move $v0, $a0   # the return signature says the answer should be in $v0
	move $a0, $t0   # put the first argument back in $a0 to maintain abstraction layer
	move $a1, $t1   # put the second argument back in $a1 to maintain abstraction layer
	jr $ra # return to caller
	
	
# Change all uppercase letters into lowercase letters in the passed string
# @param $a0 - The beginning of string
LowerCaseOfString:
	move $t0, $a0 # counter to step through string
LowerCaseStringLoop:
	lb $t1, ($t0) # load character into $t1
	
	beqz $t1, LowerCaseStringBreak
	bgt $t1, 97, LowerCaseStringLoopSkip	
	addi $t1, $t1, 32 # get ascii value of lower case from uppercase
	sb $t1, ($t0) # store character back to memory
	
LowerCaseStringLoopSkip:
	addi $t0, $t0, 1 # advance pointer
	j LowerCaseStringLoop
LowerCaseStringBreak: 
	#print string back out
	li $v0, 4
	syscall
	jr $ra


# @param $a0 - The beginning address of string
# @returns $v0 - The length of string	
stringLengthAndPrint:
	addi $sp, $sp, -12
	sw $ra, ($sp) # push ra onto stack
	jal stringLength # result saved in $v0
	sw $a0, 4($sp) # save the adress
	sw $v0, 8($sp) # save the length
	
	move $a0, $v0 # get ready to print the length
	li $v0, 1
	syscall
	
	# set registers properly before returning
	lw $ra, ($sp)
	lw $a0, 4($sp) # restore address back to $a0
	lw $v0, 8($sp) # restore length back to $t1
	addi $sp, $sp, 12 # move stack pointer back down
	jr $ra
	
# @param $a0 - The beginning address of string
# @returns $v0 - The length of string
stringLength:
	move $t0, $a0 # use address as counter to step through string
	li $v0, 0 # length counter
stringLengthLoop:
	lb $t1, ($t0)  # load one byte from current pointer
	beqz $t1, stringLengthLoopBreak # end loop if it's a null byte '\0'
	addi $t0, $t0, 1 # advance counter
	j stringLengthLoop
stringLengthLoopBreak:
	subu $v0, $t0, $a0 # subtract last address from beginning address to get length
	jr $ra


.data
positionPrompt: .asciiz "Enter the 0-based index where to start deleting"
charactersPrompt: .ascii "Enter number of characters to delete"
.text
# @param $a0 - The beginning of string
# this function will get the number of characters c and position m on its own
# Outputs - nothing.  $a0 string will be mutated	
deleteCharacters:
	addi $sp, $sp, -16  # this function needs a stack this big
	
	sw $ra, ($sp)
	jal stringLength # result stored in $v0
	lw $ra, ($sp)
	sw $v0, 12($sp) # save the length of the string
	sw $a0, 8($sp) # save the string address
	
	# get the position p
	li $a0, 0
	subi $a1, $v0, 1 # max index that the user can select is length - 1 that the 
	la $a2, positionPrompt
	sw $ra, ($sp) # save return address
	jal promptNumber # result stored in $v0
	lw $ra, ($sp) # pop return address
	sw $v0, 4($sp) # save the postiion p
	
	# now let's get the number of characters
	li $a0, 0 # the lowest number of characters to delete is 0
	# the highest number of characters to delete is legnth - p
	lw $t0, 12($sp) # get length of string
	sub $a1, $t0, $v0 # the length - p is the max bound
	la $a2, charactersPrompt
	sw $ra, ($sp) # save return address
	jal promptNumber # result stored in $v0
	lw $ra, ($sp) #pop return address

	move $a2, $v0 # move the number of characters c to $a3
	lw $a1, 4($sp) # stored position p in $a1
	lw $a0, 8($sp) # THE STRING ADDRESS
	lw $a3, 12($sp) # total length of string
	
	sw $ra, ($sp)
	jal deleteCharactersProcess
	lw $ra ($sp)
	
	lw $a0, 8($sp)
	li $v0, 4 #print the new string
	syscall
	
	addi $sp, $sp, 16
	jr $ra
# $a0 - The string
# $a1 - p The position
# $a2 - c The number of characters
# $a3 - total length of string
deleteCharactersProcess:
	add $t0, $a0, $a1 # make $t0 point to the letter that will be deleted
	add $t1, $t0, $a2 # make $t1 point to the memory that we will be overwriting with

	sub $t2, $a3, $a2 # initialize counter
deleteLoop:
	# copy [$t1] to [$t0]
	lb $t3, ($t1)
	sb $t3, ($t0)
	# advance both $t0 and $t1
	addi $t0, $t0, 1
	addi $t1, $t1, 1
	# decrement counter
	subi $t2, $t2, 1
	bnez $t2, deleteLoop # loop of not reached zero
	
	jr $ra
