using CSV
using Plots
using StatsPlots
using Glob
using DataFrames
using Dates
using GLM
using Printf

path_to_data = "/home/lawson/Data/LCS_data/SOOFIE/1min_data/"

data_paths = glob("*.csv",path_to_data)


data = CSV.read(data_paths[1],DataFrame)

rename!(data,[strip(n) for n in names(data)])
[data[!,col] = convert(Vector{Any},data[!,col]) for col in names(data)]

# for n in names(data)
#     data[!,n] = convert(Vector{Any},data.$"n")
# end

for path in data_paths[2:end]
    df  = CSV.read(path, DataFrame)
    append!(data,df)
end

data.dt = [DateTime(t,"u d, yyyy "*'@'*" HH:MM") for t in data.date]

[println(n) for n in names(data)]



# scatter(TC1.dt,TC1.methane)


# png("test_plot")

function list_devices(data)
    devs = []
    for d in data.device
        if ! in(d,devs)
            push!(devs,d)
        end
    end
    for d in devs
        println(d)
    end
    return devs
end

devs = list_devices(data)

function csv_by_device(data, path_to_data)
    devs = list_devices(data)
    dfs = []
    for dev in devs
        df = data[data.device .== dev,:]
        CSV.write(path_to_data*"$(dev).csv",df)
    end
end

csv_by_device(data,path_to_data*"split_data/")

function dfs_dict_by_device(data)
    devs = list_devices(data)
    dfs = []
    for dev in devs
        df = data[data.device .== dev,:]
        push!(dfs,df)
    end
    dic = Dict([(devs[i], dfs[i]) for i in 1:length(devs)])
    return dic 
end

dfs = dfs_dict_by_device(data)


Test1 = dfs["Test-1"]
Test2 = dfs["Test-2"]
Test3 = dfs["Test-3"]
Test4 = dfs["Test-4"]
Test5 = dfs["Test-5"]
TC1 = dfs["Twin Creeks-1"]
TC2 = dfs["Twin Creeks-2"]
TC4 = dfs["Twin Creeks-4"]
TC5 = dfs["Twin Creeks-5"]

TCL1 = rename!(dfs["Twin_Creeks_Landfill-1"],[n*"_tcl" for n in names(data)])
TCL2 = rename!(dfs["Twin_Creeks_Landfill-2"],[n*"_tcl" for n in names(data)])
TCL3 = rename!(dfs["Twin_Creeks_Landfill-3"],[n*"_tcl" for n in names(data)])
TCL4 = rename!(dfs["Twin_Creeks_Landfill-4"],[n*"_tcl" for n in names(data)])
TCL5 = rename!(dfs["Twin_Creeks_Landfill-5"],[n*"_tcl" for n in names(data)])
TCL6 = rename!(dfs["Twin_Creeks_Landfill-6"],[n*"_tcl" for n in names(data)])
TCL7 = rename!(dfs["Twin_Creeks_Landfill-7"],[n*"_tcl" for n in names(data)])
TCL8 = rename!(dfs["Twin_Creeks_Landfill-8"],[n*"_tcl" for n in names(data)])
TCL9 = rename!(dfs["Twin_Creeks_Landfill-9"],[n*"_tcl" for n in names(data)])
TCL10 = rename!(dfs["Twin_Creeks_Landfill-10"],[n*"_tcl" for n in names(data)])
TCL11 = rename!(dfs["Twin_Creeks_Landfill-11"],[n*"_tcl" for n in names(data)])
TCL12 = rename!(dfs["Twin_Creeks_Landfill-12"],[n*"_tcl" for n in names(data)])

path_to_plots = pwd()*"/Plots"

if ! isdir(path_to_plots)
    mkdir(path_to_plots)
end

