using CSV
using DataFrames
using StatsBase
using Interpolations


function movingWindowAverager(list, windowlength, pct)
    #=function takes in list of data, returns the pct-th
    percentile of the backgoround in moving window of windowlength
    indicies=#
    len = length(list)
    percent = [] #list to return
    for i in 1:len
      if i <= windowlength #at the start of the data, window = 1 to i + windowlength
          # println("ding: ", i)
          push!(percent, percentile(list[1:i+windowlength],pct))
      elseif i + windowlength+1 > len   #at end of data, window = i-windowlength to end
          # println("dong")
          push!(percent, percentile(list[i-windowlength:len-1],pct))
      else
          #in between, window is i-windowlength to i+windowlength
          # println("ditch")
          push!(percent,percentile(list[i-windowlength:i+windowlength],pct))
      end
    end
    return percent

end

#dateformats for functions
dfmt1 = "yyyy-mm-dd HH:MM:SS"


function process_sync_data(df)
        #=df exected to be a pass of sync_data frame=#
        df.dts = [r.gps_time[1:19] for r in eachrow(df)]
        df.dt2 = [DateTime(r.dts,dfmt1) for r in eachrow(df)]
        df.dt1 = [r.dt2 - Dates.Hour(4) for r in eachrow(df)]
        df.ch4d_avg = movingWindowAverager(df.ch4d,120,50)
        return df
end

# function clean_bad_lcs_data!(lcs_data, bad_date=false)
#         #= A function to clean data calculated from  YYYYMMDD.CSV
#         LCS files. 2022-02-10 =#
#         if bad_date == true
#                 dfmt = "yyyy-mm-02d HH:MM:SS"
#         else
#                 dfmt = "yyyy-mm-dd HH:MM:SS"
#         end
#         lcs_data.datetime = [Dates.DateTime(r.dt,dfmt) for r in eachrow(lcs_data)]
#
#         lcs_data.abs_hum = [6.112 * exp((17.67 * r.hum_BME)/(r.temp_BME+243.5)) * r.hum_BME *
#                                     2.1674 / (273.15+r.temp_BME) for r in eachrow(lcs_data)]
#
#         #calculate voltage at the voltage divider
#         lcs_data.V_rl1 = ( lcs_data.ADC1.+2^23 ) ./(2^24 - 1) .* 5
#         lcs_data.V_rl2 = ( lcs_data.ADC2.+2^23 ) ./(2^24 - 1) .* 5
#
#         #calculate the sensor's resistance
#         # lcs_data.R_s1 =
#
#
# end

function clean_lcs_data!(lcs_data)
        #=Function to process low cost sensor dataframes,
          Expects columns named dt,ADC1,ADC2,temp_BME,pres_BME,hum_BME,
          Resistor1,Sensor1,Resistor2,Sensor2=#
          dfmt = "yyyy-mm-d HH:MM:SS"

          lcs_data.datetime = [Dates.DateTime(r.dt,dfmt) for r in eachrow(lcs_data)]

          lcs_data.abs_hum = [6.112 * exp((17.67 * r.hum_BME)/(r.temp_BME+243.5)) * r.hum_BME *
                                      2.1674 / (273.15+r.temp_BME) for r in eachrow(lcs_data)]


          #Calculate the voltage at the voltage divider?
          lcs_data."V_rl1" = (lcs_data."ADC1".+2^23)./(2^24-1) .*5
          lcs_data."V_rl2" = (lcs_data."ADC2".+2^23)./(2^24-1) .*5

          #Calculate the sensor's resistance, assuming 510 ohm resisitors if
          #no values are given
          lcs_data."Rs_1" = (5 ./lcs_data."V_rl1" .- 1) .* lcs_data.Resistor1
          lcs_data."Rs_2" = (5 ./lcs_data."V_rl2" .- 1) .* lcs_data.Resistor2
          lcs_data."Rs_1k" = lcs_data.Rs_1 ./ 1000
          lcs_data."Rs_2k" = lcs_data.Rs_2 ./ 1000

          # return lcs_data
  end

function add_literature_corrections!(lcs_data)
        #=Adds the corerctions from Eugster et al
        and equations from Riddick et al=#
        lcs_data."Rs/Ro1" = lcs_data.Rs_1 ./ percentile(lcs_data.Rs_1,3)
        lcs_data."Rs/Ro2" = lcs_data.Rs_2 ./ percentile(lcs_data.Rs_2,3)
        lcs_data."Rs1_corr" = [ r."Rs/Ro1" *
                (0.024+ 0.0072 * r.hum_BME + 0.0246 * r.temp_BME)
                for r in eachrow(lcs_data) ]
        lcs_data."Rs2_corr" = [ r."Rs/Ro2" *
                (0.024+ 0.0072 * r.hum_BME + 0.0246 * r.temp_BME)
                for r in eachrow(lcs_data) ]

        lcs_data."CH4_Eug" = 1.82 .+ 0.0288 .* -lcs_data."Rs1_corr"
        lcs_data."CH4_Eug2" = 1.82 .+ 0.0288 .* -lcs_data."Rs2_corr"

        ## Riddick et al. Correction

        lcs_data."CH4_Ridd" = [1.8 + 0.09 * exp(11.669*(r.Rs1_corr-0.7083))
                                for r in eachrow(lcs_data)]

        lcs_data."CH4_Ridd2" = [1.8 + 0.09 * exp(11.669*(r.Rs2_corr-0.7083))
                                for r in eachrow(lcs_data)]
