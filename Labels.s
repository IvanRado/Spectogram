
X_AXIS_NAME .skip 9

Y_AXIS_NAME .skip 9


movia r20, X_AXIS_NAME				# Initialize the axis

movi r19, 70			# Move 'F'
stb r19, 0(r20)
addi r19, r19,1 

movi r19, 82			# Move 'R'
stb r19, 0(r20)
addi r19, r19,1 

movi r19, 69			# Move 'E'
stb r19, 0(r20)
addi r19, r19,1 

movi r19, 81			# Move 'Q'
stb r19, 0(r20)
addi r19, r19,1 

movi r19, 85			# Move 'U'
stb r19, 0(r20)
addi r19, r19,1 

movi r19, 69			# Move 'E'
stb r19, 0(r20)
addi r19, r19,1 

movi r19, 78			# Move 'N'
stb r19, 0(r20)
addi r19, r19,1 

movi r19, 67			# Move 'C'
stb r19, 0(r20)
addi r19, r19,1 

movi r19, 89			# Move 'Y'
stb r19, 0(r20)
addi r19, r19,1 


movia r20, Y_AXIS_NAME				# Initialize the axis

movi r19, 77			# Move 'M'
stb r19, 0(r20)
addi r19, r19,1 

movi r19, 65			# Move 'A'
stb r19, 0(r20)
addi r19, r19,1 

movi r19, 71			# Move 'G'
stb r19, 0(r20)
addi r19, r19,1 

movi r19, 78			# Move 'N'
stb r19, 0(r20)
addi r19, r19,1 

movi r19, 73			# Move 'I'
stb r19, 0(r20)
addi r19, r19,1 

movi r19, 84			# Move 'T'
stb r19, 0(r20)
addi r19, r19,1 

movi r19, 85			# Move 'U'
stb r19, 0(r20)
addi r19, r19,1 

movi r19, 68			# Move 'D'
stb r19, 0(r20)
addi r19, r19,1 

movi r19, 69			# Move 'E'
stb r19, 0(r20)
addi r19, r19,1 



# Draw the x label

movia r17, TEXT			# Get address
movi r19, 59			# Second last line	
slli r19, 7				# Multiply by 128
add r17, r19, r19		# Implement the y offset
addi r17, r17, 35		# Start at the appropriate address

movia r19, X_AXIS_NAME
ldb r21, 0(r19)
stbio r21, 0(r17)

 addi r19, r19, 1
 ldb r21, 0(r19)
stbio r21, 0(r17)

addi r19,r19, 1
ldb r21, 0(r19)
stbio r21, 0(r17)

addi r19, r19, 1
ldb r21, 0(r19)
stbio r21, 0(r17)

addi r19, r19, 1
ldb r21, 0(r19)
stbio r21, 0(r17)

addi r19, r19, 1
ldb r21, 0(r19)
stbio r21, 0(r17)

addi r19, r19, 1
ldb r21, 0(r19)
stbio r21, 0(r17)

addi r19, r19, 1
ldb r21, 0(r19)
stbio r21, 0(r17)

addi r19, r19, 1
ldb r21, 0(r19)
stbio r21, 0(r17)
 
# Draw y label
movia r17, TEXT			# Get address
movi r19, 26			# Second third line	
slli r19, 7				# Multiply by 128
add r17, r19, r19		# Implement the y offset
addi r17, r17, 3		# Start at the appropriate address

movia r19, Y_AXIS_NAME
ldb r21, 0(r19)
stbio r21, 0(r17)

 addi r19, r19, 128
 ldb r21, 0(r19)
stbio r21, 0(r17)

addi r19,r19, 128
ldb r21, 0(r19)
stbio r21, 0(r17)

addi r19, r19, 128
ldb r21, 0(r19)
stbio r21, 0(r17)

addi r19, r19, 128
ldb r21, 0(r19)
stbio r21, 0(r17)

addi r19, r19, 128
ldb r21, 0(r19)
stbio r21, 0(r17)

addi r19, r19, 128
ldb r21, 0(r19)
stbio r21, 0(r17)

addi r19, r19, 128
ldb r21, 0(r19)
stbio r21, 0(r17)

addi r19, r19, 128
ldb r21, 0(r19)
stbio r21, 0(r17)
