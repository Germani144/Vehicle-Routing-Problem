using Random
# Best known solution from project description file
include("bestKnown.jl")
# Algorithm tuning file
include("myTuner.jl")
# Supporting functions like printing and plotting
include("supportFunc.jl")

mutable struct Car
    load::Float64
    route::Array{Int64,1}
    car_id::Int64
end

mutable struct Client
    demand::Float64
    stock::Float64
    locale::Int64
    t_init::Float64
    t_end::Float64
    serv_time::Float64
    delivery_car::Int64
    delivery_time::Float64
end

# Checks if any contraints are being broken
function checkSolution(D::Array{Float64},clients::Array{Client},fleet::Array{Car},dim::Int64)
    b = zeros(Float64,dim,1)
    for car in fleet
        if length(car.route) > 2
            for i in 1:(length(car.route)-1)
                client_a = clients[car.route[i]]
                client_b = clients[car.route[i+1]]
                b[client_a.locale] = 1
                b[client_b.locale] = 1
                if client_a.delivery_time + D[client_a.locale,client_b.locale] > client_b.t_end
                    return 1
                end
            end
        end
        if car.load < 0 || car.route[end] != 1
            return 1
        end
    end
    for client in b
        if client == 0
            return 1
        end
    end
    return 0
end

# Same as check solution, but specific to routes (important for optimization part to be faster)
function checkRoute(D::Array{Float64},clients::Array{Client},car::Car)
    if length(car.route) > 2
        for i in 1:(length(car.route)-1)
            client_a = clients[car.route[i]]
            client_b = clients[car.route[i+1]]
            if client_a.delivery_time + D[client_a.locale,client_b.locale] > client_b.t_end
                return 1
            end
        end
    end
    return 0
end

# Performs an insertion of a client in a route and delivers to it
function makeDelivery(client::Client,car::Car,i::Int64)
    insert!(car.route,i,client.locale)
    car.load -= client.demand
    client.stock = client.demand
    client.demand = 0
    client.delivery_car = car.car_id
end

# Checks if a client can be inserted in a specific spot in a new route
function checkInsertion(prev_client::Client,subs_client::Client,car::Car,client::Client,D::Array{Float64,2})
    # arrival condition at current client from possible previous client
    arriv_cond = prev_client.delivery_time + D[prev_client.locale,client.locale]
    # departure conditions from current client to possible subsequent client
    dept_cond1 = arriv_cond + D[client.locale,subs_client.locale] + client.serv_time
    dept_cond2 = client.t_init + D[client.locale,subs_client.locale] + client.serv_time
    # condition for when vehicle arrives within time window
    if client.t_init <= arriv_cond <= client.t_end && dept_cond1 <= subs_client.t_end
        return 1
    # condition for when vehicle arrives before time window
    elseif arriv_cond < client.t_init && dept_cond2 <= subs_client.t_end
        return 2
    end
    return 0
end

