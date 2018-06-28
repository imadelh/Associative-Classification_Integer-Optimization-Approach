### Last step - Validation

# The aim is to use the ordered rules generated at step 3
# on the test dataset and then compute the error.

# Test dataset :
# Contains the following variables:
# - d: the number of features
# - n: the number of transactions in the testing set
# - t: the transactions in the testing set (each line is a transaction)
# - transactionClass: class of the transactions
include("../data/haberman_test2.dat")

# Ordered rules :
# Contains the following variables
# - rules: the created rules (each line is a rule)
# - ruleClass: the class of each rule
include("../res/haberman_ordered_rules2.dat")

eps = 0.00001

L = size(rules)[1]

# Define the class vector for the test set
class = zeros(n)

# Apply the ordered rules to the transactions of the test set
for i in 1:n
	verif = 0
	l = 1
	# As soon as a rule is verified the class is found
	while (l <= L && verif == 0)
		if !any(x->x<-eps, t[i, :]-rules[l, :])
			verif = 1
			class[i] = ruleClass[l]
		end
		l += 1
	end
end

# There should not be any 0 anymore
println("=== Predicted classes === ")
println(class)
println("=== True classes === ")
println(transactionClass)
println("================================== ")
errors = sum(abs.(class - transactionClass))*100/n
println("Accuracy = ", 100 - errors)
println("Error_percentage = ", errors)
