using CSV
using GLM
using DataFrames
using Interpolations
using Statistics
using Plots
using Dates

#include useful functions
include("data_handling_functions.jl")


#2021 Summer Mobile Data
#path to lcs data
lcs_paths = ["/home/lawson/Data/ArduinoData/2021MobileData/test_data_mobile20210715.csv"]
append!(lcs_paths, ["/home/lawson/Data/ArduinoData/2021MobileData/test_data_mobile20210804.csv"])
append!(lcs_paths, ["/home/lawson/Data/ArduinoData/2021MobileData/test_data_mobile20210806.csv"])
# lcs_path = "/home/lawson/Data/ArduinoData/2021MobileData/test_data_mobile20210806.csv"
# lcs_path = "/home/lawson/Data/ArduinoData/2021MobileData/test_data_mobile20210831.csv"
append!(lcs_paths, ["/home/lawson/Data/ArduinoData/2021MobileData/test_data_mobile20210831.csv"])
# append!(lcs_paths, ["/home/lawson/Data/ArduinoData/2021MobileData/test_data_mobile20210831.csv"])

#Sync_data paths
sync_paths = ["/home/lawson/Data/InSituMethane/BikeData/2021/sync_data_2021-07-15.csv"]
append!(sync_paths, ["/home/lawson/Data/InSituMethane/BikeData/2021/sync_data_2021-08-04.csv"])
append!(sync_paths, ["/home/lawson/Data/InSituMethane/BikeData/2021/sync_data_2021-08-06.csv"])
append!(sync_paths, ["/home/lawson/Data/InSituMethane/BikeData/2021/sync_data_2021-08-31.csv"])
# append!(sync_paths, ["/home/lawson/Data/InSituMethane/BikeData/2021/sync_data_2021-09-14.csv"])


#2021 PetroliaData
# lcs_paths = ["/home/lawson/Data/ArduinoData/PetroliaData/tgs2600_data/lcs_data_mobile_2021-915.csv"]
append!(lcs_paths,["/home/lawson/Data/ArduinoData/PetroliaData/tgs2600_data/lcs_data_mobile_2021-915.csv"])
# append!(lcs_paths, ["/home/lawson/Data/ArduinoData/PetroliaData/tgs2600_data/lcs_data_mobile_2021-916.csv"])
append!(lcs_paths, ["/home/lawson/Data/ArduinoData/PetroliaData/tgs2600_data/lcs_data_mobile_2021-918.csv"])
append!(lcs_paths, ["/home/lawson/Data/ArduinoData/PetroliaData/tgs2600_data/lcs_data_mobile_2021-919.csv"])
append!(lcs_paths, ["/home/lawson/Data/ArduinoData/PetroliaData/tgs2600_data/lcs_data_mobile_2021-920.csv"])
#
# sync_paths = ["/home/lawson/Data/ArduinoData/PetroliaData/bike_data/sync_data_2021-09-15.csv"]
append!(sync_paths, ["/home/lawson/Data/ArduinoData/PetroliaData/bike_data/sync_data_2021-09-15.csv"])
append!(sync_paths, ["/home/lawson/Data/ArduinoData/PetroliaData/bike_data/sync_data_2021-09-18.csv"])
append!(sync_paths, ["/home/lawson/Data/ArduinoData/PetroliaData/bike_data/sync_data_2021-09-19.csv"])
append!(sync_paths, ["/home/lawson/Data/ArduinoData/PetroliaData/bike_data/sync_data_2021-09-20.csv"])



# plot1 = plot()
# plot2 = plot()

#TODO regress all data at once
#TODO include ch4 data
#TODO include convolved CH4 data

lcs_data = DataFrame()
for lcs_path in lcs_paths
    #process lcs_data, assumes static resistor value of 510 ohm
    append!(lcs_data,process_lcs_data(CSV.read(lcs_path,DataFrame)))
end

lcs_data= lcs_data[lcs_data.Rs_1k .< 500,:]
lcs_data= lcs_data[lcs_data.dt .< Dates.DateTime(2021,09,20,10,21),:]

# linearly_interpolate_columns(lcs_data)

sync_data = process_sync_data(CSV.read(sync_paths[1],DataFrame))
allowmissing!(sync_data)
for sync_path in sync_paths[2:end]
    println(sync_path)
    append!(sync_data,process_sync_data(CSV.read(sync_path,DataFrame)))
    # sleep(.1)
end

