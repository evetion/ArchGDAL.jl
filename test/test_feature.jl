using Base.Test
import ArchGDAL; const AG = ArchGDAL

AG.registerdrivers() do
    AG.read("data/point.geojson") do dataset
        layer = AG.getlayer(dataset, 0)
        AG.getfeature(layer, 0) do f1
            AG.getfeature(layer, 2) do f2
                println(f1)
                println(AG.getgeom(f1))
                fid1 = AG.getfid(f1); println(fid1)
                println(f2)
                println(AG.getgeom(f2))
                fid2 = AG.getfid(f2); println(fid2)
                println(AG.equals(AG.getgeom(f1), AG.getgeom(f2)))
                AG.clone(f1) do f3
                    @test AG.equals(AG.getgeom(f1), AG.getgeom(f3)) == true
                end
                AG.setfid!(f1, fid2); AG.setfid!(f2, fid1)
                println(fid1, fid2)
                println(AG.getfid(f1), AG.getfid(f2))

                println("f1 geomfieldindex for geom: $(AG.getgeomfieldindex(f1, "geom"))")
                println("f1 geomfieldindex for \"\": $(AG.getgeomfieldindex(f1, ""))")
                println("f2 geomfieldindex for geom: $(AG.getgeomfieldindex(f2, "geom"))")
                println("f2 geomfieldindex for \"\": $(AG.getgeomfieldindex(f2, ""))")
                println("f1 geomfielddefn: $(AG.getgeomfielddefn(f1, 0))")
                println("f2 geomfielddefn: $(AG.getgeomfielddefn(f2, 0))")
            end
        end
        AG.getfeature(layer, 0) do f
            @test AG.toWKT(AG.getgeomfield(f,0)) == "POINT (100 0)"
            AG.setgeomfielddirectly!(f, 0, AG.unsafe_createpoint(0,100))
            @test AG.toWKT(AG.getgeomfield(f,0)) == "POINT (0 100)"
            AG.createpolygon([(0.,100.),(100.,0.)]) do poly
                AG.setgeomfield!(f, 0, poly)
            end
            @test AG.toWKT(AG.getgeomfield(f,0)) == "POLYGON ((0 100,100 0))"

            AG.setstylestring!(f, "@Name")
            @test AG.getstylestring(f) == "@Name"
            AG.setstylestring!(f, "NewName")
            @test AG.getstylestring(f) == "NewName"

            AG.setstyletabledirectly!(f, AG.unsafe_createstyletable())
            println(AG.getstyletable(f))
            AG.createstyletable() do st
                AG.setstyletable!(f, st)
            end
            println(AG.getstyletable(f))

            AG.setnativedata!(f, "nativedata1")
            @test AG.getnativedata(f) == "nativedata1"
            AG.setnativedata!(f, "nativedata2")
            @test AG.getnativedata(f) == "nativedata2"

            AG.setmediatype!(f, "mediatype1")
            @test AG.getmediatype(f) == "mediatype1"
            AG.setmediatype!(f, "mediatype2")
            @test AG.getmediatype(f) == "mediatype2"

            @test AG.validate(f, GDAL.OGR_F_VAL_NULL, false) == true
            @test AG.validate(f, GDAL.OGR_F_VAL_GEOM_TYPE, false) == false
            @test AG.validate(f, GDAL.OGR_F_VAL_WIDTH, false) == true
            @test AG.validate(f, GDAL.OGR_F_VAL_ALLOW_NULL_WHEN_DEFAULT, false) == true
            @test AG.validate(f, GDAL.OGR_F_VAL_ALLOW_DIFFERENT_GEOM_DIM, false) == true

            @test AG.getfield(f, 1) == "point-a"
            AG.setdefault!(AG.getfielddefn(f, 1),"nope")
            @test AG.getfield(f, 1) == "point-a"
            AG.unsetfield!(f, 1)
            @test AG.getfield(f, 1) == nothing
            AG.fillunsetwithdefault!(f, notnull=false)
            @test AG.getfield(f, 1) == "nope"
        end
    end

    println("Memory")
    AG.create("", "MEMORY") do output
        layer = AG.createlayer(output, "dummy", geom=AG.wkbPolygon)
        AG.createfielddefn("int64field", AG.OFTInteger64) do fielddefn
            AG.createfield!(layer, fielddefn)
        end
        AG.createfielddefn("doublefield", AG.OFTReal) do fielddefn
            AG.createfield!(layer, fielddefn)
        end
        AG.createfielddefn("intlistfield", AG.OFTIntegerList) do fielddefn
            AG.createfield!(layer, fielddefn)
        end
        AG.createfielddefn("int64listfield", AG.OFTInteger64List) do fielddefn
            AG.createfield!(layer, fielddefn)
        end
        AG.createfielddefn("doublelistfield", AG.OFTRealList) do fielddefn
            AG.createfield!(layer, fielddefn)
        end
        AG.createfielddefn("stringlistfield", AG.OFTStringList) do fielddefn
            AG.createfield!(layer, fielddefn)
        end
        AG.createfielddefn("binaryfield", AG.OFTBinary) do fielddefn
            AG.createfield!(layer, fielddefn)
        end
        AG.createfielddefn("datetimefield", AG.OFTDateTime) do fielddefn
            AG.createfield!(layer, fielddefn)
        end
        AG.createfeature(layer) do feature
            AG.setfield!(feature, 0, 1)
            AG.setfield!(feature, 1, 1.0)
            AG.setfield!(feature, 2, Cint[1, 2])
            AG.setfield!(feature, 3, Int64[1, 2])
            AG.setfield!(feature, 4, Float64[1.0, 2.0])
            AG.setfield!(feature, 5, ["1", "2.0"])
            AG.setfield!(feature, 6, GDAL.GByte[1,2,3,4])
            AG.setfield!(feature, 7, Dates.DateTime(2016,9,25,21,17,0))

            AG.createfeature(layer) do newfeature
                AG.setfrom!(newfeature, feature)
                @test AG.getfield(newfeature, 0) == 1 
                @test AG.getfield(newfeature, 1) ≈ 1.0
                @test AG.getfield(newfeature, 2) == Int32[1, 2]
                @test AG.getfield(newfeature, 3) == Int64[1, 2]
                @test AG.getfield(newfeature, 4) ≈ [1.0, 2.0]
                @test AG.getfield(newfeature, 5) == ["1", "2.0"]
                @test AG.getfield(newfeature, 6) == GDAL.GByte[1,2,3,4]
                @test AG.getfield(newfeature, 7) == Dates.DateTime(2016,9,25,21,17,0)

                AG.createfeature(layer) do lastfeature
                    AG.setfrom!(lastfeature, feature)
                    AG.setfield!(lastfeature, 0, 45)
                    AG.setfield!(lastfeature, 1, 18.2)
                    AG.setfield!(lastfeature, 5, ["foo", "bar"])
                    @test AG.getfield(lastfeature, 0) == 45
                    @test AG.getfield(lastfeature, 1) ≈ 18.2
                    @test AG.getfield(lastfeature, 2) == Int32[1, 2]
                    @test AG.getfield(lastfeature, 3) == Int64[1, 2]
                    @test AG.getfield(lastfeature, 4) ≈ [1.0, 2.0]
                    @test AG.getfield(lastfeature, 5) == ["foo", "bar"]
                    @test AG.getfield(lastfeature, 6) == GDAL.GByte[1,2,3,4]
                    @test AG.getfield(lastfeature, 7) == Dates.DateTime(2016,9,25,21,17,0)

                    @test AG.getfield(newfeature, 0) == 1
                    @test AG.getfield(newfeature, 1) ≈ 1.0
                    @test AG.getfield(newfeature, 5) == ["1", "2.0"]
                    AG.setfrom!(newfeature, lastfeature, collect(Cint, 0:7))
                    @test AG.getfield(newfeature, 0) == 45
                    @test AG.getfield(newfeature, 1) ≈ 18.2
                    @test AG.getfield(newfeature, 5) == ["foo", "bar"]
                end
            end
        end
    end
end