end

function process_lcs_data(lcs_data, R1 = 510, R2 = 510)
        #=Function to process low cost sensor dataframes,
          Expects columns named datetime,NAU7802_ch1,NAU7802_ch2,
          tempp_bme,pres_bme, and hum_bme
          Function assumes voltagge divider resistances R1 and R2=#

        #Make a second resolution datetime string column
        # lcs_data.datetime = [r.datetime[1:19] for r in eachrow(lcs_data)]

        #Made datetimes out of those strings
        lcs_data.dt1 = [Dates.DateTime(r.dt,dfmt1) for r in eachrow(lcs_data)]

        #Copying column names because I copy and pasted old code...
        lcs_data."24Bit1" = lcs_data.NAU7802_ch1 #.+ 2^23
        lcs_data."24Bit2" = lcs_data.NAU7802_ch2 #.+ 2^23

        #Calculate the voltage at the voltage divider?
        lcs_data."V_rl1" = lcs_data."24Bit1"./(2^24-1) .*5
        lcs_data."V_rl2" = lcs_data."24Bit2"./(2^24-1) .*5

        #Calculate the sensor's resistance, assuming 510 ohm resisitors if
        #no values are given
        lcs_data."Rs_1" = (5 ./lcs_data."V_rl1" .- 1) .* R1
        lcs_data."Rs_2" = (5 ./lcs_data."V_rl2" .- 1) .* R2
        lcs_data."Rs_1k" = lcs_data.Rs_1 ./ 1000
        lcs_data."Rs_2k" = lcs_data.Rs_2 ./ 1000

        #difference between the two Sensors
        lcs_data."diff" = lcs_data.Rs_2 - lcs_data.Rs_1


        lcs_data."Ch1_avg" = movingWindowAverager(lcs_data.NAU7802_ch1,5,50)
        lcs_data."Ch2_avg" = movingWindowAverager(lcs_data.NAU7802_ch2,5,50)
        lcs_data."Rs_1_avg" = movingWindowAverager(lcs_data.Rs_1,5,50)
        lcs_data."Rs_2_avg" = movingWindowAverager(lcs_data.Rs_2,5,50)
        lcs_data.hum_avg = movingWindowAverager(lcs_data.hum_bme,30,50)
        lcs_data.res = lcs_data.Rs_1_avg - lcs_data.Rs_2_avg

        lcs_data."Rs/Ro1" = lcs_data.Rs_1_avg ./ minimum(lcs_data.Rs_1_avg)
        lcs_data."Rs/Ro2" = lcs_data.Rs_2_avg ./ minimum(lcs_data.Rs_2_avg)

        #calculate the mean
        lcs_data."Rs_Ro1" = lcs_data.Rs_1 ./ maximum(lcs_data.Rs_1)
        lcs_data."Rs_Ro2" = lcs_data.Rs_2 ./ maximum(lcs_data.Rs_2)



        #Original Correction from Eugster et al.
        lcs_data."Rs/Ro1_corr" = [ r."Rs/Ro1" *
                (0.024+ 0.0072 * r.hum_bme + 0.0246 * r.tempp_bme)
                for r in eachrow(lcs_data) ]

        lcs_data."CH4_Eug" = 1.82 .+ 0.0288 .* -lcs_data."Rs/Ro1_corr"

        ## Riddick et al. Correction

        lcs_data."CH4_Ridd" = [1.8 + 0.09 * exp(11.669*(r."Rs/Ro1_corr"-0.7083))
                                for r in eachrow(lcs_data)]

        #calculate absolute humidity (g/kg) ? from BME data
        lcs_data.abs_hum = [6.112 * exp((17.67 * r.tempp_bme)/(r.tempp_bme+243.5)) * r.hum_bme *
                                2.1674 / (273.15+r.tempp_bme) for r in eachrow(lcs_data)]

        #calculate seconds since start
        lcs_data.sec = [(lcs_data.dt[n]-lcs_data.dt[1]).value/1000
                                    for n in 1:length(eachrow(lcs_data))]

        return lcs_data
end


function linearly_interpolate_columns(input_df)
        #=Function to interpolate  low cost sensor dataframes,
          Expects columns named sec, returns linear for all data=#
          dataframe = deepcopy(input_df)
          first, last =  dataframe.sec[1], dataframe.sec[end]
          secs = dataframe.sec
          select!(dataframe, Not(:sec))
          # select!(dataframe, Not(String))
          select!(dataframe, findall(col -> eltype(col) <: Float64, eachcol(dataframe)))
          colnames = names(dataframe)
          # filter!(x->x!="sec",colnames)
          out_frame = DataFrame()
          out_frame.sec = collect(first:last)
          for (i,col) in enumerate(eachcol(dataframe))
                  interp_linear = LinearInterpolation(secs, col)
                  out_frame[!,colnames[i]] = [interp_linear(n) for n in out_frame.sec]
          end
          return out_frame
  end