#TODO combine data using interpolation...
combined_data = innerjoin(lcs_data,sync_data,on=Pair(:dt,:dt1))

#Interpolate onto one second intervals
#interpolates all columns with Float64 type
lcs_data_interp = linearly_interpolate_columns(lcs_data)


#shift the humidity (create shifted humidity datacol)
#---------HUMIDITY SHIFTING-----------------------------------------------------

lcs_data_interp.index = [i for (i,r) in enumerate(eachrow(lcs_data_interp))]
combined_data.index =  [i for (i,r) in enumerate(eachrow(combined_data))]
#shift things by XX seconds..
#shift all data values backward by XX points, except for the time,
#ORR shift the time values forward by XX points/seconds

#initiate empty dataframe for shifted variables
shifted_data = DataFrame()

#determined  appropriate shift using lcs_pulse_analysis.jl
shift = 290 #number of seconds to shift gas data relative to other data
shift=97
# shifted_data = lcs_data_interp[lcs_data_interp.index .> shift, :]
shifted_data = combined_data[combined_data.index .> shift, :]


shifted_data.index = [i for (i,r) in enumerate(eachrow(shifted_data))]

#Add shifted humidity to the interpolated dataframe?
# lcs_data_interp.abs_hum_shifted  = zeros(length(eachrow(lcs_data_interp)))
combined_data.abs_hum_shifted = zeros(length(eachrow(combined_data)))



for i in 1:length(shifted_data.index)
    combined_data.abs_hum_shifted[i] = shifted_data.abs_hum[i]
end


#
# for i in 1:length(shifted_data.index)
#     lcs_data_interp.abs_hum_shifted[i] = shifted_data.abs_hum[i]
# end
# lcs_data_interp = lcs_data_interp[lcs_data_interp.abs_hum_shifted .> 5,:]
# lcs_data_interp = lcs_data_interp[lcs_data_interp.Rs_2 .> 17500,:]

#interpolate shifted humidity back to native resolution?

# for (i,col) in enumerate(eachcol(lcs_data_interp))
#          interp_linear = LinearInterpolation(secs, col)
#          out_frame[!,colnames[i]] = [interp_linear(n) for n in out_frame.sec]
#  end

# interp_linear = LinearInterpolation(lcs_data_interp.sec,lcs_data_interp.abs_hum_shifted)
# lcs_data[!,"abs_hum_shifted"] = [interp_linear(n) for n in lcs_data.sec]

# lcs_data = lcs_data[lcs_data.Rs_1k .< 85,:]
#TODO Make added variable plots
# lcs_data = lcs_data[lcs_data.abs_hum_shifted .> 5,:]

combined_data = combined_data[combined_data.abs_hum .> 5, :]
combined_data = combined_data[combined_data.ch4d_avg .< 3, :]


plot1 = plot() #plot of the Shifted LCS Abs. Hum vs TGS2600 (Rs_1k) (kΩ)
scatter!(plot1,combined_data.Rs_1k,combined_data.abs_hum,
            legend=:bottomleft,
            # marker_z = combined_data.ch4d_avg,
            # clims=(minimum(combined_data.ch4d_avg), 3),
            # label="$date",
            label=false,
            msw=0,
            xlabel="TGS2600 Resistance (kΩ)",
            ylabel = "BME280 Absolute Humidity (g/kg)",
            leftmargin = 2Plots.mm)

#linear regression

#example from
# https://www.r-bloggers.com/2021/03/partial-regression-plots-in-julia-python-and-r/
# sat = CSV.File("sat.csv") |> DataFrame

# expend_regression = lm(@formula(expend ~ ratio + salary + takers), sat)
# abs_hum_regression = lm(@formula(Rs_1k ~ abs_hum_shifted + tempp_bme + pres_bme ), combined_data)
# abs_hum_regression = lm(@formula(Rs_1k ~ abs_hum_shifted), combined_data)
abs_hum2_regression = lm(@formula(Rs_1k ~ abs_hum^2 + abs_hum), combined_data)
# abs_hum3_regression = lm(@formula(Rs_1k ~ abs_hum_shifted^2 + abs_hum_shifted + abs_hum ), combined_data)


# total_regression = lm(@formula(total ~ ratio + salary + takers), sat)
# temp_regression = lm(@formula(Rs_1k ~ tempp_bme), lcs_data)
# relhum_regression = lm(@formula(Rs_1k ~ hum_bme), lcs_data)

