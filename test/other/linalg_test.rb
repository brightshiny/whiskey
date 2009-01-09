require 'linalg'

a1 = Linalg::DMatrix[
  [1,1,1],
  [0,1,1],
  [1,0,0],
  [0,1,0],
  [1,0,0],
  [1,0,1],
  [1,1,1],
  [1,1,1],
  [1,0,1],
  [0,2,0],
  [0,1,1]
]

# m = Linalg::DMatrix[
#   [4,0],
#   [3,-5]
# ]   

puts 
puts "A:  "
puts a1  

u, s, vt = a1.singular_value_decomposition

puts 
puts "U:  "
puts u

puts 
puts "S:  "
puts s

puts 
puts "Vt: "
puts vt

puts 
puts "Reconstituting A: "
a2 = u * s * vt
puts a2