function plot_data(dfs,devs,dts,test_end_dt,path_to_plots)
    min_dt = minimum(dts)
    max_dt,MAX_DT = maximum(dts),maximum(dts)
    for d in devs
        max_dt = MAX_DT
        df = dfs[d]
        if contains(d,"Test")
            max_dt = test_end_dt
        end
        if contains(d,"Landfill")
            p1 = scatter(df.dt_tcl,df.methane_tcl,markersize=2,msw=0,xrange=(min_dt,max_dt),
                        title = d*" CH₄ vs. Time", ylabel = "SOOFIE CH₄ (ppm)",
                        xrot=-10)
        else            
            p1 = scatter(df.dt,df.methane,markersize=2,msw=0,xrange=(min_dt,max_dt),
                        title = d*" CH₄ vs. Time", ylabel = "SOOFIE CH₄ (ppm)",
                        xrot=-10)
        end
        png(p1, path_to_plots*"/"*d*"methane_vs_t.png")

    end
end

function max_dt_Test(dfs,devs)
    maxdt = DateTime(0)
    for d in devs
        if contains(d,"Test")
            df = dfs[d]
            if maximum(df.dt) > maxdt
                maxdt = maximum(df.dt)
            end
        end
    end
    return maxdt
end

plot_data(dfs,devs,data.dt,max_dt_Test(dfs,devs),path_to_plots)


#Data trimming by inspection


TC1 = TC1[TC1.methane .> 0,:]
# TC2 = TC2[TC2.dt .< DateTime(2022,09,25),:]

#side by side pairs
#TC1 TCL6
pair1 = innerjoin(TC1,TCL6, on=:dt => :dt_tcl )
#TC2 TCL8
pair2 = innerjoin(TC2,TCL8, on=:dt => :dt_tcl )
#TC3 TCL11
# pair3 = innerjoin(TC3,TCL11, on=:dt => :dt_tcl )
#TC5 TCL4
pair5 = innerjoin(TC5,TCL4, on=:dt => :dt_tcl )
#TC4 TCL3
pair4 = innerjoin(TC4,TCL3, on=:dt => :dt_tcl )

pairss = [pair1,pair2,pair4,pair5]

function plot_pairs(pairss,path_to_plots)
    is = [1,2,4,5]
    plts = []
    for i in 1:length(is)
        # println(p)
        # println(i)
        p1 = scatter(pairss[i].dt,pairss[i].methane, markersize=2,msw=0,
        # xrange=(min_dt,max_dt),
        title = "Pair $(is[i])\nCH₄ vs. Time", ylabel = "SOOFIE CH₄ (ppm)", label = "CRD SOOFIE",
        xrot=-10)
        scatter!(p1,pairss[i].dt,pairss[i].methane_tcl, markersize=1.5,msw=0,α=0.2, label = "EPB SOOFIE")
        png(p1, path_to_plots*"/pair"*string(is[i])*"_methane_vs_t.png")
        push!(plts,p1)
    end
    lay = @layout[2,2]
    println(plts)
    plot(plts[1],plts[2],plts[3],plts[4],layout=lay,size=(1000,1000))
    png(path_to_plots*"/all_together")
end

plot_pairs(pairss,path_to_plots)

function floatify!(pairss)
    for p in pairss
        p.methane = Float64.(p.methane)
        p.methane_tcl = Float64.(p.methane_tcl)
    end
end

floatify!(pairss)

function linear_pairs(pairss)
    s = [1,2,4,5]
    plts = []
    for i in 1:length(is)
        # println(p)
        # println(i)
        fit = lm(@formula(methane_tcl ~ methane), pairss[i])
        
        label = @sprintf("CRD vs. EPB SOOFIE\nR² = %.2f, slope = %.2f",r2(fit), coef(fit)[2] )
        
        p1 = scatter(pairss[i].methane,pairss[i].methane_tcl, markersize=2,msw=0,
        # xrange=(min_dt,max_dt),
        title = "Pair $(is[i])\nCRD SOOFIE vs. EPB SOOFIE", ylabel = "CH₄ (ppm)",
         xlabel = "CH₄ (ppm)",label = label,
        # xrot=-10
        )
        pred = predict(fit,pairss[i],interval=:prediction)
        println(first(pred))
        plot!(p1,pairss[i].methane,pred.prediction,c=:black)
        png(p1, path_to_plots*"/pair"*string(is[i])*"_methane_vs_methane.png")
        push!(plts,p1)
    end
    lay = @layout[2,2]
    println(plts)
    plot(plts[1],plts[2],plts[3],plts[4],layout=lay,size=(1000,1000))
    png(path_to_plots*"/all_slopes")
end

linear_pairs(pairss)