# expend_residuals = sat["expend"] - predict(expend_regression, sat)
# total_residuals = sat["total"] - predict(total_regression, sat)
# residual_df = DataFrame(ExpendResiduals=expend_residuals, TotalResiduals=total_residuals)

combined_data.abs_hum2_residuals = combined_data.Rs_1k - predict(abs_hum2_regression, combined_data)
# combined_data.abs_hum_residuals = combined_data.Rs_1k - predict(abs_hum_regression, combined_data)
# abs_hum3_residuals = combined_data.Rs_1k - predict(abs_hum3_regression, combined_data)
temp_regression = lm(@formula(abs_hum2_residuals ~ tempp_bme^2 + tempp_bme), combined_data)
combined_data.temp_residuals = combined_data.abs_hum2_residuals - predict(temp_regression, combined_data)
pres_regression = lm(@formula(temp_residuals ~ pres_bme^2 + pres_bme), combined_data)
combined_data.pres_residuals = combined_data.temp_residuals - predict(pres_regression, combined_data)

ch4_regression = lm(@formula(Float64(ch4d_avg) ~  temp_residuals^2 + temp_residuals), combined_data)


# temp_residuals = lcs_data.Rs_1k - predict(temp_regression, lcs_data)
# relhum_residuals = lcs_data.Rs_1k - predict(relhum_regression, lcs_data)
combined_data.ch4_preds = predict(ch4_regression, combined_data)

plot2 = plot()
scatter!(plot2,combined_data.Rs_1k,combined_data.abs_hum2_residuals,
            marker_z=combined_data.tempp_bme,
            msw=0,
            ylabel = "Abs. Hum. residuals",
            # xlabel = "Rel. Hum. residuals",
            xlabel = "TGS2600 Resistance (kΩ)",
            # ylabel = "Temp. Residuals",
            # label="$date",
            label=false,
            ma=.5,
            legend=:bottomright)

plot3 = plot()
scatter!(plot3,combined_data.Rs_1k,combined_data.temp_residuals,
            marker_z=combined_data.pres_bme,
            msw=0,
            # ylabel = "Abs. Hum. residuals",
            # xlabel = "Rel. Hum. residuals",
            xlabel = "TGS2600 Resistance (kΩ)",
            ylabel = "Temp. Residuals",
            # label="$date",
            label=false,
            ma=.5,
            legend=:bottomright)

plot4 = plot()
scatter!(plot4,combined_data.Rs_1k,combined_data.pres_residuals,
            marker_z=combined_data.ch4d_avg,
            msw=0,
            # ylabel = "Abs. Hum. residuals",
            # xlabel = "Rel. Hum. residuals",
            xlabel = "TGS2600 Resistance (kΩ)",
            ylabel = "Pres. Residuals",
            # label="$date",
            label=false,
            ma=.5,
            legend=:bottomright)

plot5 = plot()
plot!(plot5,[2,3],[2,3])
scatter!(plot5,combined_data.ch4d_avg,combined_data.ch4_preds,
            # marker_z=combined_data.ch4d_avg,
            msw=0,
            # ylabel = "Abs. Hum. residuals",
            # xlabel = "Rel. Hum. residuals",
            xlabel = "LGR 120s. Averaged CH₄",
            ylabel = "Predicted CH₄",
            # label="$date",
            label=false,
            ma=.5,
            legend=:bottomright)
#plot3, what I think she wants...
# plot3 = plot()

combined_data.sec = [(combined_data.dt[n]-combined_data.dt[1]).value/1000
                                for n in 1:length(eachrow(combined_data))]
# end



total_regression = lm(@formula(Float64(ch4d_avg) ~  CH4_raw+CH4_raw2+abs_hum_shifted), combined_data)

#Added variable time..

total_regression2 = lm(@formula( ch4d_avg ~  abs_hum^2 + abs_hum
                                            +tempp_bme+pres_bme + Rs_1k), combined_data)

#add them together because rs goes down when ch4 goes up...
combined_data.signal = combined_data.ch4d_avg+combined_data.Rs_1k

#abs_hum ^2 residuals

