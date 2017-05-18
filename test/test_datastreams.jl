using ArchGDAL, DataFrames, DataStreams
const AG = ArchGDAL

@time result = AG.registerdrivers() do
    AG.read("ospy/data1/sites.shp") do ds
        Data.stream!(AG.Source(AG.getlayer(ds, 0)), DataFrame)
    end
end
@time result = AG.registerdrivers() do
    AG.read("ospy/data1/sites.shp") do ds
        Data.stream!(AG.Source(AG.getlayer(ds, 0)), DataFrame)
    end
end
