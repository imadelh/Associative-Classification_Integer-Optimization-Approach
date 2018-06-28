using JuMP
using CPLEX

eps = 0.00001

# Contains the following variables:
# - d: the number of features
# - n: the number of transactions in the training set
# - t: the transactions in the training set (each line is a transaction)
# - transactionClass: class of the transactions
include("../data/ttt_train.dat")

# Contains the following variables
# - rules: the created rules (each line is a rule)
# - ruleClass: the class of each rule
include("../res/rules.dat")

tic();

# Add the two null rules
rules = convert(Array{Float64},rules)
rules = vcat(rules, zeros(2,d))
#rules = [rules, zeros(2, d)]
ruleClass = [ruleClass 1 0]

# Number of rules
L = size(rules)[1]

Rrank = 1/L

################
# Compute the v_il and p_il constants
# p_il = :
#  0 if rule l does not apply to transaction i
#  1 if rule l applies to transaction i and   correctly classifies it
# -1 if rule l applies to transaction i and incorrectly classifies it
################
p = zeros(n, L)

# For each transaction and each rule
for i in 1:n
    for l in 1:L

        # If rule l applies to transaction i
        # i.e., if the vector t_i - r_l does not contain any negative value
        if !any(x->x<-eps, t[i, :]-rules[l, :])

            # If rule l correctly classifies transaction i
            if transactionClass[i] == ruleClass[l]
                p[i,l] = 1
            else
                p[i, l] = -1 
            end
        end
    end
end

v = abs.(p)

################
# Create and solve the model
###############
m = Model(solver=CplexSolver(CPX_PARAM_SCRIND=0))

# u_il: rule l is the highest which applies to transaction i
@variable(m, u[1:n, 1:L], Bin)

# r_l: rank of rule l
@variable(m, 1 <= r[1:L] <= L, Int)

# rstar: rank of the highest null rule
@variable(m, 1 <= rstar <= L)@variable(m, 1 <= rB <= L)

# g_i: rank of the highest rule which applies to transaction i
@variable(m, 1 <= g[1:n] <= L, Int)

# s_lk: rule l is assigned to rank k
@variable(m, s[1:L,1:L], Bin)

# Rank of null rules

rA = r[L-1]
rB = r[L]

# rstar == rB?
@variable(m, alpha, Bin)

# rstar == rA?
@variable(m, 0 <= beta <= 1)

# Maximize the classification accuracy
@objective(m, Max, sum(p[i, l] * u[i, l] for i in 1:n for l in 1:L)
           + Rrank * rstar)

# Only one rule is the highest which applies to transaction i
@constraint(m, [i in 1:n], sum(u[i, l] for l in 1:L) == 1)

# g constraints
@constraint(m, [i in 1:n, l in 1:L], g[i] >= v[i, l] * r[l])
@constraint(m, [i in 1:n, l in 1:L], g[i] <= v[i, l] * r[l] + L * (1 - u[i, l]))

# Relaxation improvement
@constraint(m, [i in 1:n, l in 1:L], u[i, l] >= 1 - g[i] + v[i, l] * r[l])
@constraint(m, [i in 1:n, l in 1:L], u[i, l] <= v[i, l]) 

# r constraints
@constraint(m, [k in 1:L], sum(s[l, k] for l in 1:L) == 1)
@constraint(m, [l in 1:L], sum(s[l, k] for k in 1:L) == 1)
@constraint(m, [l in 1:L], r[l] == sum(k * s[l, k] for k in 1:L))

# rstar constraints
@constraint(m, rstar >= rA)
@constraint(m, rstar >= rB)
@constraint(m, rstar - rA <= (L-1) * alpha)
@constraint(m, rA - rstar <= (L-1) * alpha)
@constraint(m, rstar - rB <= (L-1) * beta)
@constraint(m, rB - rstar <= (L-1) * beta)
@constraint(m, alpha + beta == 1)

# u_il == 0 if rstar > rl (also improve relaxation)
@constraint(m, [i in 1:n, l in 1:L], u[i, l] <= 1 - (rstar - r[l])/ (L - 1))


println("Start Solving")

solve(m)

toc();

###############
# Write the rstar highest ranked rules and their corresponding class
###############

# Number of rules kept in the classifier
# (all the rules ranked lower than rstar are removed)
relevantNbOfRules=L-round(Int, getvalue(rstar))+1

# Sort the rules and their class by decreasing rank
rulesOrder = getvalue(r[:])
rules = rules[sortperm(L-rulesOrder), :]
ruleClass = ruleClass[sortperm(L-rulesOrder)]

fout = open("../res/ordered_rules.dat", "w")
println(fout, "rules = ", rules[1:relevantNbOfRules, :])
println(fout, "ruleClass = ", ruleClass[1:relevantNbOfRules])
