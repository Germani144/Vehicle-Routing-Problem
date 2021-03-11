using Plots

# Reads one file at a time and keeps the data
function readInstance(filename::String)
    file = open(filename)

    #Read the name of the file
    name = split(readline(file))[1]
    readline(file);readline(file);readline(file)

    #Read the number of vehicles and capacity of each one
    data1 = parse.(Int32,split(readline(file)))
    cars = data1[1]
    capacity = data1[2]
    readline(file);readline(file);readline(file);readline(file)

    #Creating appropriate matrices to hold the data
    dim::Int64 = 201
    cust_id = zeros(Float64,dim,1)
    coord = zeros(Float64,dim,2)
    demand = zeros(Float64,dim,1)
    time_window = zeros(Float64,dim,2)
    service_time = zeros(Float64,dim,1)
    for i in 1:dim
        data2 = parse.(Float64,split(readline(file)))
        cust_id[i] = data2[1]+1
        coord[i,:] = data2[2:3]
        demand[i] = data2[4]
        time_window[i,:] = data2[5:6]
        service_time[i] = data2[7]
    end
    close(file)
    return name,cars,capacity,dim,coord,demand,time_window,service_time,cust_id
end

# Gets the immutable distance between each point and every other point
# in the problem set
function distanceMatrix(coord::Array{Float64,2},dim::Int64)
    dist = zeros(Float64,dim,dim)
    for i in 1:dim
       for j in 1:dim
            if i!=j
                dist[i,j]=round(sqrt((coord[i,1]-coord[j,1])^2+(coord[i,2]-coord[j,2])^2),digits=2)
            else
                dist[i,j]=Inf
            end
        end
    end
    return dist
end

# Prints a header for the solutions
function printHeader()
    println("\n")
    println(" ","Instance ID"," | ","Vehicles", " | ","Vehi_Opt"," |  ","Gap","  | ","Iter."," | ","Distance"," => ","Dist_Opt")
    println("--------------------------------------------------------------------------")
end

# Prints each solution result (one per file)
function printResults(file_name::String,CAR_COUNT::Int64,CAR_COUNT2::Int64,DISTANCE::Float64,DISTANCE2::Float64,iter::Int64,gap::Float64)
    if CAR_COUNT > 9
        if CAR_COUNT2 < 10
            if file_name[6:7] == "10"
                println("   ",file_name[1:7], "   |    ", CAR_COUNT, "    |    " , CAR_COUNT2,
                "    |  ",gap,"  |  ",
                iter ,"  | ",round(DISTANCE, digits=3)," => ",round(DISTANCE2, digits=3))
            else
                println("   ",file_name[1:6], "    |    ", CAR_COUNT, "    |     " , CAR_COUNT2,
                "    |  ",gap,"  |  ",
                iter ,"  | ",round(DISTANCE, digits=3)," => ",round(DISTANCE2, digits=3))
            end
        else
            if file_name[6:7] == "10"
                println("   ",file_name[1:7], "   |    ", CAR_COUNT, "    |    " , CAR_COUNT2,
                "    |  ",gap,"  |  ",
                iter ,"  | ",round(DISTANCE, digits=3)," => ",round(DISTANCE2, digits=3))
            else
                println("   ",file_name[1:6], "    |    ", CAR_COUNT, "    |    " , CAR_COUNT2,
                "    |  ",gap,"  |  ",
                iter ,"  | ",round(DISTANCE, digits=3)," => ",round(DISTANCE2, digits=3))
            end
        end
    else
        if file_name[6:7] == "10"
            println("   ",file_name[1:7], "   |     ", CAR_COUNT, "    |     " , CAR_COUNT2,
            "    |  ",gap,"  |  ",
             iter ,"  | ",round(DISTANCE, digits=3)," => ",round(DISTANCE2, digits=3))
        else
            println("   ",file_name[1:6], "    |     ", CAR_COUNT, "    |     " , CAR_COUNT2,
            "    |  ",gap,"  |  ",
            iter ,"  | ",round(DISTANCE, digits=3)," => ",round(DISTANCE2, digits=3))
        end
    end
end

function plotConvg(DISTANCE2,CAR_COUNT2,file_name)
    x = 1:length(DISTANCE2)
    tp = DISTANCE2.*CAR_COUNT2
    display(plot(x, tp, title = "Cost convergence",label=file_name,lw = 2))
    ylabel!("Cost (cars x distance)")
    xlabel!("Iteration")
end
