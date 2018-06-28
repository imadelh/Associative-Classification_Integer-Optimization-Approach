using JuMP
using CPLEX

### Initialization

include("../data/ttt_train.dat")
# Contains:
# - d: the number of features
# - n: the number of transactions in the training set
# - t: the transactions in the training set (each line is a transaction)
# - transactionClass: class of the transactions

mincovy = 0.05
iterlim = 5
RgenX = 0.1 / n
RgenB = 0.1 / (n * d)

### Algorithm

function RuleGen(mincovy,iterlim,RgenB,RgenX)
	
	R = Matrix(0,d+1)

	for y in 0:1
		
		s_bar = 0 # objective value for the last solved problem
		iter = 1
		s_bar_x = n # upper bound for cover

		m = Model(solver = CplexSolver(CPX_PARAM_SCRIND=0))
		@variable(m, x[i in 1:n], Bin)
		#@variable(m, 0<=x[i in 1:n]<=1)
		@variable(m, b[j in 1:d], Bin)
		@objective(m, Max, sum(x[i] for i in 1:n if transactionClass[i] == y) - RgenX * sum(x[i] for i in 1:n) - RgenB * sum(b[j] for j in 1:d))
		@constraint(m,contraint1, sum(x[i] for i in 1:n) <= s_bar_x)
		@constraint(m,contraint2[i = 1:n, j = 1:d], x[i] <= 1 + (t[i,j] - 1) * b[j])
		@constraint(m,contraint3[i = 1:n], x[i] >= 1 + sum(((t[i,j] - 1) * b[j]) for j in 1:d))

		while(s_bar_x >= n * mincovy)
			if iter == 1
				#Update constraint1. N2 and 3 are the always same
				JuMP.setRHS(contraint1, s_bar_x) 
				solve(m)
				println("Done with first pb optimization")
				x_star = getvalue(x)
				b_star = round.(Int,getvalue(b))
				s_bar = sum(x_star[i] for i in 1:n if transactionClass[i] == y)
				iter = iter + 1
			end
		    s = sum(b_star) # If the sum on the rule is 0 then we have a null rule
			vect = push!(b_star,y)
			#we save only non-nul rules
		    if(s>0)	        
				println(vect)
				R = vcat(R, transpose(vect))
				println("Appended the generated rule")
		    end

			# Add the other constraint on b
			@constraint(m, sum(b[j] for j in 1:d if b_star[j] == 0) + sum((1 - b[j]) for j in 1:d if b_star[j] == 1) >= 1)
			
			if iter < iterlim
				solve(m)
				println("Solved again")
				x_star = getvalue(x)
				b_star = round.(Int,getvalue(b))

				if sum(x_star[i] for i in 1:n if transactionClass[i] == y) < s_bar
					s_bar_x = min(s_bar_x - 1, sum(x_star[i] for i in 1:n))
					iter = 1
				else
					iter = iter + 1
				end
			else
				s_bar_x = s_bar_x - 1
				iter = 1
			end
		end
		println("Done with the current class")
	end
	return R
end


### Rule Generation
tic();

R = RuleGen(mincovy,iterlim,RgenB,RgenX)

toc();

### Output

fout = open("../res/rules.dat","w")
println(fout,"rules = ", convert(Array,R[:,1:end-1]))
println(fout,"ruleClass = ", reduce(hcat, R[:,end]))
close(fout)