# Constructs a feasible solution which tries to use each car as much as possible
# from the beginning. Runs until all clients have had their demands met
function constructionHeuristic(clients::Array{Client},fleet::Array{Car},D::Array{Float64,2},total_demand::Float64)
    for car in fleet
        # Every car starts at the warehouse
        push!(car.route, 1)
        for client in clients
            # Skipping warehouse, only checking clients that still have a demand
            # and that the current car has enough cargo for it
            if client.demand > 0 && car.load >= client.demand
                if client.locale != 1
                    # if only warehouse in the route we may add the client already
                    if length(car.route) == 1
                        # making the drop
                        total_demand -= client.demand
                        makeDelivery(client,car,2)
                        # setting the delivery time for the client:
                        # if the car arrives btwn the delivery window
                        if client.t_init <= D[1,client.locale] <= client.t_end
                            client.delivery_time = D[1,client.locale] + client.serv_time
                        # if the car arrives before the delivery window
                        else
                            client.delivery_time = client.t_init + client.serv_time
                        end
                        # adding the warehouse as the last stop
                        push!(car.route,1)
                    # if route from car already has one client
                    else
                        i::Int64 = 2
                        # keep trying to insert the vehicle at any possible point of the route
                        while i < (length(car.route)) && 0 < client.demand <= car.load
                            flag = checkInsertion(clients[car.route[i-1]],clients[car.route[i]],car,client,D)
                            if flag > 0
                                client2 = deepcopy(client)
                                car2 = deepcopy(car)
                                clients2 = deepcopy(clients)
                                makeDelivery(client2,car2,i)
                                updateDelTimes(car2,D,i,clients2)
                                if flag == 1
                                    if checkRoute(D,clients2,car2) == 0
                                        makeDelivery(client,car,i)
                                        updateDelTimes(car,D,i,clients)
                                        client.delivery_time = clients[car.route[i-1]].delivery_time + D[car.route[i-1],client.locale] + client.serv_time
                                        total_demand -= client.demand
                                    end
                                else
                                    if checkRoute(D,clients2,car2) == 0
                                        makeDelivery(client,car,i)
                                        updateDelTimes(car,D,i,clients)
                                        client.delivery_time = client.t_init + client.serv_time
                                        total_demand -= client.demand
                                    end
                                end
                            end
                            i += 1
                        end
                    end
                end
            end
        end
    end
end

# Returns the result of a solution, i.e., the number of vehicles used
# and the total distance traveled
function getResult(fleet::Array{Car},clients::Array{Client},D::Array{Float64,2})
    DISTANCE::Float64 = 0
    CAR_COUNT::Int64  = 0
    for car in fleet
        if length(car.route) > 2
            for i in 1:(length(car.route)-1)
                DISTANCE += D[car.route[i],car.route[i+1]]
            end
            CAR_COUNT += 1
        end
    end
    return DISTANCE, CAR_COUNT
end

# Returns the cost of a solution as being the number of cars times the distance
function solutionCost(fleet::Array{Car},clients::Array{Client},D::Array{Float64,2})
    dist, cars = getResult(fleet,clients,D)
    return dist*cars
end

# Updates the delivery time of all the cars that are subsequent of a car newly added to a route
function updateDelTimes(car::Car,D::Array{Float64,2},spot::Int64,clients::Array{Client})
    for i in spot:(length(car.route)-1)
        client_a = clients[car.route[i-1]]
        client_b = clients[car.route[i]]
        if client_a.delivery_time + D[client_a.locale,client_b.locale] < client_b.t_init
            client_b.delivery_time = client_b.t_init + client_b.serv_time
        elseif client_a.delivery_time + D[client_a.locale,client_b.locale] <= client_b.t_end
            client_b.delivery_time = client_a.delivery_time + D[client_a.locale,client_b.locale] + client_b.serv_time
        else
            client_b.delivery_time = Inf
        end
    end
end

# Swap two clients between same or different routes, updating the delivery time when necessary
function makeSwap(old_car::Car,new_car::Car,old_spot::Int64,new_spot::Int64,clients::Array{Client},D::Array{Float64,2})
    clients[old_car.route[old_spot]].delivery_car = new_car.car_id
    old_car.load += clients[old_car.route[old_spot]].stock
    new_car.load -= clients[old_car.route[old_spot]].stock

    insert!(new_car.route, new_spot, old_car.route[old_spot])
    deleteat!(old_car.route, old_spot)

    if new_car == old_car
        if old_spot < new_spot
            updateDelTimes(new_car,D,old_spot,clients)
        else
            updateDelTimes(new_car,D,new_spot,clients)
        end
    else
        updateDelTimes(new_car,D,new_spot,clients)
        updateDelTimes(old_car,D,old_spot,clients)
    end
end

