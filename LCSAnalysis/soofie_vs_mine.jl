using CSV
using DataFrames
using Plots
using Glob
using Dates
using Plots

include("data_handling_functions.jl")

mypath = "/home/lawson/Data/LCS_data/Twin_Creeks_2022/"

data_paths = Glob.glob("2*.CSV",mypath)

data = CSV.read(data_paths[1],DataFrame)

for dp in data_paths[2:end]
    append!(data,CSV.read(dp,DataFrame);cols = :intersect)
end

dfmt = "yyyy-mm-dd HH:MM:SS"


clean_lcs_data!(data)
add_literature_corrections!(data)

data_pre = data[data.datetime .< Date(2022,09),:]
data_post = data[data.datetime .> Date(2022,09),:]

#--
#calculate Allan Deviation
#clean further
data_good = data_pre[0.5 .< data_pre."Rs/Ro1" .< 1.75, :]
data_good = data_good[Date(2022,07,30) .< data_good.datetime .< Date(2022,08,01), : ]
τ3 = [Second(n) for n in 100:300:3600]
avgs3 = []
for window in τ3
    means = []
    for r in eachrow(data_good)
        println(window, " ", r.datetime)
        data_avg = data_good[r.datetime .< data_good.datetime .< r.datetime+ window, : ]
        avg = mean(data_avg."Rs/Ro1")
        push!(means,avg)
    end
    push!(avgs3,means)
    println(window)
end

expectedVal3 = []
for i in 1:length(τ3)-1
    dta = avgs3[i] - avgs3[i+1]
    dd = [!isequal(i,NaN) for i in dta]
    dta = dta[dd]
    avg = mean(dta)
    push!(expectedVal3,avg)
end

allanVar3 = 0.5*(expectedVal3.^2)

scatter(τ[1:end-1],allanVar,xaxis=:log,label="10 sec (10-1000)")
scatter!(τ2[1:end-1],allanVar2,label="1 sec (3-30)")
scatter!(τ3[1:end-1],allanVar3,label="300 sec (100-3600)",yaxis=:log)
plot!(title="Allan Deviation Plot, LCS 2 Days Test",xrot=-11,legend=:topleft)
png("allanVar_log")

soofie_path = "/home/lawson/Data/LCS_data/Twin_Creeks_2022/SOOFIE/SOOFIE_sametime.csv"

soofie_data = CSV.read(soofie_path,DataFrame)
soofie_2 = soofie_data[soofie_data.device .== "Twin Creeks-2", :]
dfmt2 = "uuu dd, yyyy @ HH:MM"
soofie_2.dt = [Dates.DateTime(d,dfmt2) for d in soofie_2.date]


soofie_2.mv2 = (5 ./soofie_2.methane_voltage .- 1) .* 5000
soofie_2.mv3 = 1 .- soofie_2.methane_voltage

scatter(data_pre.datetime,data_pre.V_rl1,
        msw=0,xrot=-11,
        ylims=[0,0.25],
        # marker_z = data.abs_hum
        )

scatter!(twinx(),soofie_2.dt,soofie_2.methane_voltage,markersize=2,c=:red)
png("test1")

data.dt=data.datetime .+ Dates.Minute(46)

combined = innerjoin(data,soofie_2,on=[:dt])
combined_secs = [(r - combined.dt[1]).value /1000 for r in combined.dt]
scatter(combined.V_rl2,combined.mv2,marker_z=combined_secs)
png("Corr")

using GLM

day1 = combined[combined.dt .< Dates.Date(2022,08,02),:]
day1 = day1[Dates.DateTime(2022,07,29,14).< day1.dt ,:]
scatter(day1.dt,day1.methane_voltage)
scatter!(day1.dt,day1.V_rl2./0.2,msw=0,markersize=3,ylims=[0.5,1.5])


day1.secs = [(d-day1.dt[1]).value / 1000 for d in day1.dt]

# day1.dt2 = day1.dt .+ Dates.Minute(46)

scatter(day1.dt,day1.methane_voltage,label="SOOFIE 'methane_voltagge",ylabel="Sensor Voltage (A.U)")
scatter!(day1.dt,day1.V_rl1*5,msw=0,markersize=3,label="ECCC 'TGS2611-C00")
scatter!(day1.dt,day1.V_rl2*5,msw=0,markersize=3,label="ECCC 'TGS2611-E00")
title!("Comparing Raw Data, SOOFIE & ECCC Sensors")
png("Test2")


fit = lm(@formula(methane_voltage~V_rl2),day1)

r2(fit)