avr1 = lm(@formula(signal ~  abs_hum^2),combined_data)
combined_data.abs2_res = combined_data.signal - predict(avr1,combined_data)
avr2 = lm(@formula(signal ~  abs_hum ),combined_data)
combined_data.abs_res = combined_data.signal -predict(avr2,combined_data)
avr3 = lm(@formula(signal ~  tempp_bme),combined_data)
combined_data.temp_res = combined_data.signal - predict(avr3,combined_data)
avr4 = lm(@formula(signal ~  pres_bme ),combined_data)
combined_data.pres_res = combined_data.signal - predict(avr4,combined_data)
avr5 = lm(@formula(signal ~  abs_hum^2 + abs_hum ),combined_data)
combined_data.avr5_res = combined_data.signal - predict(avr5,combined_data)

p1 = plot()
scatter!(p1,
        # predict(avr1,combined_data),
        # combined_data.abs2_res,
        combined_data.abs_hum.^2,
        combined_data.signal.- mean(combined_data.signal),
                msw=0,marker_z=combined_data.ch4d_avg,
                ylabel="Signal ",
                xlabel ="Abs. Humidity²",
                label=false,cbartitle="CH₄ Avg")

p2=plot()

scatter!(p2,
         combined_data.abs_hum,
         combined_data.signal.- mean(combined_data.signal),
        # combined_data.signal
            msw=0,marker_z=combined_data.ch4d_avg,
            ylabel="LGR 120s Avg CH₄ + TGS26 kΩ",
            xlabel ="Abs. Humidity ",label=false)

p3=plot()
scatter!(p3,
        combined_data.tempp_bme,
        combined_data.signal.- mean(combined_data.signal),
            msw=0,marker_z=combined_data.ch4d_avg,
            ylabel="LGR 120s Avg CH₄ + TGS26 kΩ",
            xlabel ="Temp",label=false)

scatter!(p3,
        combined_data.tempp_bme,
        predict(avr3,combined_data).- mean(combined_data.signal),
            msw=0,marker_z=combined_data.ch4d_avg,
            ylabel="LGR 120s Avg CH₄ + TGS26 kΩ",
            xlabel ="Temp",label="Temp_Reg")

p4=plot()
scatter!(p4,combined_data.pres_bme,
            combined_data.signal.- mean(combined_data.signal),
            msw=0,marker_z=combined_data.ch4d_avg,
            ylabel="LGR 120s Avg CH₄ + TGS26 kΩ",
            xlabel ="Pressure",label=false)

vars = ["abs2_res","abs_res","temp_res","pres_res"]

# layout=  @layout [4,4]

# plot(plot1,plot2,plot3,plot4, layout=(2,2))
plts=Any[0,0,0,0]
for (i,col) in enumerate(vars)
    ps=Any[0,0,0,0]
    for (j,c) in enumerate(vars)
        plott=plot()
        scatter!(plott,combined_data[!,"$(c)"],combined_data[!,"$(col)"],msw=0,
                        marker_z=combined_data.ch4d_avg,
                        ylabel="($col)",
                        xlabel="($c)",label=false,cbar=false)
        ps[j] = plott
    end
    plts[i]=ps
end

pls_un = Any[]

plts_um =[item for sublist in plts for item in sublist]
l = @layout (4,4)

plot(plts_um[1],plts_um[2],plts_um[3],plts_um[4],plts_um[5],plts_um[6],
        plts_um[7],plts_um[8],plts_um[9],plts_um[10],plts_um[11],plts_um[12],
        plts_um[13],plts_um[14],plts_um[15],plts_um[16],
        layout = (4,4) ,size=(1000,1000))

scatter(predict(avr3,combined_data),combined_data.signal,msw=0,marker_z=combined_data.ch4d_avg)
scatter(predict(avr4,combined_data),combined_data.signal,msw=0,marker_z=combined_data.ch4d_avg)
scatter(predict(avr5,combined_data),combined_data.signal,msw=0,marker_z=combined_data.ch4d_avg)


combined_data.ch4d_rs = combined_data.ch4d_avg - predict(avr1,combined_data)
combined_data.rk1_rs = combined_data.Rs_1k - predict(avr2,combined_data)


combined_data.AV_hum2_res = combined_data.Rs_1k - predict()


#-------------------------------------------------------------------------------
#------------------THE GRAVEYARD------------------------------------------------
#-------------------------------------------------------------------------------


# lcs_path = lcs_paths[2]
# date = lcs_paths[1][end-11:end-4]
#read in lcs data
# lcs_data = process_lcs_data(lcs_data)

#2021-07-15 start time
# start = Dates.DateTime(2021,7,15,13,15)
# lcs_data = lcs_data[lcs_data.dt .< start, :]
