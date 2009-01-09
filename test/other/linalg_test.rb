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

cols_for_u2 = []
cols_for_v2 = []
eigenvectors = []
k = 2 # dimensionality reduction
k.times do |n|
  cols_for_u2.push(u.column(n))
  cols_for_v2.push(vt.column(n))
  eigenvectors.push(s.column(n).to_a.flatten[0,k])
end
u2 = Linalg::DMatrix.join_columns(cols_for_u2)
v2 = Linalg::DMatrix.join_columns(cols_for_v2)
eig2 = Linalg::DMatrix.columns(eigenvectors)

q = Linalg::DMatrix[[0,0,0,0,0,1,0,0,0,1,1]]
qEmbed = q * u2 * eig2.inverse

similarity_matrix, count = {}, 1
v2.rows.each { |x|
  similarity_matrix[count] = (qEmbed.transpose.dot(x.transpose)) / (x.norm * qEmbed.norm)
  count += 1
}

puts

similarity_matrix.each { |u| printf "ID: %d, Similarity: %0.3f \n", u[0], u[1]  }

