using DataStructures
using DataFrames

### 1 - Read data

data = readdlm("../data/haberman.data")

## Convert to data frame

df = convert(DataFrame,data)
names!(df, [Symbol("Age"), Symbol("Annee"), Symbol("Nodules"), Symbol("Y")])

### 2 - Encoding

# Add columns that will contain categories for numerical values 
df[:x1] = 0 # Categ : age
df[:x2] = 0 # categ : Annee
df[:x3] = 0 # Categ : Nod

#define useful functions to get categories
function to_category_age(x,size)
    return div.(x,size)
end

## Transformation
# Split ages into categories of 10 years
df[:x1] = to_category_age(df[:Age],10) - 2 # -2 to start indices from 1

# Split year among even and odd years
df[:x2] = df[:Annee] - 47 # -47 because first year is 58
# indices describing years start to 11 for 1958 (because 1 already taken by age)
# indices end at 22 for 1969

# Categories for Nodules
for i = 1:size(df,1)
    if df[i,:Nodules] <= 4 
        df[i,:x3] = df[i,:Nodules]
	end
	if (df[i,:Nodules] >= 5) && (df[i,:Nodules] <= 10)
		df[i,:x3] = 5
	end
    if (df[i,:Nodules] > 10)
		df[i,:x3] = 6
	end
end
df[:x3] = df[:x3] + 30 # 30 to separate categories indices

## At this stage we have all categories 

## Encoding (binary using new added categories)

#Cleaning
df[:indice] = collect(1:size(df,1)) # Add indices to the dataframe, useful in pivot-table
delete!(df,:Age)
delete!(df,:Annee)
delete!(df,:Nodules)
println(df)

df[:tmp] = 1
df = unstack(df, :x1, :tmp)
[df[isna.(df[col]), col] = 0 for col in names(df)]

df[:tmp] = 1
df = unstack(df, :x2, :tmp)
[df[isna.(df[col]), col] = 0 for col in names(df)]

df[:tmp] = 1
df = unstack(df, :x3, :tmp)
[df[isna.(df[col]), col] = 0 for col in names(df)]

Y = df[:Y]
delete!(df,:Y)
df[:Y] = Y
println(df)

# A function to split data

function partitionTrainTest(data, pct)
    n = nrow(data) # dataset size
    idx = shuffle(1:n) # randomly permutes the 1:n vector
    train_idx = view(idx, 1:floor(Int, pct*n)) # takes the first part of the permuted data frame as train data
    test_idx = view(idx, (floor(Int, pct*n)+1):n) # the second part as test data
    data[train_idx,:], data[test_idx,:]
end

#Fix seed
#srand(123)
srand(666)
train, test = partitionTrainTest(df, 0.66)

#### 3 - Output

n,d = size(train)
t = convert(Array,train[:,2:d-1]) # get the transaction as an array
transactionClass = train[:,end]

fout = open("../data/haberman_train2.dat","w")
println(fout,"n = ",n)
println(fout,"d = ",d-2)
println(fout,"t = ",t)
println(fout,"transactionClass = ",transactionClass)
close(fout)

n,d = size(test)
t = convert(Array,test[:,2:d-1]) # get the transaction as an array
transactionClass = test[:,end]

fout = open("../data/haberman_test2.dat","w")
println(fout,"n = ",n)
println(fout,"d = ",d-2)
println(fout,"t = ",t)
println(fout,"transactionClass = ",transactionClass)
close(fout)

