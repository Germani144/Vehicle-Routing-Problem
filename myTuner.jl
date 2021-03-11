using Statistics

function tuneParams()
    # If one wishes to see it working, reduce the options of T and alpha to only 2
    # as well as time limit to 0.1s and the number of samples to 1, since the way
    # it is it will run for 4h43min
    T::Array{Float64} = [1000.0,500.0,100.0]
    alpha::Array{Float64} = [0.99,0.98,0.97]
    time_limit::Float64 = 30
    samples::Int64 = 5
    instances::Array{String} = ["c1_2_","c2_2_","r1_2_","r2_2_"]
    possibilities = Dict{String,Dict}([])

    # Different instance suffixes for test and train sets
    train_set = [1,5,9]
    test_set = 2

    for t in T, a in alpha
        key = string(t,"/",a)
        result = Dict{String,Real}([])
        result["Avg"] = 0.0
        result["Pop"] = 0
        possibilities[key] = result
        for inst in instances
            for x in train_set
                for exec in 1:samples
                    cost = solveInstance(string(inst,x,".","txt"),time_limit,t,a,1,0)
                    #check cost difference
                    obj = instances_dict[inst][x]["Vehicles"]*instances_dict[inst][x]["Distance"]
                    gap = (cost-obj)/obj
                    println(string(inst,x)," ",t,"/",a," gap = ",gap)
                    old_avg = possibilities[key]["Avg"]
                    old_pop = possibilities[key]["Pop"]
                    possibilities[key]["Avg"] = (old_avg*old_pop+gap)/(old_pop+1)
                    possibilities[key]["Pop"] += 1
                end
            end
        end
    end
    best_pair = "None"
    best_value = Inf
    for i in zip(collect(keys(possibilities)),collect(values(possibilities)))
        if i[2]["Avg"] < best_value
            best_value = i[2]["Avg"]
            best_pair = i[1]
        end
    end
    res = parse.(Float64,split(best_pair,"/"))
    best_temp = trunc(Int,res[1])*1.0
    best_alpha = res[2]
    test_set_gaps = Float64[]
    for inst in instances
        cost = solveInstance(string(inst,test_set,".","txt"),time_limit,best_temp,best_alpha,1,0)
        obj = instances_dict[inst][test_set]["Vehicles"]*instances_dict[inst][test_set]["Distance"]
        gap = (cost-obj)/obj
        push!(test_set_gaps,gap)
    end
    mean_test_gaps = mean(test_set_gaps)
    return best_temp,best_alpha,best_value,mean_test_gaps
end
