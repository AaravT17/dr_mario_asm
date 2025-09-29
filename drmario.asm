######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    128
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL: .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD: .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################
# The address of the array containing memory addresses of viruses
ADDR_VRS: .word  0x10040000
# The address of the array that stores blocks to be deleted
ADDR_DEL: .word 0x100400a0
# The address of the array that stores information about all capsules placed in the game
ADDR_CPSL: .word 0x10040ae0
# The address where the high score is stored
ADDR_HIGH_SCR: .word 0x10040aa0
# The address where the game difficulty is stored
ADDR_DFCL: .word 0x10040ab0
# The address where a copy of the display area is stored
ADDR_DSPL_COPY: .word 0x10040120

##############################################################################
# Code
##############################################################################
	.text
	.globl main

# Run the game.
main:
add $t0, $zero, $zero
lw $t1, ADDR_HIGH_SCR
sw $t0, 0($t1)
jal clear_playing_area
# Initialize the game
# $s0 will store the number of viruses in the game
# $s1 will store the position of block 1 of the current capsule
# $s2 will store the position of block 2 of the current capsule
# $s3 will store the colour of block 1 of the current capsule
# $s4 will store the colour of block 2 of the current capsule
# $s5 will store the orientation of the current capsule
# $s6 will store the memory address in which to store information about the next capsule placed in the game
# $s7 will be used to store the gravity speed
# $t8 will be used to count how many units of time have passed in order to implement gravity
# $t9 will be used to store the player's score
lw $t0, ADDR_DSPL
addi $t0, $t0, 136
li $t1, 0xff0000
add $t2, $zero, $zero # $t2 stores the current row
add $t3, $zero, $zero # $t3 stores the current column
# virus should be 5 rows, 5 columns
jal draw_virus # draw the red virus
lw $t0, ADDR_DSPL
addi $t0, $t0, 292
li $t1, 0x0000ff
add $t2, $zero, $zero # $t2 stores the current row
add $t3, $zero, $zero # $t3 stores the current column
jal draw_virus # draw the blue virus
lw $t0, ADDR_DSPL
addi $t0, $t0, 588
li $t1, 0xffff00
add $t2, $zero, $zero # $t2 stores the current row
add $t3, $zero, $zero # $t3 stores the current column
jal draw_virus # draw the yellow virus
lw $t0, ADDR_DSPL
addi $t0, $t0, 1096
jal draw_dr_mario
start_game_loop:
lw $t1, ADDR_KBRD
lw $t1, 0($t1)
bne $t1, 1, start_game_loop
lw $t1, ADDR_KBRD
lw $t1, 4($t1)
bne $t1, 0x73, start_game_loop
start_game:
jal clear_playing_area
select_difficulty:
lw $t0, ADDR_DSPL
addi $t0, $t0, 772
li $t2, 0x00ff00
li $t1, 0x65
jal draw_letter
addi $t0, $t0, -240
li $t2, 0xffff00
li $t1, 0x6d
jal draw_letter
addi $t0, $t0, -232
li $t2, 0xff0000
li $t1, 0x68
jal draw_letter
select_difficulty_loop:
lw $t1, ADDR_KBRD
lw $t1, 0($t1)
bne $t1, 1, select_difficulty_loop
lw $t1, ADDR_KBRD
lw $t1, 4($t1)
beq $t1, 0x65, set_diff_easy
beq $t1, 0x6d, set_diff_med
beq $t1, 0x68, set_diff_hard
j select_difficulty_loop
set_diff_easy:
jal clear_playing_area
addi $t8, $zero, 1
lw $t0, ADDR_DSPL
addi $t0, $t0, 772
li $t2, 0x00ff00
li $t1, 0x65
jal draw_letter
# put the system to sleep for 2000ms
li $v0, 32
li $a0, 2000
syscall
j gameplay
set_diff_med:
jal clear_playing_area
addi $t8, $zero, 2
lw $t0, ADDR_DSPL
addi $t0, $t0, 788
li $t2, 0xffff00
li $t1, 0x6d
jal draw_letter
# put the system to sleep for 2000ms
li $v0, 32
li $a0, 2000
syscall
j gameplay
set_diff_hard:
jal clear_playing_area
addi $t8, $zero, 3
lw $t0, ADDR_DSPL
addi $t0, $t0, 812
li $t2, 0xff0000
li $t1, 0x68
jal draw_letter
# put the system to sleep for 2000ms
li $v0, 32
li $a0, 2000
syscall
j gameplay
gameplay:
jal clear_playing_area
j draw_bottle
END_OF_BOTTLE_DRAWING:
# bottle drawing complete
# randomly generate viruses
j generate_viruses
VIRUSES_GENERATED:
li $t6, 0xffff00
li $t7, 10
div $t5, $s0, 10
beq $t5, 0, virus_count_initial_single_digit
# handle two digit virus count here
lw $t0, ADDR_DSPL
div $s0, $t7
mflo $t5
jal draw_virus_count
addi $t0, $t0, -248
mfhi $t5
jal draw_virus_count
j initial_virus_count_drawn
virus_count_initial_single_digit:
lw $t0, ADDR_DSPL
addi $t0, $t0, 4
add $t5, $zero, $s0 # store a copy of the virus count in $t5
jal draw_virus_count
j initial_virus_count_drawn
initial_virus_count_drawn:
add $t0, $zero, $zero
lw $t1, ADDR_DEL
sw $t0, 0($t1)
lw $s6, ADDR_CPSL
jal set_gravity
# the gravity speed "timer" is now stored in $s7
lw $t0, ADDR_DFCL
sw $t8, 0($t0) # the game difficulty (1, 2, or 3) is now stored at ADDR_DFCL
addi $t8, $zero, 1
add $t9, $zero, $zero # set the score to 0
# put the system to sleep for 1000ms
li $v0, 32
li $a0, 1000
syscall
# game setup complete
# play game
j play_game

play_game:
j generate_capsule
CAPSULE_GENERATED:
j game_turn_loop

game_turn_loop:
# put the system to sleep for 100ms
li $v0, 32
li $a0, 100
syscall
bne $t8, $s7, continue_turn
addi $t8, $zero, 1
j respond_to_grav
continue_turn:
addi $t8, $t8, 1
# $t0: display address
# $s1: position of block 1 of the current capsule
# $s2: position of block 2 of the current capsule
# $s3: colour of block 1 of the current capsule
# $s4: colour of block 2 of the current capsule
# $s5: orientation of the current capsule
# $s6: memory address at which to store the information of the next capsule placed
# check if a key has been pressed
lw $t1, ADDR_KBRD
lw $t1, 0($t1)
beq $t1, 1 , keyboard_input # if a key has been pressed (if the value at ADDR_KBRD is 1), we branch accordingly to react to the keyboard input
j END_OF_GAME_TURN_LOOP # else, we skip to the end of the current "turn"
# if a key has been pressed, check which key has been pressed and react accordingly
keyboard_input:
lw $t1, ADDR_KBRD
lw $t1, 4($t1) # stores the keyboard input (ASCII value) in $t1
beq $t1, 0x77, respond_to_w # if the keyboard input is 'w', branch accordingly
beq $t1, 0x61, respond_to_a # if the keyboard input is 'a', branch accordingly
beq $t1, 0x73, respond_to_s # if the keyboard input is 's', branch accordingly
beq $t1, 0x64, respond_to_d # if the keyboard input is 'd', branch accordingly
beq $t1, 0x71, respond_to_q # if the keyboard input is 'q', branch accordingly
beq $t1, 0x70, respond_to_p # if the keyboard input is 'p', branch accordingly
# if the keyboard input is invalid, we act as though there is no input
KEYBOARD_INPUT_HANDLED:
# check for a collision
# if there is no collision, read next keyboard input
# if there is a collision with the bottom of the bottle, generate a new capsule
# if there is a collision with a block, check if we have formed a sequence of 4+ blocks in a row, delete blocks, move blocks down, check if we have formed another sequence of 4+ blocks in a row, repeat
j detect_collision
END_OF_GAME_TURN_LOOP:
j game_turn_loop


draw_pause:
lw $t0, ADDR_DSPL
addi $t0, $t0, 856
li $t1, 0xffffff
sw $t1, 0($t0)
sw $zero, 4($t0)
sw $zero, 8($t0)
sw $t1, 12($t0)
addi $t0, $t0, 64
sw $t1, 0($t0)
sw $zero, 4($t0)
sw $zero, 8($t0)
sw $t1, 12($t0)
addi $t0, $t0, 64
sw $t1, 0($t0)
sw $zero, 4($t0)
sw $zero, 8($t0)
sw $t1, 12($t0)
addi $t0, $t0, 64
sw $t1, 0($t0)
sw $zero, 4($t0)
sw $zero, 8($t0)
sw $t1, 12($t0)
addi $t0, $t0, 64
sw $t1, 0($t0)
sw $zero, 4($t0)
sw $zero, 8($t0)
sw $t1, 12($t0)
jr $ra


draw_resume:
lw $t0, ADDR_DSPL
addi $t0, $t0, 860
li $t1, 0xffffff
sw $t1, 0($t0)
sw $zero, 4($t0)
sw $zero, 8($t0)
sw $zero, 12($t0)
sw $zero, 16($t0)
addi $t0, $t0, 64
sw $t1, 0($t0)
sw $t1, 4($t0)
sw $zero, 8($t0)
sw $zero, 12($t0)
sw $zero, 16($t0)
addi $t0, $t0, 64
sw $t1, 0($t0)
sw $t1, 4($t0)
sw $t1, 8($t0)
sw $zero, 12($t0)
sw $zero, 16($t0)
addi $t0, $t0, 64
sw $t1, 0($t0)
sw $t1, 4($t0)
sw $zero, 8($t0)
sw $zero, 12($t0)
sw $zero, 16($t0)
addi $t0, $t0, 64
sw $t1, 0($t0)
sw $zero, 4($t0)
sw $zero, 8($t0)
sw $zero, 12($t0)
sw $zero, 16($t0)
addi $t0, $t0, 64
jr $ra


draw_virus_count:
# the starting address to draw will be stored in $t0
# the number to be drawn will be stored in $t5
# the colour of the text will be stored in $t6
beq $t5, 0, draw_zero_virus_count
beq $t5, 1, draw_one_virus_count
beq $t5, 2, draw_two_virus_count
beq $t5, 3, draw_three_virus_count
beq $t5, 4, draw_four_virus_count
beq $t5, 5, draw_five_virus_count
beq $t5, 6, draw_six_virus_count
beq $t5, 7, draw_seven_virus_count
beq $t5, 8, draw_eight_virus_count
beq $t5, 9, draw_nine_virus_count