# Returns a neighborhood for the solution that can be both an intra-route relocation
# or an inter-route relocation
function neighOperator(D::Array{Float64,2},time_limit::Float64,fleet::Array{Car},
    clients::Array{Client},CAR_COUNT2::Array{Int64},DISTANCE2::Array{Float64},
    best_CarCount::Array{Int64},best_Distance::Array{Float64},T::Float64,alpha::Float64,dim::Int64)
    let
        startTime = time_ns()
        while round((time_ns()-startTime)/1e9,digits=3) <= time_limit
            non_empty_routes = Int64[]
            for car in fleet
                if length(car.route) > 2
                    push!(non_empty_routes,car.car_id)
                end
            end

            old_car = rand(non_empty_routes)
            new_car = rand(non_empty_routes)

            # Uncomment below if you wish to only allow INTER-ROUTE relocation (default allows both inter and intra)
            # obs: instance c2_2_4 does not obtain optimizations with only inter-route.
            #while new_car == old_car
            #    new_car = rand(non_empty_routes)
            #end

            old_spot = rand(2:length(fleet[old_car].route)-1)
            new_spot = rand(2:length(fleet[new_car].route)-1)
            prob = rand()

            if (old_car != new_car && fleet[new_car].load >= clients[fleet[old_car].route[old_spot]].stock) || (old_car == new_car && old_spot != new_spot)
                SA(fleet,old_car,new_car,old_spot,new_spot,clients,D,dim,CAR_COUNT2,DISTANCE2,best_CarCount,best_Distance,T,prob)
            end
            T *= alpha
        end
    end
end

function SA(fleet::Array{Car},old_car::Int64,new_car::Int64,old_spot::Int64,new_spot::Int64,clients::Array{Client},D::Array{Float64,2},dim::Int64,
        CAR_COUNT2::Array{Int64},DISTANCE2::Array{Float64},best_CarCount::Array{Int64},best_Distance::Array{Float64},T::Float64,prob::Float64)
    fleet2 = deepcopy(fleet)
    clients2 = deepcopy(clients)
    makeSwap(fleet2[old_car],fleet2[new_car],old_spot,new_spot,clients2,D)
    if checkSolution(D,clients2,fleet2,dim) == 0
        dist,cc = getResult(fleet2,clients2,D)
        push!(CAR_COUNT2,cc)
        push!(DISTANCE2,dist)
        s_prime = solutionCost(fleet2,clients2,D)
        s0 = solutionCost(fleet,clients,D)
        delta = s_prime - s0
        p_t = exp(-(delta/T))
        if (delta < 0) || (prob <= p_t)
            makeSwap(fleet[old_car],fleet[new_car],old_spot,new_spot,clients,D)
            push!(best_CarCount,cc)
            push!(best_Distance,dist)
        end
    end
end

