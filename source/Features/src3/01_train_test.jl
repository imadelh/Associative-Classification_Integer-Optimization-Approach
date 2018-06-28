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

## Transformation
# Split ages into categories of 15 years
for i = 1:size(df,1)
    if df[i,:Age] <= 44
        df[i,:x1] = 1
    end
    if (df[i,:Age] >= 45) && (df[i,:Age] <= 59)
        df[i,:x1] = 2
    end
    if (df[i,:Age] >= 60)
        df[i,:x1] = 3
    end
end

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

#srand(123)
srand(666)
train, test = partitionTrainTest(df, 0.66)

#### 3 - Output

n,d = size(train)
t = convert(Array,train[:,2:d-1]) # get the transaction as an array
transactionClass = train[:,end]

fout = open("../data/haberman_train3.dat","w")
println(fout,"n = ",n)
println(fout,"d = ",d-2)
println(fout,"t = ",t)
println(fout,"transactionClass = ",transactionClass)
close(fout)

n,d = size(test)
t = convert(Array,test[:,2:d-1]) # get the transaction as an array
transactionClass = test[:,end]

fout = open("../data/haberman_test3.dat","w")
println(fout,"n = ",n)
println(fout,"d = ",d-2)
println(fout,"t = ",t)
println(fout,"transactionClass = ",transactionClass)
close(fout)