draw_zero_virus_count:
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
jr $ra

draw_one_virus_count:
sw $t6, 0($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
jr $ra

draw_two_virus_count:
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $zero, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $zero, 4($t0)
sw $zero, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
jr $ra

draw_three_virus_count:
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $zero, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $zero, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
jr $ra

draw_four_virus_count:
sw $t6, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $zero, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $zero, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
jr $ra

draw_five_virus_count:
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $zero, 4($t0)
sw $zero, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $zero, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
jr $ra

draw_six_virus_count:
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $zero, 4($t0)
sw $zero, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
jr $ra

draw_seven_virus_count:
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $zero, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $zero, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $zero, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $zero, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
jr $ra

draw_eight_virus_count:
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
jr $ra

draw_nine_virus_count:
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $t6, 0($t0)
sw $t6, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $zero, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
addi $t0, $t0, 64
sw $zero, 0($t0)
sw $zero, 4($t0)
sw $t6, 8($t0)
jr $ra


clear_capsule_array:
lw $t0, ADDR_CPSL
li $t2, 0xcccccccc # this would need to be changed depending on the IDE
clear_capsule_array_loop:
lw $t1, 0($t0)
beq $t1, 0xcccccccc, capsule_array_cleared # this would need to be changed depending on the IDE
sw $t2, 0($t0)
addi $t0, $t0, 4
j clear_capsule_array_loop
capsule_array_cleared:
jr $ra


clear_virus_array:
lw $t0, ADDR_VRS
li $t2, 0xcccccccc # this would need to be changed depending on the IDE
clear_virus_array_loop:
lw $t1, 0($t0)
beq $t1, 0xcccccccc, virus_array_cleared # this would need to be changed depending on the IDE
sw $t2, 0($t0)
addi $t0, $t0, 4
j clear_virus_array_loop
virus_array_cleared:
jr $ra


set_gravity:
# $t8 = 1 if the game difficulty is easy
# $t8 = 2 if the game difficulty is medium
# $t8 = 3 if the game difficulty is hard
beq $t8, 1, set_grav_slow
beq $t8, 2, set_grav_med
beq $t8, 3, set_grav_fast
set_grav_slow:
addi $s7, $zero, 7
j grav_set
set_grav_med:
addi $s7, $zero, 5
j grav_set
set_grav_fast:
addi $s7, $zero, 3
j grav_set
grav_set:
jr $ra

draw_bottle:
lw $t0, ADDR_DSPL
li $t1, 0x808080 # load the colour grey (colour of the bottle) into $t1
# $t0: display address, $t1: colour grey
# draw the bottle using a loop
j draw_bottleneck
END_OF_BOTTLENECK:
j draw_bottle_body
END_OF_BOTTLE_BODY:
j END_OF_BOTTLE_DRAWING

draw_bottleneck:
add $t5, $zero, $zero # set $t5 (current row) to 0
# $t8: current row
# loop to draw bottleneck
draw_bottleneck_loop:
beq $t5, 5, draw_bottle_top_edge # check loop condition, if $t5 (current row) = 5, bottleneck has been drawn
addi $t0, $t0, 24
sw $t1, 0($t0)
addi $t0, $t0, 12
sw $t1, 0($t0)
addi $t5, $t5, 1
addi $t0, $t0, 28
j draw_bottleneck_loop

draw_bottle_top_edge:
# at this point, $t0 is pointing to 6th row, 1st column, $t5 (current row) = 5
add $t6, $zero, $zero # set $t6 (current column) to 0
# loop to draw bottle top edge
draw_bottle_top_edge_loop:
beq $t6, 16, END_OF_BOTTLENECK # check loop condition, if $t6 (current column) = 16, we have gone through the entire row
beq $t6, 7, SKIP_BOTTLE_OPENING # check branch condition, if $t6 (current column) = 7, we are at the bottleneck opening and must branch accordingly
sw $t1, 0($t0)
addi $t0, $t0, 4
addi $t6, $t6, 1
j draw_bottle_top_edge_loop
SKIP_BOTTLE_OPENING:
addi $t0, $t0, 8
addi $t6, $t6, 2
j draw_bottle_top_edge_loop

draw_bottle_body:
# at this point, $t0 is pointing to 7th row, 1st column
addi $t5, $t5, 1 # now, $t5 (current row) = 6
# loop to draw bottle body
draw_bottle_body_loop:
beq $t5, 31, draw_bottle_bottom_edge # check loop condition, if $t5 (current row) = 31, we are at the bottom row
sw $t1, 0($t0)
addi $t0, $t0, 60
sw $t1, 0($t0)
addi $t0, $t0, 4
addi $t5, $t5, 1
j draw_bottle_body_loop

draw_bottle_bottom_edge:
# at this point, $t0 is pointing to last row, 1st column, $t5 (current row) = 31 (last row)
add $t6, $zero, $zero # set $t6 (current column) to 0
# loop to draw bottle bottom edge
draw_bottle_bottom_edge_loop:
beq $t6, 16, END_OF_BOTTLE_BODY # check loop condition, if $t6 (current column) = 16, we have gone through the entire row
sw $t1, 0($t0)
addi $t0, $t0, 4
addi $t6, $t6, 1
j draw_bottle_bottom_edge_loop


generate_capsule: # animates the process of generating a new capsule
# if the entrance of the bottle is blocked at the start of a new "turn", the player loses
lw $t0, ADDR_DSPL
lw $t1, 412($t0)
lw $t2, 416($t0)
bne $t1, 0x000000, GAME_OVER_LOSS
bne $t1, 0x000000, GAME_OVER_LOSS
lw $t0, ADDR_DSPL # set $t0 back to the top-left corner of the display
# randomly generate a capsule
jal randomly_generate_colour # store a random colour (red, blue, or yellow) in $a0, this is the colour of block 1 of the current capsule
add $s3, $zero, $a0 # we now have the colour of block 1 of the current capsule in $s3
jal randomly_generate_colour # store a random colour (red, blue, or yellow) in $a0, this is the colour of block 2 of the current capsule
add $s4, $zero, $a0 # we now have the colour of block 2 of the current capsule in $s4
addi $s5, $zero, 1 # set $s5 (the capsule's orientation) to 1
add $t3, $zero, $zero
addi $s1, $t0, 28 # store the starting position of block 1 of the current capsule in $s1
addi $s2, $t0, 32 # store the starting position of block 2 of the current capsule in $s2
sw $s3, 0($s1)
sw $s4, 0($s2)
# put the system to sleep for 100ms
li $v0, 32
li $a0, 100
syscall
li $t4, 0x000000
generate_capsule_loop:
beq $t3, 6, CAPSULE_GENERATED
sw $t4, 0($s1)
sw $t4, 0($s2)
addi $s1, $s1, 64
addi $s2, $s2, 64
sw $s3, 0($s1)
sw $s4, 0($s2)
# put the system to sleep for 100ms
li $v0, 32
li $a0, 100
syscall
addi $t3, $t3, 1
j generate_capsule_loop


generate_viruses:
# $t8 = 1 if the game difficulty is easy
# $t8 = 2 if the game difficulty is medium
# $t8 = 3 if the game difficulty is hard
lw $t0, ADDR_DSPL # set $t0 back to the top-left corner of the display
beq $t8, 1, gen_virus_easy
beq $t8, 2, gen_virus_med
beq $t8, 3, gen_virus_hard
gen_virus_easy:
li $v0, 42
li $a0, 0
li $a1, 3
syscall # stores a random number between 0 and 3 (excl.) in $a0
addi $s0, $a0, 6 # stores the number of viruses (6-8) in $s0 by adding 6 to the randomly generated number between 0 and 3 (excl.) stored in $a0
j num_virus_set
gen_virus_med:
li $v0, 42
li $a0, 0
li $a1, 5
syscall # stores a random number between 0 and 5 (excl.) in $a0
addi $s0, $a0, 8 # stores the number of viruses (8-12) in $s0 by adding 8 to the randomly generated number between 0 and 5 (excl.) stored in $a0
j num_virus_set
gen_virus_hard:
li $v0, 42
li $a0, 0
li $a1, 4
syscall # stores a random number between 0 and 4 (excl.) in $a0
addi $s0, $a0, 12 # stores the number of viruses (12-15) in $s0 by adding 12 to the randomly generated number between 0 and 4 (excl.) stored in $a0
j num_virus_set

num_virus_set:
add $t1, $zero, $zero # set $t1 to 0, $t1 will count how many viruses we have generated so far
lw $t2, ADDR_VRS # set $t2 to the memory address of the array that stores the locations/memory addresses of viruses
# loop to generate viruses
# $s0: total number of viruses
# $t1: number of viruses generated so far
# $t2: the memory address where the location/memory address of the next virus will be stored
generate_viruses_loop:
beq $t1, $s0, VIRUSES_GENERATED # check loop condition (whether we have generated the number of viruses we are supposed to)
jal randomly_generate_colour # store a random colour (red, blue, or yellow) in $a0
add $t4, $zero, $a0 # we now have the random colour in $t4 (since $a0 will get overwritten when generating the random location)
# now, we must randomly generate a location in the bottom half of the bottle
jal randomly_generate_location # we now have a random location in the bottom half of the bottle in $a1
sw $t4, 0($a1) # store the randomly generated colour in $t4 at the randomly generated location in $a1
sw $a1, 0($t2) # store the memory address of the virus in $a1 in the memory location in $t2
addi $t2, $t2, 4 # increment $t2 by 4 to the memory address where we will store the location/memory address of the next virus
addi $t1, $t1, 1 # increment loop variable (number of viruses generated so far)
j generate_viruses_loop


randomly_generate_colour:
li $v0, 42
li $a0, 0
li $a1, 3
syscall # stores a random number between 0 and 3 (excl.) in $a0
# compare the randomly generated number in $a0 with 0, 1, and 2, and select a colour to store in $a0 accordingly
beq $a0, 0, get_red_virus
beq $a0, 1, get_blue_virus
beq $a0, 2, get_yellow_virus
get_red_virus:
li $a0, 0xff0000
jr $ra
get_blue_virus:
li $a0, 0x0000ff
jr $ra
get_yellow_virus:
li $a0, 0xffff00
jr $ra


randomly_generate_location:
location_generating_loop:
li $v0, 42
li $a0, 0
li $a1, 208
syscall # stores a random number between 0 and 208 (excl.) in $a0, this is the number of locations where we can have a virus
sll $a0, $a0, 2 # multiply the location number in $a0 by 4
addi $a1, $a0, 1152 # jump to the lower half of the bottle
add $a1, $a1, $t0 # add the memory address relative to our base display address to the base display address so that we get a valid location in the display area
# now, have randomly generated location/memory address in the bottom half of the bottle in $a1
lw $t3, 0($a1) # sets $t3 to the colour at the memory address stored in $a1
bne $t3, 0x000000, location_generating_loop # if the location generated is not empty (if its colour is not black), we must generate another location
jr $ra


respond_to_w:
# $s1: position of block 1 of the current capsule
# $s2: position of block 2 of the current capsule
# $s3: colour of block 1 of the current capsule
# $s4: colour of block 2 of the current capsule
# $s5: orientation of the current capsule
beq $s5, 1, w_case_1
beq $s5, 2, w_case_2
beq $s5, 3, w_case_3
beq $s5, 4, w_case_4
# one of these cases must always be satisfied, $s5 (orientation) must always be 1, 2, 3, or 4

w_case_1:
# $s5 = 1, after this, it will be 2
lw $t1, -64($s2)
beq $t1, 0x000000, continue_w_case_1 # if the position above block 2 of the capsule is empty (black), we can rotate
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_W
continue_w_case_1:
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, -60 # $s1 moves 1 row up and 1 column to the right
# $s2 does not need to be updated
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
addi $s5, $zero, 2 # set $s5 (orientation of the current capsule) to 2
j END_OF_RESPOND_TO_W


w_case_2:
# $s5 = 2, after this, it will be 3
lw $t1, -4($s2)
beq $t1, 0x808080, w_case_2_edge_case
lw $t1, -4($s2)
beq $t1, 0x000000, continue_w_case_2 # if the position to the left of block 2 of the capsule is empty (black), we can rotate
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_W
continue_w_case_2:
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, 64 # $s1 moves 1 row down
addi $s2, $s2, -4 # $s2 moves 1 column to the left
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
END_OF_W_CASE_2:
addi $s5, $zero, 3 # set $s5 (orientation of the current capsule) to 3
j END_OF_RESPOND_TO_W

w_case_2_edge_case:
lw $t1, 4($s2)
beq $t1, 0x000000, continue_w_case_2_edge_case # if the position to the right of block 2 of the capsule is empty (black), we can rotate
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_W
continue_w_case_2_edge_case:
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, 68 # $s1 moves 1 row down and 1 column to the right
# $s2 does not need to be updated
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_W_CASE_2

w_case_3:
# $s5 = 3, after this, it will be 4
lw $t1, -64($s1)
beq $t1, 0x000000, continue_w_case_3 # if the position above block 1 of the capsule is empty (black), we can rotate
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_W
continue_w_case_3:
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
# $s1 does not need to be updated
addi $s2, $s2, -60 # $s2 moves 1 row up and 1 column to the right
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
addi $s5, $zero, 4 # set $s5 (orientation of the current capsule) to 4
j END_OF_RESPOND_TO_W


w_case_4:
# $s5 = 4, after this, it will be 1
lw $t1, -4($s1)
beq $t1, 0x808080, w_case_4_edge_case
lw $t1, -4($s1)
beq $t1, 0x000000, continue_w_case_4 # if the position to the left of block 1 of the capsule is empty (black), we can rotate
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_W
continue_w_case_4:
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, -4 # $s1 moves 1 column to the left
addi $s2, $s2, 64 # $s2 moves 1 row down
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
END_OF_W_CASE_4:
addi $s5, $zero, 1 # set $s5 (orientation of the current capsule) to 1
j END_OF_RESPOND_TO_W

w_case_4_edge_case:
lw $t1, 4($s1)
beq $t1, 0x000000, continue_w_case_4_edge_case # if the position to the right of block 1 of the capsule is not empty (black), we cannot rotate
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_W
continue_w_case_4_edge_case:
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
# $s1 does not need to be updated
addi $s2, $s2, 68 # $s2 moves 1 row down and 1 column to the right
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_W_CASE_4

END_OF_RESPOND_TO_W:
j KEYBOARD_INPUT_HANDLED


respond_to_a:
# $s1: position of block 1 of the current capsule
# $s2: position of block 2 of the current capsule
# $s3: colour of block 1 of the current capsule
# $s4: colour of block 2 of the current capsule
# $s5: orientation of the current capsule
beq $s5, 1, a_case_1
beq $s5, 2, a_case_2
beq $s5, 3, a_case_3
beq $s5, 4, a_case_4
# one of these cases must always be satisfied, $s5 (orientation) must always be 1, 2, 3, or 4

a_case_1:
lw $t1, -4($s1)
beq $t1, 0x000000, continue_a_case_1 # if the position to the left of block 1 of the capsule is empty (black), we can move left
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_A
continue_a_case_1:
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, -4
addi $s2, $s2, -4
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_RESPOND_TO_A

a_case_2:
lw $t1, -4($s1)
lw $t2, -4($s2)
# if the positions to the left of block 1 and block 2 are empty (black), we can move left
beq $t1, 0x000000, a_case_2_check_second_cond
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_A
a_case_2_check_second_cond:
beq $t2, 0x000000, continue_a_case_2
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_A
continue_a_case_2:
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, -4
addi $s2, $s2, -4
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_RESPOND_TO_A

a_case_3:
lw $t1, -4($s2)
beq $t1, 0x000000, continue_a_case_3 # if the position to the left of block 2 of the capsule is empty (black), we can move left
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_A
continue_a_case_3:
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, -4
addi $s2, $s2, -4
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_RESPOND_TO_A

a_case_4:
lw $t1, -4($s1)
lw $t2, -4($s2)
# if the positions to the left of block 1 and block 2 are empty (black), we can move left
beq $t1, 0x000000, a_case_4_check_second_cond
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_A
a_case_4_check_second_cond:
beq $t2, 0x000000, continue_a_case_4
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_A
continue_a_case_4:
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, -4
addi $s2, $s2, -4
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_RESPOND_TO_A

END_OF_RESPOND_TO_A:
j KEYBOARD_INPUT_HANDLED



respond_to_s:
# $s1: position of block 1 of the current capsule
# $s2: position of block 2 of the current capsule
# $s3: colour of block 1 of the current capsule
# $s4: colour of block 2 of the current capsule
# $s5: orientation of the current capsule
beq $s5, 1, s_case_1
beq $s5, 2, s_case_2
beq $s5, 3, s_case_3
beq $s5, 4, s_case_4
# one of these cases must always be satisfied, $s5 (orientation) must always be 1, 2, 3, or 4

s_case_1:
lw $t1, 64($s1)
lw $t2, 64($s2)
# if the position below block 1 or block 2 is not empty (black), we cannot move down
bne $t1, 0x000000, END_OF_RESPOND_TO_S
bne $t2, 0x000000, END_OF_RESPOND_TO_S
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, 64
addi $s2, $s2, 64
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_RESPOND_TO_S

s_case_2:
lw $t1, 64($s2)
# if the position below block 2 is not empty (black), we cannot move down
bne $t1, 0x000000, END_OF_RESPOND_TO_S
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, 64
addi $s2, $s2, 64
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_RESPOND_TO_S

s_case_3:
lw $t1, 64($s1)
lw $t2, 64($s2)
# if the position below block 1 or block 2 is not empty (black), we cannot move down
bne $t1, 0x000000, END_OF_RESPOND_TO_S
bne $t2, 0x000000, END_OF_RESPOND_TO_S
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, 64
addi $s2, $s2, 64
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_RESPOND_TO_S

s_case_4:
lw $t1, 64($s1)
# if the position below block 1 is not empty (black), we cannot move down
bne $t1, 0x000000, END_OF_RESPOND_TO_S
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, 64
addi $s2, $s2, 64
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_RESPOND_TO_S

END_OF_RESPOND_TO_S:
j KEYBOARD_INPUT_HANDLED


respond_to_d:
# $s1: position of block 1 of the current capsule
# $s2: position of block 2 of the current capsule
# $s3: colour of block 1 of the current capsule
# $s4: colour of block 2 of the current capsule
# $s5: orientation of the current capsule
beq $s5, 1, d_case_1
beq $s5, 2, d_case_2
beq $s5, 3, d_case_3
beq $s5, 4, d_case_4
# one of these cases must always be satisfied, $s5 (orientation) must always be 1, 2, 3, or 4

d_case_1:
lw $t1, 4($s2)
beq $t1, 0x000000, continue_d_case_1 # if the position to the right of block 2 of the capsule is empty (black), we can move right
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_D
continue_d_case_1:
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, 4
addi $s2, $s2, 4
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_RESPOND_TO_D

d_case_2:
lw $t1, 4($s1)
lw $t2, 4($s2)
# if the positions to the right of block 1 and block 2 are empty (black), we can move right
beq $t1, 0x000000, d_case_2_check_second_cond
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_D
d_case_2_check_second_cond:
beq $t2, 0x000000, continue_d_case_2
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_D
continue_d_case_2:
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, 4
addi $s2, $s2, 4
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_RESPOND_TO_D

d_case_3:
lw $t1, 4($s1)
beq $t1, 0x000000, continue_d_case_3 # if the position to the right of block 1 of the capsule is empty (black), we can move right
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_D
continue_d_case_3:
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, 4
addi $s2, $s2, 4
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_RESPOND_TO_D

d_case_4:
lw $t1, 4($s1)
lw $t2, 4($s2)
# if the positions to the right of block 1 and block 2 are empty (black), we can move right
beq $t1, 0x000000, d_case_4_check_second_cond
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_D
d_case_4_check_second_cond:
beq $t2, 0x000000, continue_d_case_4
li $a0, 30 # pitch
li $a1, 100 # duration
li $a2, 0 # instrument (0-127)
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
j END_OF_RESPOND_TO_D
continue_d_case_4:
li $a0, 60 # pitch
li $a1, 100 # duration
li $a2, 10
li $a3, 100 # volume (0-127)
li $v0, 31
syscall
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, 4
addi $s2, $s2, 4
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_RESPOND_TO_D

END_OF_RESPOND_TO_D:
j KEYBOARD_INPUT_HANDLED


respond_to_q:
j GAME_OVER # quit game


respond_to_p:
store_screen:
lw $t0, ADDR_DSPL
lw $t1, ADDR_DSPL_COPY
add $t2, $zero, $zero
store_screen_loop:
beq $t2, 512, screen_stored
lw $t3, 0($t0)
sw $t3, 0($t1)
addi $t0, $t0, 4
addi $t1, $t1, 4
addi $t2, $t2, 1
j store_screen_loop
screen_stored:
jal clear_playing_area
jal draw_pause
# put the system to sleep for 100ms
li $v0, 32
li $a0, 100
syscall
pause_game_loop:
lw $t1, ADDR_KBRD
lw $t1, 0($t1)
bne $t1, 1, pause_game_loop
lw $t1, ADDR_KBRD
lw $t1, 4($t1)
beq $t1, 0x71, GAME_OVER
beq $t1, 0x70, unpause
j pause_game_loop
unpause:
jal clear_playing_area
jal draw_resume
# put the system to sleep for 500ms
li $v0, 32
li $a0, 500
syscall
jal clear_playing_area
restore_screen:
lw $t0, ADDR_DSPL
lw $t1, ADDR_DSPL_COPY
add $t2, $zero, $zero
restore_screen_loop:
beq $t2, 512, screen_restored
lw $t3, 0($t1)
sw $t3, 0($t0)
addi $t0, $t0, 4
addi $t1, $t1, 4
addi $t2, $t2, 1
j restore_screen_loop
screen_restored:
# put the system to sleep for 100ms
li $v0, 32
li $a0, 100
syscall
j KEYBOARD_INPUT_HANDLED


respond_to_grav:
# $s1: position of block 1 of the current capsule
# $s2: position of block 2 of the current capsule
# $s3: colour of block 1 of the current capsule
# $s4: colour of block 2 of the current capsule
# $s5: orientation of the current capsule
beq $s5, 1, grav_case_1
beq $s5, 2, grav_case_2
beq $s5, 3, grav_case_3
beq $s5, 4, grav_case_4
# one of these cases must always be satisfied, $s5 (orientation) must always be 1, 2, 3, or 4

grav_case_1:
lw $t1, 64($s1)
lw $t2, 64($s2)
# if the position below block 1 or block 2 is not empty (black), we cannot move down
bne $t1, 0x000000, END_OF_RESPOND_TO_GRAV
bne $t2, 0x000000, END_OF_RESPOND_TO_GRAV
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, 64
addi $s2, $s2, 64
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_RESPOND_TO_GRAV

grav_case_2:
lw $t1, 64($s2)
# if the position below block 2 is not empty (black), we cannot move down
bne $t1, 0x000000, END_OF_RESPOND_TO_GRAV
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, 64
addi $s2, $s2, 64
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_RESPOND_TO_GRAV

grav_case_3:
lw $t1, 64($s1)
lw $t2, 64($s2)
# if the position below block 1 or block 2 is not empty (black), we cannot move down
bne $t1, 0x000000, END_OF_RESPOND_TO_GRAV
bne $t2, 0x000000, END_OF_RESPOND_TO_GRAV
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, 64
addi $s2, $s2, 64
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_RESPOND_TO_GRAV

grav_case_4:
lw $t1, 64($s1)
# if the position below block 1 is not empty (black), we cannot move down
bne $t1, 0x000000, END_OF_RESPOND_TO_GRAV
# paint the current positions black
li $t1, 0x000000
sw $t1, 0($s1)
sw $t1, 0($s2)
# update the locations
addi $s1, $s1, 64
addi $s2, $s2, 64
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
j END_OF_RESPOND_TO_GRAV

END_OF_RESPOND_TO_GRAV:
j KEYBOARD_INPUT_HANDLED


detect_collision:
# if there is no collision, read next keyboard input
# if there is a collision with the bottom of the bottle, generate a new capsule
# if there is a collision with a block, check if we have formed a sequence of 4+ blocks in a row, delete blocks, move blocks down, check if we have formed another sequence of 4+ blocks in a row, repeat
# $s1: position of block 1 of the current capsule
# $s2: position of block 2 of the current capsule
# $s5: orientation of the current capsule
beq $s5, 1, collision_case_1
beq $s5, 2, collision_case_2
beq $s5, 3, collision_case_3
beq $s5, 4, collision_case_4
# one of these cases must always be satisfied, $s5 (orientation) must always be 1, 2, 3, or 4

collision_case_1:
# $s5 = 1
lw $t1, 64($s1)
lw $t2, 64($s2)
# if the position below block 1 or block 2 is not empty (black), there is a collision
bne $t1, 0x000000, COLLISION_DETECTED
bne $t2, 0x000000, COLLISION_DETECTED
# if the positions below block 1 and block 2 are empty (black), there is no collision, we would only get to this part of the code if that were the case
j NO_COLLISION_DETECTED

collision_case_2:
# $s5 = 2
lw $t1, 64($s2)
# if the position below block 2 is not empty (black), there is a collision
bne $t1, 0x000000, COLLISION_DETECTED
# if the position below block 2 is empty (black), there is no collision, we would only get to this part of the code if that were the case
j NO_COLLISION_DETECTED

collision_case_3:
# $s5 = 3
lw $t1, 64($s1)
lw $t2, 64($s2)
# if the position below block 1 or block 2 is not empty (black), there is a collision
bne $t1, 0x000000, COLLISION_DETECTED
bne $t2, 0x000000, COLLISION_DETECTED
# if the positions below block 1 and block 2 are empty (black), there is no collision, we would only get to this part of the code if that were the case
j NO_COLLISION_DETECTED

collision_case_4:
# $s5 = 4
lw $t1, 64($s1)
# if the position below block 1 is not empty (black), there is a collision
bne $t1, 0x000000, COLLISION_DETECTED
# if the position below block 1 is empty (black), there is no collision, we would only get to this part of the code if that were the case
j NO_COLLISION_DETECTED

COLLISION_DETECTED:
addi $t9, $t9, 1 # add 1 to the player's score for each capsule placed
# now, we must check if we have formed a sequence of 4+ blocks in a row, delete blocks, move blocks down, check if we have formed another sequence of 4+ blocks in a row, repeat
# the code that this jumps to will be the most important program logic
# add capsule information to the array
sw $s1, 0($s6)
sw $s2, 4($s6)
sw $s5, 8($s6)
addi $s6, $s6, 12
li $v0, 31
li $a2, 10
li $a3, 100
li $a0, 40
li $a1, 50
syscall
li $a0, 70
li $a1, 40
syscall
# put the system to sleep for 100ms
li $v0, 32
li $a0, 100
syscall
# find and delete sequences of length 4+
j detect_sequence
SEQUENCE_DETECTION_COMPLETE: # we now have the blocks to be deleted stored in the array 
lw $t2, ADDR_DEL
lw $t2, 0($t2)
bne $t2, 0, clear_blocks
# if we get to this point, that means there are no blocks that need to be cleared
j generate_capsule
BLOCKS_CLEARED:
li $v0, 31
li $a2, 10
li $a3, 110
li $a0, 60
li $a1, 200
syscall
li $a0, 64
li $a1, 200
syscall
li $a0, 67
li $a1, 200
syscall
li $a0, 72
li $a1, 200
syscall
li $a3, 90
li $a0, 67
li $a1, 200
syscall
beq $s0, 0, GAME_OVER_WIN # if there are no more viruses in the game, the player wins
j drop_down_blocks

NO_COLLISION_DETECTED:
# since there has been no collision, we run game_turn_loop again
j game_turn_loop


detect_sequence:
# apply brute force to detect sequences of the same colour of length 4+, first row-wise and then column-wise
# store the memory addresses of blocks to be cleared in an array starting at ADDR_DEL
# $t0: current location
# $t1: next memory address in which to store the memory address of a block to be cleared
# $t2: length of current sequence
# $t3, $t4: available for use
# $t5: current row, $t6: current column
# first, check row-wise
lw $t1, ADDR_DEL
lw $t0, ADDR_DSPL
addi $t0, $t0, 388 # $t0 now points to the top left of the playing area
j detect_seq_rows
DETECT_SEQ_ROWS_COMPLETE:
# then, check column-wise
lw $t0, ADDR_DSPL
addi $t0, $t0, 388 # $t0 now points to the top left of the playing area
j detect_seq_cols
DETECT_SEQ_COLS_COMPLETE:
# sequence detection complete
# we now have the elements to be deleted stored in an array starting at ADDR_DSPL
j SEQUENCE_DETECTION_COMPLETE

detect_seq_rows:
# $t0 points to the top left of the playing area
# $t1 points to ADDR_DEL
addi $t5, $zero, 6 # set $t5 (current row) to 6
addi $t6, $zero, 1 # set $t6 (current column) to 1
addi $t2, $zero, 1 # set $t2 (length of current sequence) to 1
detect_seq_rows_loop:
beq $t5, 31, DETECT_SEQ_ROWS_COMPLETE # if $t5 (current row) = 31, we have gone through all rows within the playing area (the bottom row of the display is the bottom edge of the bottle)
beq $t6, 15, detect_curr_row_complete # if $t6 (current column) = 15, we have gone through all columns within the playing area in the current row (the rightmost column of the display is the right edge of the bottle)
lw $t3, 0($t0) # $t3 stores the colour of the current block
lw $t4, -4($t0) # $t4 stores the colour of the previous block in the row
beq $t3, 0x000000, detect_seq_rows_check_for_seq_4_or_more # if the current block is black, we check whether we have a sequence of 4+ before it and act accordingly
bne $t3, $t4, detect_seq_rows_check_for_seq_4_or_more # if the current block is of a different colour to the previous block, we check whether we have a sequence of 4+ before it and act accordingly
# if we get to this point, that means our current block is not black and has the same colour as the previous block
addi $t2, $t2, 1 # increment sequence length
j detect_seq_rows_loop_update

detect_seq_rows_reset_seq_length:
addi $t2, $zero, 1 # set $t2 (length of current sequence) to 1
beq $t6, 15, detect_seq_rows_loop_update_row_complete
j detect_seq_rows_loop_update

detect_seq_rows_loop_update:
addi $t6, $t6, 1 # increment current column
addi $t0, $t0, 4 # move the pointer to the next block to the right
j detect_seq_rows_loop

detect_curr_row_complete:
j detect_seq_rows_check_for_seq_4_or_more
detect_seq_rows_loop_update_row_complete:
addi $t5, $t5, 1 # increment current row
addi $t6, $zero, 1 # set $t6 (current column) back to 1
addi $t2, $zero, 1 # set $t2 (length of current sequence) to 1
addi $t0, $t0, 8 # add 8 to the pointer to jump over the left edge of the bottle when moving to the next row
j detect_seq_rows_loop

detect_seq_rows_check_for_seq_4_or_more:
# if we get to this point, it means our sequence has been broken (or we did not have a sequence and encountered a black block)
# the current block that $t0 points at is not part of the sequence, $t0 points at the block right after the sequence
# we also do not want to change $t0 since it is still required for the rest of the loop
blt $t2, 4, detect_seq_rows_reset_seq_length # checks if $t2 (length of current sequence) < 4
# if we get to this point, then $t2 (length of current sequence) >= 4
addi $t3, $t0, -4 # $t3 points to the last block in the sequence
detect_seq_rows_check_for_seq_4_or_more_loop:
# $t3 points to the current block in the sequence
# $t2 is the number of blocks in the sequence remaining to be added to the array
beq $t2, 0, detect_seq_rows_reset_seq_length
sw $t3, 0($t1)
addi $t3, $t3, -4
addi $t1, $t1, 4
addi $t2, $t2, -1
j detect_seq_rows_check_for_seq_4_or_more_loop

detect_seq_cols:
# $t0 points to the top left of the playing area
# $t1 points to the next memory address where we will store the memory address of the next block to clear
addi $t5, $zero, 6 # set $t5 (current row) to 6
addi $t6, $zero, 1 # set $t6 (current column) to 1
addi $t2, $zero, 1 # set $t2 (length of current sequence) to 1
detect_seq_cols_loop:
beq $t6, 15, DETECT_SEQ_COLS_COMPLETE # if $t6 (current column) = 15, we have gone through all columns within the playing area (the rightmost column of the display is the right edge of the bottle)
beq $t5, 31, detect_curr_col_complete # if $t5 (current row) = 31, we have gone through all rows within the playing area in the current column (the bottom row of the display is the bottom edge of the bottle)
lw $t3, 0($t0)
lw $t4, -64($t0)
beq $t3, 0x000000, detect_seq_cols_check_for_seq_4_or_more # if the current block is black, we check whether we have a sequence of 4+ before it and act accordingly
bne $t3, $t4, detect_seq_cols_check_for_seq_4_or_more # if the current block is of a different colour to the previous block, we check whether we have a sequence of 4+ before it and act accordingly
# if we get to this point, that means our current block is not black and has the same colour as the previous block
addi $t2, $t2, 1 # increment sequence length
j detect_seq_cols_loop_update

detect_seq_cols_reset_seq_length:
addi $t2, $zero, 1 # set $t2 (length of current sequence) to 1
beq $t5, 31, detect_seq_cols_loop_update_col_complete
j detect_seq_cols_loop_update

detect_seq_cols_loop_update:
addi $t5, $t5, 1 # increment current row
addi $t0, $t0, 64 # move the pointer to the block below
j detect_seq_cols_loop

detect_curr_col_complete:
j detect_seq_cols_check_for_seq_4_or_more
detect_seq_cols_loop_update_col_complete:
addi $t6, $t6, 1 # increment current column
addi $t5, $zero, 6 # set $t5 (current row) back to 6
addi $t2, $zero, 1 # set $t2 (length of current sequence) to 1
addi $t0, $t0, -1596 # move the pointer up 25 rows and 1 column to the right
j detect_seq_cols_loop

detect_seq_cols_check_for_seq_4_or_more:
# if we get to this point, it means our sequence has been broken (or we did not have a sequence and encountered a black block)
# the current block that $t0 points at is not part of the sequence, $t0 points at the block right after the sequence
# we also do not want to change $t0 since it is still required for the rest of the loop
blt $t2, 4, detect_seq_cols_reset_seq_length # checks if $t2 (length of current sequence) < 4
# if we get to this point, then $t2 (length of current sequence) >= 4
addi $t3, $t0, -64 # $t3 points to the last block in the sequence
detect_seq_cols_check_for_seq_4_or_more_loop:
# $t3 points to the current block in the sequence
# $t2 is the number of blocks in the sequence remaining to be added to the array
beq $t2, 0, detect_seq_cols_reset_seq_length
sw $t3, 0($t1)
addi $t3, $t3, -64
addi $t1, $t1, 4
addi $t2, $t2, -1
j detect_seq_cols_check_for_seq_4_or_more_loop


clear_blocks:
# $t1 points to the address right after the last address where we stored a location to be cleared
add $t5, $t1, $zero # $t1 is copied into $t5
lw $t2, ADDR_DEL
li $t3, 0xffffff
add $t6, $zero, $zero
clear_blocks_paint_white:
beq $t5, $t2, BLOCKS_PAINTED_WHITE
lw $t4, -4($t5)
lw $t7, 0($t4)
beq $t7, 0xffffff, block_painted_white
sw $t3, 0($t4)
addi $t6, $t6, 1
block_painted_white:
addi $t5, $t5, -4
j clear_blocks_paint_white

BLOCKS_PAINTED_WHITE:
# $t6 now contains the number of blocks being cleared
# add to the player's score according to the difficulty
lw $t0, ADDR_DFCL
lw $t0, 0($t0)
beq $t0, 1, block_clear_score_easy
beq $t0, 2, block_clear_score_medium
beq $t0, 3, block_clear_score_hard
block_clear_score_easy:
add $t9, $t9, $t6
j block_clear_score_handled
block_clear_score_medium:
# 1.25x multiplier
mul $t6, $t6, 5
div $t6, $t6, 4
add $t9, $t9, $t6
j block_clear_score_handled
block_clear_score_hard:
# 1.5x multiplier
mul $t6, $t6, 3
div $t6, $t6, 2
add $t9, $t9, $t6
j block_clear_score_handled
block_clear_score_handled:
# put the system to sleep for 300ms
li $v0, 32
li $a0, 300
syscall

li $t3, 0x000000
clear_blocks_loop:
beq $t1, $t2, BLOCKS_CLEARED
lw $t4, -4($t1)
sw $t3, -4($t1) # resets the location in memory
sw $t3, 0($t4) # paints the block black
# $t4 stores the location/memory address of the block being cleared
# if the block deleted is a virus, remove it from the array of virus memory addresses and reduce the number of viruses remaining by 1
j remove_virus_from_array
VIRUS_REMOVAL_COMPLETE:
# remove capsule from the array of capsules
j remove_capsule_from_array
CAPSULE_REMOVAL_COMPLETE:
addi $t1, $t1, -4
j clear_blocks_loop


remove_virus_from_array:
# $t4 stores the location/memory address of the block being cleared
# $s0 stores the number of viruses in the game
# $t5-$t7 are available to use
lw $t5, ADDR_VRS
add $t6, $zero, $zero
virus_array_search_loop:
beq $t6, $s0, VIRUS_NOT_FOUND
lw $t7, 0($t5)
beq $t4, $t7, VIRUS_FOUND
addi $t5, $t5, 4 # increment $t5
addi $t6, $t6, 1 # increment $t6
j virus_array_search_loop

VIRUS_FOUND:
# add to the player's score according to the difficulty
lw $t0, ADDR_DFCL
lw $t0, 0($t0)
beq $t0, 1, virus_clear_score_easy
beq $t0, 2, virus_clear_score_medium
beq $t0, 3, virus_clear_score_hard
virus_clear_score_easy:
addi $t9, $t9, 3
j virus_clear_score_handled
virus_clear_score_medium:
addi $t9, $t9, 4
j virus_clear_score_handled
virus_clear_score_hard:
addi $t9, $t9, 5
j virus_clear_score_handled
virus_clear_score_handled:
# shift the array elements to remove the address of the virus being deleted
# $t5 refers to the location in the array where the virus' memory address is stored
# $t6 refers to the index in the array where the virus' memory address is stored
# $s0 stores the number of viruses in the game
remove_virus_loop:
beq $t6, $s0, VIRUS_REMOVED
lw $t7, 4($t5)
sw $t7, 0($t5)
addi $t5, $t5, 4 # increment $t5
addi $t6, $t6, 1 # increment $t6
j remove_virus_loop

VIRUS_REMOVED:
# $t0, $t5, $t6, $t7 should be free to use
# print the number of viruses
# clear the current printed virus count
li $t6, 0
li $t7, 10
div $t5, $s0, 10
beq $t5, 0, virus_count_clear_single_digit
# handle two digit virus count here
lw $t0, ADDR_DSPL
div $s0, $t7
mflo $t5
jal draw_virus_count
addi $t0, $t0, -248
mfhi $t5
jal draw_virus_count
j virus_count_cleared
virus_count_clear_single_digit:
lw $t0, ADDR_DSPL
addi $t0, $t0, 4
add $t5, $zero, $s0 # store a copy of the virus count in $t5
jal draw_virus_count
j virus_count_cleared
virus_count_cleared:
addi $s0, $s0, -1 # reduce the number of viruses remaining in the game by 1
# print the new virus count
li $t6, 0xffff00
li $t7, 10
div $t5, $s0, 10
beq $t5, 0, virus_count_update_single_digit
# handle two digit virus count here
lw $t0, ADDR_DSPL
div $s0, $t7
mflo $t5
jal draw_virus_count
addi $t0, $t0, -248
mfhi $t5
jal draw_virus_count
j virus_count_updated
virus_count_update_single_digit:
lw $t0, ADDR_DSPL
addi $t0, $t0, 4
add $t5, $zero, $s0 # store a copy of the virus count in $t5
jal draw_virus_count
j virus_count_updated
virus_count_updated:
j VIRUS_REMOVAL_COMPLETE

VIRUS_NOT_FOUND:
j VIRUS_REMOVAL_COMPLETE


remove_capsule_from_array:
# $t4 stores the location/memory address of the block being cleared
# $s6 refers to the memory address right after the last memory address where we stored capsule information
# $t5-$t7 are available to use
lw $t5, ADDR_CPSL # $t5 stores the address of start of the array, this will be used to loop through the array and look for $t4
# loop through the array to find the capsule
capsule_search_loop:
beq $t5, $s6, CAPSULE_NOT_FOUND # this means we have gone through the entire array and could not find the capsule
lw $t6, 0($t5) # $t6 stores the value stored at $t5
beq $t4, $t6, CAPSULE_FOUND # if $t4 = $t6, that means the memory address stored at $t5 is equal to the address of the block being deleted i.e., we have found the block in the array
addi $t5, $t5, 4 # increment $t5
j capsule_search_loop

CAPSULE_NOT_FOUND:
j CAPSULE_REMOVAL_COMPLETE

CAPSULE_FOUND:
# $t5 is the memory location at which the memory address of the block being deleted is stored
lw $t6, 4($t5)
bgt $t6, 4, BLOCK_1_FOUND # if the value in the array right after the address of the block is > 4, that means we have found block 1 (since the next location in the array stores another memory location, not orientation)
# delete the capsule from the array and shift the array elements over accordingly
# else, we have found block 2 of a capsule, in order to delete a block, we must start from block 1, so we shift $t5 by -4 so that it now points to block 1 of that capsule
addi $t5, $t5, -4 # $t5 now points to the memory location which stores the address of block 1 of the capsule
BLOCK_1_FOUND:
# loop to shift the elements over and delete the capsule by overwriting it
capsule_shift_loop:
beq $t5, $s6, CAPSULE_SHIFT_LOOP_COMPLETE
lw $t7, 12($t5)
sw $t7, 0($t5)
addi $t5, $t5, 4
j capsule_shift_loop

CAPSULE_SHIFT_LOOP_COMPLETE:
addi $s6, $s6, -12
j CAPSULE_REMOVAL_COMPLETE


drop_down_blocks:
lw $t0, ADDR_DSPL
addi $t0, $t0, 1860 # $t0 now points to the first column of the second-last row in the playing area (row 29, column 1)
addi $t5, $zero, 29 # $t5 stores the current row
addi $t6, $zero, 1 # $t6 stores the current column
add $t7, $zero, $zero # $t7 is a counter that will be used to check if we have finished dropping blocks down
block_drop_down_loop:
beq $t5, 5, BLOCK_DROP_DOWN_ITERATION_COMPLETE
beq $t6, 15, BLOCK_DROP_DOWN_ROW_COMPLETE
# check if the current block is black
lw $t4, 0($t0)
beq $t4, 0x000000, BLOCK_DROP_DOWN_LOOP_UPDATE
# check if the current block is a virus
j check_virus
BLOCK_NOT_VIRUS:
# check if the current block is part of a capsule and handle accordingly
j check_capsule
BLOCK_IN_CAPSULE:
# $t1 stores the address in the array of capsule information at which the block was found
# $t2-$t6 are available to use
lw $t2, 4($t1) # $t2 stores the value at the next memory address in the array of capsules
bgt $t2, 4, BLOCK_IN_CAPSULE_BLOCK_ONE # # if the value in the array right after the address of the block is > 4, that means we have found block 1 (since the next location in the array stores another memory location, not orientation)
# else, we have found block 2 of a capsule, in order to delete a block, we must start from block 1, so we shift $t5 by -4 so that it now points to block 1 of that capsule
addi $t1, $t1, -4 # now, $t1 points to the array location where the first block of the capsule is stored
BLOCK_IN_CAPSULE_BLOCK_ONE:
# $t1 points to the array location where the first block of the capsule is stored
# $t2-$t6 are available to use
# we can also use $s1-$s5 since, at this point, they do not store information about any active capsule
# retrieve the capsule's information
lw $s1, 0($t1) # $s1 stores the position of block 1 of the capsule
lw $s2, 4($t1) # $s2 stores the position of block 2 of the capsule
lw $s3, 0($s1) # $s3 stores the colour of block 1 of the capsule
lw $s4, 0($s2) # $s4 stores the colour of block 2 of the capsule
lw $s5, 8($t1) # $s5 stores the capsule's orientation
j handle_capsule_drop_down
CAPSULE_DROP_DOWN_HANDLED:
j BLOCK_DROP_DOWN_LOOP_UPDATE
# if the code gets to this point, that means the block is a stand-alone block
BLOCK_NOT_IN_CAPSULE:
lw $t1, 64($t0)
bne $t1, 0x000000, BLOCK_DROP_DOWN_LOOP_UPDATE
lw $t1, 0($t0) 
li $t2, 0x000000
sw $t2, 0($t0)
sw $t1, 64($t0)
addi $t7, $t7, 1 # increment $t7, the counter that will be used to check whether the process of dropping blocks down has been completed
j BLOCK_DROP_DOWN_LOOP_UPDATE

BLOCK_DROP_DOWN_LOOP_UPDATE:
addi $t0, $t0, 4 # increment $t0, move to the next block in the row
addi $t6, $t6, 1 # increment the current column
j block_drop_down_loop

BLOCK_DROP_DOWN_ROW_COMPLETE:
addi $t5, $t5, -1 # decrement the current row
addi $t6, $zero, 1 # set the current column to 1
addi $t0, $t0, -120 # move $t0 to point to the first column of the row above
j block_drop_down_loop

BLOCK_DROP_DOWN_ITERATION_COMPLETE: # this means we have gone through the grid once and dropped all blocks down one unit (if appropriate)
beq $t7, 0, detect_sequence
# put the system to sleep for 100ms
li $v0, 32
li $a0, 100
syscall
j drop_down_blocks


check_virus:
# $t0 stores the current block
# $s0 stores the number of viruses remaining in the game
lw $t1, ADDR_VRS
add $t2, $zero, $zero # $t2 stores the index of the array of virus memory addresses we are currently at
check_virus_loop:
beq $t2, $s0, BLOCK_NOT_VIRUS
lw $t3, 0($t1)
beq $t0, $t3, BLOCK_DROP_DOWN_LOOP_UPDATE
addi $t1, $t1, 4 # increment $t1
addi $t2, $t2, 1 # increment $t2 (the index of the array of virus memory addresses we are currently at)
j check_virus_loop


check_capsule:
# $t0 stores the current block
# $s6 stores the memory address right after the address where we last stored information about a capsule
# $t1-$t6 are available to use
lw $t1, ADDR_CPSL
check_capsule_loop:
beq $t1, $s6, BLOCK_NOT_IN_CAPSULE
lw $t2, 0($t1)
beq $t2, $t0, BLOCK_IN_CAPSULE
addi $t1, $t1, 4 # increment $t1
j check_capsule_loop


handle_capsule_drop_down:
# $s1: position of block 1 of the capsule
# $s2: position of block 2 of the capsule
# $s3: colour of block 1 of the capsule
# $s4: colour of block 2 of the capsule
# $s5: orientation of the capsule
beq $s5, 1, capsule_drop_down_case_1
beq $s5, 2, capsule_drop_down_case_2
beq $s5, 3, capsule_drop_down_case_3
beq $s5, 4, capsule_drop_down_case_4
# one of these cases must always be satisfied, $s5 (orientation) must always be 1, 2, 3, or 4

capsule_drop_down_case_1:
lw $t2, 64($s1)
lw $t3, 64($s2)
# if the position below block 1 or block 2 is not empty (black), we cannot move down
bne $t2, 0x000000, END_OF_HANDLE_CAPSULE_DROP_DOWN
bne $t3, 0x000000, END_OF_HANDLE_CAPSULE_DROP_DOWN
# paint the current positions black
li $t2, 0x000000
sw $t2, 0($s1)
sw $t2, 0($s2)
# update the locations
addi $s1, $s1, 64
addi $s2, $s2, 64
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
# update the capsule's position in the array
sw $s1, 0($t1)
sw $s2, 4($t1)
addi $t7, $t7, 1 # increment $t7, the counter that will be used to check whether the process of dropping blocks down has been completed
j END_OF_HANDLE_CAPSULE_DROP_DOWN

capsule_drop_down_case_2:
lw $t2, 64($s2)
# if the position below block 2 is not empty (black), we cannot move down
bne $t2, 0x000000, END_OF_HANDLE_CAPSULE_DROP_DOWN
# paint the current positions black
li $t2, 0x000000
sw $t2, 0($s1)
sw $t2, 0($s2)
# update the locations
addi $s1, $s1, 64
addi $s2, $s2, 64
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
# update the capsule's position in the array
sw $s1, 0($t1)
sw $s2, 4($t1)
addi $t7, $t7, 1 # increment $t7, the counter that will be used to check whether the process of dropping blocks down has been completed
j END_OF_HANDLE_CAPSULE_DROP_DOWN

capsule_drop_down_case_3:
lw $t2, 64($s1)
lw $t3, 64($s2)
# if the position below block 1 or block 2 is not empty (black), we cannot move down
bne $t2, 0x000000, END_OF_HANDLE_CAPSULE_DROP_DOWN
bne $t3, 0x000000, END_OF_HANDLE_CAPSULE_DROP_DOWN
# paint the current positions black
li $t2, 0x000000
sw $t2, 0($s1)
sw $t2, 0($s2)
# update the locations
addi $s1, $s1, 64
addi $s2, $s2, 64
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
# update the capsule's position in the array
sw $s1, 0($t1)
sw $s2, 4($t1)
addi $t7, $t7, 1 # increment $t7, the counter that will be used to check whether the process of dropping blocks down has been completed
j END_OF_HANDLE_CAPSULE_DROP_DOWN

capsule_drop_down_case_4:
lw $t2, 64($s1)
# if the position below block 1 is not empty (black), we cannot move down
bne $t2, 0x000000, END_OF_HANDLE_CAPSULE_DROP_DOWN
# paint the current positions black
li $t2, 0x000000
sw $t2, 0($s1)
sw $t2, 0($s2)
# update the locations
addi $s1, $s1, 64
addi $s2, $s2, 64
# paint the new positions the appropriate colour
sw $s3, 0($s1)
sw $s4, 0($s2)
# update the capsule's position in the array
sw $s1, 0($t1)
sw $s2, 4($t1)
addi $t7, $t7, 1 # increment $t7, the counter that will be used to check whether the process of dropping blocks down has been completed
j END_OF_HANDLE_CAPSULE_DROP_DOWN

END_OF_HANDLE_CAPSULE_DROP_DOWN:
j CAPSULE_DROP_DOWN_HANDLED


draw_letter:
# the starting address to draw will be stored in $t0
# the ASCII value of the letter to be drawn will be stored in $t1
# the colour of the text will be stored in $t2
# the colour black will be stored in $t3
beq $t1, 0x62, draw_b
beq $t1, 0x65, draw_e
beq $t1, 0x68, draw_h
beq $t1, 0x69, draw_i
beq $t1, 0x6c, draw_l
beq $t1, 0x6d, draw_m
beq $t1, 0x6e, draw_n
beq $t1, 0x6f, draw_o
beq $t1, 0x73, draw_s
beq $t1, 0x74, draw_t
beq $t1, 0x75, draw_u
beq $t1, 0x77, draw_w
beq $t1, 0x79, draw_y

draw_b:
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t3, 8($t0)
jr $ra



draw_e:
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
jr $ra

draw_h:
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t3, 8($t0)
sw $t2, 12($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t3, 8($t0)
sw $t2, 12($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
sw $t2, 12($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t3, 8($t0)
sw $t2, 12($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t3, 8($t0)
sw $t2, 12($t0)
jr $ra

draw_i:
sw $t2, 0($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
jr $ra


draw_l:
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t3, 8($t0)
jr $ra

draw_m:
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
sw $t2, 12($t0)
sw $t2, 16($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
sw $t3, 12($t0)
sw $t2, 16($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
sw $t3, 12($t0)
sw $t2, 16($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
sw $t3, 12($t0)
sw $t2, 16($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
sw $t3, 12($t0)
sw $t2, 16($t0)
jr $ra

draw_n:
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t3, 8($t0)
sw $t3, 12($t0)
sw $t2, 16($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t3, 8($t0)
sw $t3, 12($t0)
sw $t2, 16($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
sw $t3, 12($t0)
sw $t2, 16($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t3, 8($t0)
sw $t2, 12($t0)
sw $t2, 16($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t3, 8($t0)
sw $t3, 12($t0)
sw $t2, 16($t0)
jr $ra


draw_o:
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
jr $ra


draw_s:
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
jr $ra

draw_t:
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t2, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t2, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t2, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t2, 4($t0)
sw $t3, 8($t0)
jr $ra

draw_u:
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
jr $ra

draw_w:
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
sw $t3, 12($t0)
sw $t2, 16($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
sw $t3, 12($t0)
sw $t2, 16($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
sw $t3, 12($t0)
sw $t2, 16($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
sw $t3, 12($t0)
sw $t2, 16($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
sw $t2, 12($t0)
sw $t2, 16($t0)
jr $ra

draw_y:
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t2, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t2, 4($t0)
sw $t3, 8($t0)
jr $ra


draw_number:
# the starting address to draw will be stored in $t0
# the number to be drawn will be stored in $t1
# the colour of the text will be stored in $t2
# the colour black will be stored in $t3
beq $t1, 0, draw_zero
beq $t1, 1, draw_one
beq $t1, 2, draw_two
beq $t1, 3, draw_three
beq $t1, 4, draw_four
beq $t1, 5, draw_five
beq $t1, 6, draw_six
beq $t1, 7, draw_seven
beq $t1, 8, draw_eight
beq $t1, 9, draw_nine

draw_zero:
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
jr $ra

draw_one:
sw $t3, 0($t0)
sw $t2, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t2, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t2, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t2, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t2, 4($t0)
sw $t3, 8($t0)
jr $ra

draw_two:
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
jr $ra

draw_three:
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
jr $ra

draw_four:
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
jr $ra

draw_five:
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
jr $ra

draw_six:
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t3, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
jr $ra

draw_seven:
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
jr $ra

draw_eight:
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
jr $ra

draw_nine:
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
addi $t0, $t0, 64
sw $t3, 0($t0)
sw $t3, 4($t0)
sw $t2, 8($t0)
jr $ra


GAME_OVER_LOSS:
jal clear_playing_area
lw $t0, ADDR_DSPL
li $t2, 0xffffff
li $t3, 0x000000
addi $t0, $t0, 136
li $t1, 0x79
jal draw_letter
addi $t0, $t0, -240
li $t1, 0x6f
jal draw_letter
addi $t0, $t0, -240
li $t1, 0x75
jal draw_letter
addi $t0, $t0, 92
li $t1, 0x6c
jal draw_letter
addi $t0, $t0, -244
li $t1, 0x6f
jal draw_letter
addi $t0, $t0, -240
li $t1, 0x73
jal draw_letter
addi $t0, $t0, -240
li $t1, 0x65
jal draw_letter
lw $t0, ADDR_DSPL
addi $t0, $t0, 1032
li $t1, 0xff0000
add $t2, $zero, $zero # $t2 stores the current row
add $t3, $zero, $zero # $t3 stores the current column
# virus should be 5 rows, 5 columns
jal draw_virus # draw the red virus
lw $t0, ADDR_DSPL
addi $t0, $t0, 1188
li $t1, 0x0000ff
add $t2, $zero, $zero # $t2 stores the current row
add $t3, $zero, $zero # $t3 stores the current column
jal draw_virus # draw the blue virus
lw $t0, ADDR_DSPL
addi $t0, $t0, 1484
li $t1, 0xffff00
add $t2, $zero, $zero # $t2 stores the current row
add $t3, $zero, $zero # $t3 stores the current column
jal draw_virus # draw the yellow virus
li $v0, 31
li $a2, 5
li $a3, 100
li $a0, 20
li $a1, 1500
syscall
li $a0, 35
li $a1, 1200
syscall
li $a0, 25
li $a1, 2000
syscall
li $a3, 80
li $a0, 40
li $a1, 1000
syscall
li $a3, 90
li $a0, 35
li $a1, 1500
syscall
li $a0, 35
li $a1, 1500
syscall
li $a0, 20
li $a1, 2000
syscall
# put the system to sleep for 3000ms
li $v0, 32
li $a0, 3000
syscall
j display_score

draw_dr_mario:
li $t1, 0x964B00
li $t2, 0xffffff
li $t3, 0x808080
li $t4, 0x0000ff
li $t5, 0x000000
li $t6, 0xffdbac
li $t7, 0xff746c
sw $t5, 0($t0)
sw $t5, 4($t0)
sw $t1, 8($t0)
sw $t1, 12($t0)
sw $t1, 16($t0)
sw $t1, 20($t0)
sw $t1, 24($t0)
sw $t1, 28($t0)
sw $t1, 32($t0)
sw $t1, 36($t0)
sw $t5, 40($t0)
sw $t5, 44($t0)
addi $t0, $t0, 64
sw $t5, 0($t0)
sw $t5, 4($t0)
sw $t3, 8($t0)
sw $t3, 12($t0)
sw $t3, 16($t0)
sw $t5, 20($t0)
sw $t5, 24($t0)
sw $t3, 28($t0)
sw $t3, 32($t0)
sw $t3, 36($t0)
sw $t5, 40($t0)
sw $t5, 44($t0)
addi $t0, $t0, 64
sw $t5, 0($t0)
sw $t5, 4($t0)
sw $t6, 8($t0)
sw $t6, 12($t0)
sw $t6, 16($t0)
sw $t6, 20($t0)
sw $t6, 24($t0)
sw $t6, 28($t0)
sw $t6, 32($t0)
sw $t6, 36($t0)
sw $t5, 40($t0)
sw $t5, 44($t0)
addi $t0, $t0, 64
sw $t5, 0($t0)
sw $t5, 4($t0)
sw $t6, 8($t0)
sw $t5, 12($t0)
sw $t5, 16($t0)
sw $t6, 20($t0)
sw $t6, 24($t0)
sw $t5, 28($t0)
sw $t5, 32($t0)
sw $t6, 36($t0)
sw $t5, 40($t0)
sw $t5, 44($t0)
addi $t0, $t0, 64
sw $t5, 0($t0)
sw $t5, 4($t0)
sw $t6, 8($t0)
sw $t6, 12($t0)
sw $t6, 16($t0)
sw $t6, 20($t0)
sw $t6, 24($t0)
sw $t6, 28($t0)
sw $t6, 32($t0)
sw $t6, 36($t0)
sw $t5, 40($t0)
sw $t5, 44($t0)
addi $t0, $t0, 64
sw $t5, 0($t0)
sw $t5, 4($t0)
sw $t6, 8($t0)
sw $t5, 12($t0)
sw $t5, 16($t0)
sw $t5, 20($t0)
sw $t5, 24($t0)
sw $t5, 28($t0)
sw $t5, 32($t0)
sw $t6, 36($t0)
sw $t5, 40($t0)
sw $t5, 44($t0)
addi $t0, $t0, 64
sw $t5, 0($t0)
sw $t5, 4($t0)
sw $t6, 8($t0)
sw $t6, 12($t0)
sw $t7, 16($t0)
sw $t7, 20($t0)
sw $t7, 24($t0)
sw $t7, 28($t0)
sw $t6, 32($t0)
sw $t6, 36($t0)
sw $t5, 40($t0)
sw $t5, 44($t0)
addi $t0, $t0, 64
sw $t5, 0($t0)
sw $t5, 4($t0)
sw $t6, 8($t0)
sw $t6, 12($t0)
sw $t6, 16($t0)
sw $t7, 20($t0)
sw $t7, 24($t0)
sw $t6, 28($t0)
sw $t6, 32($t0)
sw $t6, 36($t0)
sw $t5, 40($t0)
sw $t5, 44($t0)
addi $t0, $t0, 64
sw $t5, 0($t0)
sw $t5, 4($t0)
sw $t5, 8($t0)
sw $t5, 12($t0)
sw $t6, 16($t0)
sw $t6, 20($t0)
sw $t6, 24($t0)
sw $t6, 28($t0)
sw $t5, 32($t0)
sw $t5, 36($t0)
sw $t5, 40($t0)
sw $t5, 44($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
sw $t2, 12($t0)
sw $t2, 16($t0)
sw $t2, 20($t0)
sw $t2, 24($t0)
sw $t2, 28($t0)
sw $t2, 32($t0)
sw $t2, 36($t0)
sw $t2, 40($t0)
sw $t2, 44($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
sw $t2, 12($t0)
sw $t2, 16($t0)
sw $t2, 20($t0)
sw $t2, 24($t0)
sw $t2, 28($t0)
sw $t2, 32($t0)
sw $t2, 36($t0)
sw $t2, 40($t0)
sw $t2, 44($t0)
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
sw $t2, 12($t0)
sw $t2, 16($t0)
sw $t2, 20($t0)
sw $t2, 24($t0)
sw $t2, 28($t0)
sw $t2, 32($t0)
sw $t2, 36($t0)
sw $t2, 40($t0)
sw $t2, 44($t0)
addi $t0, $t0, 64
sw $t2, 0($t0)
sw $t2, 4($t0)
sw $t2, 8($t0)
sw $t2, 12($t0)
sw $t2, 16($t0)
sw $t2, 20($t0)
sw $t2, 24($t0)
sw $t2, 28($t0)
sw $t2, 32($t0)
sw $t2, 36($t0)
sw $t2, 40($t0)
sw $t2, 44($t0)
jr $ra


draw_virus:
# $t0: base address to draw the virus
# $t1: colour of the virus
# $t2: current row
# $t3: current column
draw_virus_loop:
blt $t2, 5, draw_virus_continue
jr $ra
draw_virus_continue:
beq $t2, 0, draw_virus_row_top_and_bottom
beq $t2, 1, draw_virus_row_eyes
beq $t2, 2, draw_virus_row_full_colour
beq $t2, 3, draw_virus_row_mouth
beq $t2, 4, draw_virus_row_top_and_bottom

draw_virus_row_full_colour:
add $t3, $zero, $zero # $t3 stores the current column
draw_virus_row_full_colour_loop:
beq $t3, 5, draw_virus_row_complete
sw $t1, 0($t0)
addi $t0, $t0, 4
addi $t3, $t3, 1
j draw_virus_row_full_colour_loop

draw_virus_row_eyes:
add $t3, $zero, $zero # $t3 stores the current column
draw_virus_row_eyes_loop:
beq $t3, 5, draw_virus_row_complete
andi $t4, $t3, 0000000000000001 # stores 0 in $t4 if $t3 is even, and 1 if it is odd
beq $t4, 0, draw_virus_row_eyes_loop_fill
addi $t0, $t0, 4
addi $t3, $t3, 1
j draw_virus_row_eyes_loop

draw_virus_row_eyes_loop_fill:
sw $t1, 0($t0)
addi $t0, $t0, 4
addi $t3, $t3, 1
j draw_virus_row_eyes_loop

draw_virus_row_mouth:
add $t3, $zero, $zero # $t3 stores the current column
draw_virus_row_mouth_loop:
beq $t3, 5, draw_virus_row_complete
beq $t3, 0, draw_virus_row_mouth_loop_fill
beq $t3, 4, draw_virus_row_mouth_loop_fill
addi $t0, $t0, 4
addi $t3, $t3, 1
j draw_virus_row_mouth_loop

draw_virus_row_mouth_loop_fill:
sw $t1, 0($t0)
addi $t0, $t0, 4
addi $t3, $t3, 1
j draw_virus_row_mouth_loop


draw_virus_row_top_and_bottom:
add $t3, $zero, $zero # $t3 stores the current column
draw_virus_row_top_and_bottom_loop:
beq $t3, 5, draw_virus_row_complete
beq $t3, 1, draw_virus_row_top_and_bottom_loop_fill
beq $t3, 2, draw_virus_row_top_and_bottom_loop_fill
beq $t3, 3, draw_virus_row_top_and_bottom_loop_fill
addi $t0, $t0, 4
addi $t3, $t3, 1
j draw_virus_row_top_and_bottom_loop

draw_virus_row_top_and_bottom_loop_fill:
sw $t1, 0($t0)
addi $t0, $t0, 4
addi $t3, $t3, 1
j draw_virus_row_top_and_bottom_loop

draw_virus_row_complete:
addi $t2, $t2, 1
addi $t0, $t0, 44
j draw_virus_loop

clear_playing_area:
lw $t0, ADDR_DSPL
li $t1, 0x000000
addi $t2, $zero, 0
addi $t3, $zero, 0
clear_playing_area_loop:
blt $t2, 32, clear_playing_area_continue
jr $ra
clear_playing_area_continue:
beq $t3, 16, row_cleared
sw $t1, 0($t0)
addi $t3, $t3, 1
addi $t0, $t0, 4
j clear_playing_area_loop

row_cleared:
addi $t2, $t2, 1
add $t3, $zero, $zero
j clear_playing_area_loop

GAME_OVER_WIN:
jal clear_playing_area
lw $t0, ADDR_DFCL
lw $t0, 0($t0)
beq $t0, 1, player_score_win_easy
beq $t0, 2, player_score_win_medium
beq $t0, 3, player_score_win_hard
player_score_win_easy:
addi $t9, $t9, 20
j player_score_win_handled
player_score_win_medium:
addi $t9, $t9, 30
j player_score_win_handled
player_score_win_hard:
addi $t9, $t9, 50
j player_score_win_handled
player_score_win_handled:
lw $t0, ADDR_DSPL
li $t2, 0xffffff
li $t3, 0x000000
addi $t0, $t0, 136
li $t1, 0x79
jal draw_letter
addi $t0, $t0, -240
li $t1, 0x6f
jal draw_letter
addi $t0, $t0, -240
li $t1, 0x75
jal draw_letter
addi $t0, $t0, 92
li $t1, 0x77
jal draw_letter
addi $t0, $t0, -232
li $t1, 0x69
jal draw_letter
addi $t0, $t0, -248
li $t1, 0x6e
jal draw_letter
lw $t0, ADDR_DSPL
addi $t0, $t0, 1032
jal draw_dr_mario
li $v0, 31
li $a2, 10
li $a3, 120
li $a0, 60
li $a1, 1000
syscall
li $a0, 64
li $a1, 1000
syscall
li $a0, 67
li $a1, 1000
syscall
li $a0, 72
li $a1, 1200
syscall
li $a0, 76
li $a1, 1200
syscall
li $a3, 110
li $a0, 79
li $a1, 1500
syscall
# put the system to sleep for 3000ms
li $v0, 32
li $a0, 3000
syscall
j display_score


display_score:
jal clear_playing_area
# $t9 has the current score
# the high score is stored at ADDR_HIGH_SCR
lw $t0, ADDR_HIGH_SCR
lw $t0, 0($t0)
# the high score is now stored in $t0
bgt $t9, $t0, display_score_high_score
# display just the score
li $t2, 0xffffff
li $t3, 0
div $t1, $t9, 10
beq $t1, 0, score_one_digit
div $t1, $t9, 100
beq $t1, 0, score_two_digit
div $t1, $t9, 1000
beq $t1, 0, score_three_digit
div $t1, $t9, 10000
beq $t1, 0, score_four_digit
# assume the score is capped at 4-digit length, if its greater set the score to 9999
addi $t9, $zero, 9999
j score_four_digit

score_one_digit:
lw $t0, ADDR_DSPL
addi $t0, $t0, 796
li $t4, 10
div $t9, $t4
mflo $t9
mfhi $t1
jal draw_number
j score_printed

score_two_digit:
lw $t0, ADDR_DSPL
addi $t0, $t0, 784
li $t4, 10
div $t9, $t4
mflo $t1
jal draw_number
mfhi $t1
addi $t0, $t0, -240
jal draw_number
j score_printed

score_three_digit:
lw $t0, ADDR_DSPL
addi $t0, $t0, 780
li $t4, 100
div $t9, $t4
mflo $t1
jal draw_number
mfhi $t9
addi $t0, $t0, -240
li $t4, 10
div $t9, $t4
mflo $t1
jal draw_number
mfhi $t1
addi $t0, $t0, -240
jal draw_number
j score_printed

score_four_digit:
lw $t0, ADDR_DSPL
addi $t0, $t0, 772
li $t4, 1000
div $t9, $t4
mflo $t1
jal draw_number
mfhi $t9
addi $t0, $t0, -240
li $t4, 100
div $t9, $t4
mflo $t1
jal draw_number
mfhi $t9
addi $t0, $t0, -240
li $t4, 10
div $t9, $t4
mflo $t1
jal draw_number
mfhi $t1
addi $t0, $t0, -240
jal draw_number
j score_printed

score_printed:
j END


display_score_high_score:
# display the score along with the text new best
lw $t0, ADDR_HIGH_SCR
sw $t9, 0($t0)
# the score is stored as the new high score
li $t2, 0xffffff
li $t3, 0
div $t1, $t9, 10
beq $t1, 0, high_score_one_digit
div $t1, $t9, 100
beq $t1, 0, high_score_two_digit
div $t1, $t9, 1000
beq $t1, 0, high_score_three_digit
div $t1, $t9, 10000
beq $t1, 0, high_score_four_digit
# assume the score is capped at 4-digit length, if its greater set the score to 9999
addi $t9, $zero, 9999
j high_score_four_digit
high_score_printed:
# print new best
lw $t0, ADDR_DSPL
addi $t0, $t0, 836
li $t1, 0x6e
jal draw_letter
addi $t0, $t0, -232
li $t1, 0x65
jal draw_letter
addi $t0, $t0, -240
li $t1, 0x77
jal draw_letter
addi $t0, $t0, 88
li $t1, 0x62
jal draw_letter
addi $t0, $t0, -240
li $t1, 0x65
jal draw_letter
addi $t0, $t0, -240
li $t1, 0x73
jal draw_letter
addi $t0, $t0, -240
li $t1, 0x74
jal draw_letter
j END

high_score_one_digit:
lw $t0, ADDR_DSPL
addi $t0, $t0, 348
li $t4, 10
div $t9, $t4
mflo $t9
mfhi $t1
jal draw_number
j high_score_printed

high_score_two_digit:
lw $t0, ADDR_DSPL
addi $t0, $t0, 336
li $t4, 10
div $t9, $t4
mflo $t1
jal draw_number
mfhi $t1
addi $t0, $t0, -240
jal draw_number
j high_score_printed

high_score_three_digit:
lw $t0, ADDR_DSPL
addi $t0, $t0, 332
li $t4, 100
div $t9, $t4
mflo $t1
jal draw_number
mfhi $t9
addi $t0, $t0, -240
li $t4, 10
div $t9, $t4
mflo $t1
jal draw_number
mfhi $t1
addi $t0, $t0, -240
jal draw_number
j high_score_printed

high_score_four_digit:
lw $t0, ADDR_DSPL
addi $t0, $t0, 324
li $t4, 1000
div $t9, $t4
mflo $t1
jal draw_number
mfhi $t9
addi $t0, $t0, -240
li $t4, 100
div $t9, $t4
mflo $t1
jal draw_number
mfhi $t9
addi $t0, $t0, -240
li $t4, 10
div $t9, $t4
mflo $t1
jal draw_number
mfhi $t1
addi $t0, $t0, -240
jal draw_number
j high_score_printed
j END

END:
jal clear_capsule_array
jal clear_virus_array
end_game_loop:
lw $t1, ADDR_KBRD
lw $t1, 0($t1)
bne $t1, 1, end_game_loop
lw $t1, ADDR_KBRD
lw $t1, 4($t1)
beq $t1, 0x72, start_game
beq $t1, 0x71, GAME_OVER
j end_game_loop

GAME_OVER:
jal clear_playing_area
li $v0, 10
syscall