function solveInstance(file_name::String,time_limit::Float64,T::Float64,alpha::Float64,tune::Int64,graph::Int64)
    data = readInstance(file_name)
    num_cars = data[2]
    capacity = data[3]
    dim = data[4]
    coord = data[5]
    demand = data[6]
    time_window = data[7]
    service_time = data[8]
    cust_id = data[9]
    total_demand = sum(demand)

    # Creating array of cars (fleet) and clients
    fleet = Vector{Car}(undef,num_cars)
    clients = Vector{Client}(undef,dim)

    # Initializing each car in the fleet
    for i in 1:num_cars
        fleet[i] = Car(capacity,[],i)
    end

    # Initializing clients
    for i in 1:dim
        clients[i] = Client(demand[i],0,cust_id[i],time_window[i,1],
        time_window[i,2],service_time[i],0,0.0)
    end

    # Getting immutable distances between every point in the problem
    D = distanceMatrix(coord,dim)
    # Constructing of a feasible solution
    constructionHeuristic(clients,fleet,D,total_demand)
    # Getting the cost of the initial non-optimized solution
    DISTANCE, CAR_COUNT = getResult(fleet,clients,D)
    # Checking if no constraints are broken for the initial solution
    flagSol = checkSolution(D,clients,fleet,dim)
    if flagSol == 1
        println("Problem with solution ",file_name)
    end

    CAR_COUNT2::Array{Int64} = []
    DISTANCE2::Array{Float64} = []
    best_CarCount::Array{Int64} = []
    best_Distance::Array{Float64} = []
    push!(CAR_COUNT2,CAR_COUNT)
    push!(DISTANCE2,DISTANCE)
    push!(best_CarCount,CAR_COUNT)
    push!(best_Distance,DISTANCE)

    dig = parse(Int64,file_name[6:findfirst(".", file_name)[end]-1])
    inst = file_name[1:5]
    obj_car = instances_dict[inst][dig]["Vehicles"]
    obj_dis = instances_dict[inst][dig]["Distance"]
    obj = obj_car*obj_dis

    neighOperator(D,time_limit,fleet,clients,CAR_COUNT2,DISTANCE2,best_CarCount,best_Distance,T,alpha,dim)

    # Checking if no constraints are broken for the optimized solution
    flagSol = checkSolution(D,clients,fleet,dim)
    if flagSol == 1
        println("Problem with solution ",file_name)
    end

    cost = solutionCost(fleet,clients,D)
    gap = round((cost-obj)/obj,digits=1)


    if tune != 1
        printResults(file_name,CAR_COUNT,best_CarCount[end],DISTANCE,best_Distance[end],length(DISTANCE2),gap)
    else
        return cost
    end

    if graph == 1
        plotConvg(DISTANCE2,CAR_COUNT2,file_name)
    end
end

function main()
    startTime = time_ns()
    # Minimum time to ensure 100 iterations for all instances is ~10s (with tuned parameters in my machine)
    # Set it to zero if only construction heuristic results are wanted
    # Best results reported were obtained with 600s per instance
    time_limit::Float64 = 600
    Random.seed!(1234)
    # T and alpha obtained from parameter tuning (30s of time limit = 5h07min of total runtime)
    T::Float64 = 100.0
    alpha::Float64 = 0.98
    prefix = ["c","r"]
    tunetime::Float64 = 0.0
    # Set variable "tune" to 1 in order to tune the parameters T and alpha
    tune::Int64 = 0
    # Set runAll to 1 in order to run all the files, and 0 to run a specific (specify below)
    runAll::Int64 = 0

    if tune == 1
        println("\n")
        println("Initial temperature = ",T)
        println("Initial alpha = ",alpha)

        T,alpha,train_gap,test_gap = tuneParams()

        println("=======================")
        println("Tuned temperature = ",T)
        println("Tuned alpha = ",alpha)
        println("Avg. train set gap = ",round(train_gap,digits=2))
        println("Avg. test set gap = ",round(test_gap,digits=2))
        tunetime = round((time_ns()-startTime)/1e9,digits=3)
        println("Tuning run-time = ",floor(tunetime/3600,digits=0),"h ",floor((tunetime%3600)/60,digits=0),"m ",round((tunetime%3600)%60,digits=2),"s")
        println("\n")
    end

    if runAll == 1
        println("Theoretical algorithm runtime = ",floor((time_limit*40+300)/3600,digits=0),"h ",floor(((time_limit*40+300)%3600)/60,digits=0),"m ",((time_limit*40+300)%3600)%60,"s")
        printHeader()

        for pre in prefix
            for i in 1:2, j in 1:10
                solveInstance(string(pre,i,"_","2","_",j,".","txt"),time_limit,T,alpha,0,0)
            end
        end

        rrtime = round((time_ns()-startTime)/1e9,digits=3)-tunetime
        println("\n")
        println("Real algorithm runtime = ",floor(rrtime/3600,digits=0),"h ",floor((rrtime%3600)/60,digits=0),"m ",round((rrtime%3600)%60,digits=2),"s")
    else
        printHeader()
        solveInstance("c1_2_2.txt",time_limit,T,alpha,0,1)
    end
end

main()
