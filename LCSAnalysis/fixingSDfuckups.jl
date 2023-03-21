using CSV
using DataFrames
using Dates

path = "/home/lawson/Research/Data/LCS_data/Twin_Creeks_2022/LateOctAll.CSV"

data = CSV.read(path,DataFrame)
include("data_handling_functions.jl")
# process_lcs_data(data)
clean_lcs_data!(data)
# dfmt = "yyyy-mm-dd HH:MM:SS"
# for (i,d) in enumerate(data.dt)
#     try
#         DateTime(d,dfmt)
#     catch
#         println(d, "   ", i)
#     end
# end

# data.datetime =  [DateTime(d,dfmt) for d in data.dt]

data_21 = data[Date(2022,10,21) .< data.datetime .< Date(2022,10,22), :]
CSV.write("20221021.CSV",data_21)
data_22 = data[Date(2022,10,22) .< data.datetime .< Date(2022,10,23), :]
data_23 = data[Date(2022,10,23) .< data.datetime .< Date(2022,10,24), :]
data_24 = data[Date(2022,10,24) .< data.datetime .< Date(2022,10,25), :]
data_25 = data[Date(2022,10,25) .< data.datetime .< Date(2022,10,26), :]
CSV.write("20221025.CSV",data_25)
data_26 = data[Date(2022,10,26) .< data.datetime .< Date(2022,10,27), :]
CSV.write("20221026.CSV",data_26)
data_27 = data[Date(2022,10,27) .< data.datetime .< Date(2022,10,28), :]
CSV.write("20221027.CSV",data_27)
data_28 = data[Date(2022,10,28) .< data.datetime .< Date(2022,10,29), :]
CSV.write("20221028.CSV",data_28)
data_29 = data[Date(2022,10,29) .< data.datetime .< Date(2022,10,30), :]
CSV.write("20221029.CSV",data_29)
data_30 = data[Date(2022,10,30) .< data.datetime .< Date(2022,10,31), :]
data_31 = data[Date(2022,10,31) .< data.datetime .< Date(2022,11,01), :]
