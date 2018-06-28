using DataStructures
using DataFrames

### 1 - Read data

data = readdlm("../data/onehot.csv")

n,d = size(data)

## Delete head

d = data[2:n,:]

df = convert(DataFrame,d)

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

fout = open("../data/ttt_train.dat","w")
println(fout,"n = ",n)
println(fout,"d = ",d-2)
println(fout,"t = ",t)
println(fout,"transactionClass = ",transactionClass)
close(fout)

n,d = size(test)
t = convert(Array,test[:,2:d-1]) # get the transaction as an array
transactionClass = test[:,end]

fout = open("../data/ttt_test.dat","w")
println(fout,"n = ",n)
println(fout,"d = ",d-2)
println(fout,"t = ",t)
println(fout,"transactionClass = ",transactionClass)
close(fout)

