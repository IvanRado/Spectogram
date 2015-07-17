.equ HEX, 0x10000030 

# Just set the hex values to display what operation has been performed on the sampled frequency

# For Low Pass Filter
# To write LO, Hex 7 has 0111000, Hex 6 has 0111111

movia r17, HEX
movia r19, 0x38000000		# Set Hex 7 to display a L
movia r21, 0x3F000000		# Set Hex 6 to display an O
add r19, 19, r21			# Combine the two values for the overall value we wish to write
stwio r19, 0(r17)			# Display to HEX 6 and 7


# For High Pass Filter
# To write HI, Hex 7 has 1110110, Hex 6 has 0000110

movia r17, HEX
movia r19, 0x76000000		# Set Hex 7 to display a H
movia r21, 0x06000000		# Set Hex 6 to display an I
add r19, 19, r21			# Combine the two values for the overall value we wish to write
stwio r19, 0(r17)			# Display to HEX 6 and 7


# For Band Pass Filter
# To Write BA, Hex 7 has 1111100, Hex 6 has 1110111

movia r17, HEX
movia r19, 0x7C000000		# Set Hex 7 to display a 'b'
movia r21, 0x77000000		# Set Hex 6 to display an A
add r19, 19, r21			# Combine the two values for the overall value we wish to write
stwio r19, 0(r17)			# Display to HEX 6 and 7