

"""
Read/write a region of image data from multiple bands.

This method allows reading a region of one or more `GDALRasterBands` from this
dataset into a buffer, or writing data from a buffer into a region of the
`GDALRasterBands`. It automatically takes care of data type translation if the
data type (`eBufType`) of the buffer is different than that of the
`GDALRasterBand`. The method also takes care of image decimation / replication
if the buffer size (`nBufXSize x nBufYSize`) is different than the size of the
region being accessed (`nXSize x nYSize`).

The `pxspace`, `linespace` and `bandspace` parameters allow reading into
or writing from various organization of buffers.

For highest performance full resolution data access, read and write on \"block
boundaries\" as returned by `GetBlockSize()`, or use the `ReadBlock()` and
`WriteBlock()` methods.

### Parameters
* `access`      Either `GF_Read` to read a region of data, or `GF_Write` to
                write a region of data.
* `xoffset`     The pixel offset to the top left corner of the band to be
                accessed. This would be 0 to start from the left side.
* `yoffset`     The line offset to the top left corner of the region of the
                band to be accessed. This would be zero to start from the top.
* `xsize`       The width of the region of the band to be accessed in pixels.
* `ysize`       The height of the region of the band to be accessed in lines.
* `buffer`      The buffer into which the data should be read, or from which it
                should be written. It must contain
                    ≥`nBufXSize * nBufYSize * nBandCount`
                words of type `eBufType`. It is organized in left to right,
                top to bottom pixel order. Spacing is controlled by the
                `nPixelSpace`, and `nLineSpace` parameters
* `xsz`         The width of the buffer image into which the desired region is
                to be read, or from which it is to be written.
* `ysz`         The height of the buffer image into which the desired region is
                to be read, or from which it is to be written.
* `bands`       The list of bands (1 based) to be read/written.
* `pxspace`     The byte offset from the start of one pixel value in `pBuffer`
                to the start of the next pixel value within a scanline.
                If defaulted (0) the size of the datatype `eBufType` is used.
* `linespace`   The byte offset from the start of one scanline in pBuffer to
                the start of the next. If defaulted (0) the size of the datatype
                `eBufType * nBufXSize` is used.
* `bandspace`   The byte offset from the start of one bands data to the start
                of the next. If defaulted (0) the value will be
                    `nlinespace * nBufYSize`
                implying band sequential organization of the data buffer.
* `psExtraArg`  (new in GDAL 2.0) pointer to a GDALRasterIOExtraArg structure
with additional arguments to specify resampling and progress callback, or
`NULL` for default behaviour. The `GDAL_RASTERIO_RESAMPLING` configuration
option can also be defined to override the default resampling to one of
`BILINEAR`, `CUBIC`, `CUBICSPLINE`, `LANCZOS`, `AVERAGE` or `MODE`.
"""
function rasterio!{T <: Real}(dataset::Dataset,
                              buffer::Array{T, 3},
                              bands::Vector{Cint},
                              access::GDALRWFlag=GF_Read,
                              pxspace::Integer = 0,
                              linespace::Integer = 0,
                              bandspace::Integer = 0)
    rasterio!(dataset, buffer, bands, 0, 0, width(dataset), height(dataset),
              access, pxspace, linespace, bandspace)
end

function rasterio!{T <: Real, U <: Integer}(
        dataset::Dataset,
        buffer::Array{T, 3},
        bands::Vector{Cint},
        rows::UnitRange{U},
        cols::UnitRange{U},
        access::GDALRWFlag=GF_Read,
        pxspace::Integer = 0,
        linespace::Integer = 0,
        bandspace::Integer = 0)
    xsize = cols[end] - cols[1] + 1; xsize < 0 && error("invalid window width")
    ysize = rows[end] - rows[1] + 1; ysize < 0 && error("invalid window height")
    rasterio!(dataset, buffer, bands, cols[1], rows[1], xsize, ysize, access,
              pxspace, linespace, bandspace)
end

"""
Read/write a region of image data for this band.

This method allows reading a region of a `GDALRasterBand` into a buffer, or
writing data from a buffer into a region of a `GDALRasterBand`. It
automatically takes care of data type translation if the data type (`eBufType`)
of the buffer is different than that of the `GDALRasterBand`. The method also
takes care of image decimation / replication if the buffer size
`(nBufXSize x nBufYSize)` is different than the size of the region being
accessed `(nXSize x nYSize)`.

The `nPixelSpace` and `nLineSpace` parameters allow reading into or writing
from unusually organized buffers. This is primarily used for buffers containing
more than one bands raster data in interleaved format.

Some formats may efficiently implement decimation into a buffer by reading from
lower resolution overview images.

For highest performance full resolution data access, read and write on "block
boundaries" returned by `GetBlockSize()`, or use the `ReadBlock()` and 
`WriteBlock()` methods.

### Parameters
* `eRWFlag`     Either GF_Read to read a region of data, or GF_Write to write a
region of data.
* `nXOff`       The pixel offset to the top left corner of the region of the
band to be accessed. This would be zero to start from the left side.
* `nYOff`       The line offset to the top left corner of the region of the
band to be accessed. This would be zero to start from the top.
* `nXSize`      The width of the region of the band to be accessed in pixels.
* `nYSize`      The height of the region of the band to be accessed in lines.
* `pData`       The buffer into which the data should be read, or from which it
should be written. This buffer must contain at least `(nBufXSize * nBufYSize)`
words of type `eBufType`. It is organized in left to right, top to bottom pixel
order. Spacing is controlled by the `nPixelSpace`, and `nLineSpace` parameters.
* `nBXSize`     The width of the buffer image into which the desired region is
to be read, or from which it is to be written.
* `nBYSize`     The height of the buffer image into which the desired region is
to be read, or from which it is to be written.
* `eBufType`    The type of the pixel values in the `buffer`. The pixel values
will be auto-translated to/from the `GDALRasterBand` data type as needed.
* `nPixelSpace` The byte offset from the start of one pixel value in `buffer`
to the start of the next pixel value within a scanline. If defaulted (0) the
size of the datatype `eBufType` is used.
* `nLineSpace`  The byte offset from the start of one scanline in `buffer` to
the start of the next. If defaulted (0) the size of the datatype
`(eBufType * nBufXSize)` is used.
* `psExtraArg`  (new in GDAL 2.0) pointer to a GDALRasterIOExtraArg structure
with additional arguments to specify resampling and progress callback, or
`NULL` for default behaviour. The `GDAL_RASTERIO_RESAMPLING` configuration
option can also be defined to override the default resampling to one of
`BILINEAR`, `CUBIC`, `CUBICSPLINE`, `LANCZOS`, `AVERAGE` or `MODE`.

### Returns
`CE_Failure` if the access fails, otherwise `CE_None`.
"""
function rasterio!{T <: Real}(rasterband::RasterBand,
                              buffer::Array{T,2},
                              access::GDALRWFlag=GF_Read,
                              pxspace::Integer=0,
                              linespace::Integer=0)
    rasterio!(rasterband, buffer, 0, 0, width(rasterband), height(rasterband),
              access, pxspace, linespace)
end

function rasterio!{T <: Real, U <: Integer}(
        rasterband::RasterBand,
        buffer::Array{T,2},
        rows::UnitRange{U},
        cols::UnitRange{U},
        access::GDALRWFlag=GF_Read,
        pxspace::Integer = 0,
        linespace::Integer = 0)
    xsize = length(cols); xsize < 1 && error("invalid window width")
    ysize = length(rows); ysize < 1 && error("invalid window height")
    rasterio!(rasterband, buffer, cols[1]-1, rows[1]-1, xsize, ysize,
              access, pxspace, linespace)
end

fetch!{T <: Real}(rb::RasterBand, buffer::Array{T,2}) =
    rasterio!(rb, buffer, GF_Read)

fetch!{T <: Real}(rb::RasterBand, buffer::Array{T,2}, xoffset::Integer,
                  yoffset::Integer, xsize::Integer, ysize::Integer) =
    rasterio!(rb, buffer, xoffset, yoffset, xsize, ysize)

fetch!{T <: Real, U <: Integer}(rb::RasterBand, buffer::Array{T,2},
                                rows::UnitRange{U}, cols::UnitRange{U}) =
    rasterio!(rb, buffer, rows, cols)

fetch(rb::RasterBand) =
    rasterio!(rb, Array(getdatatype(rb), width(rb), height(rb)))

function fetch(rb::RasterBand, xoffset::Integer, yoffset::Integer,
               xsize::Integer, ysize::Integer)
    buffer = Array(getdatatype(rb), width(rb), height(rb))
    rasterio!(rb, buffer, xoffset, yoffset, xsize, ysize)
end


fetch{U <: Integer}(rb::RasterBand, rows::UnitRange{U}, cols::UnitRange{U}) =
    rasterio!(rb, Array(getdatatype(rb), length(cols), length(rows)), rows, cols)

update!{T <: Real}(rb::RasterBand, buffer::Array{T,2}) =
    rasterio!(rb, buffer, GF_Write)

update!{T <: Real}(rb::RasterBand, buffer::Array{T,2}, xoffset::Integer,
                   yoffset::Integer, xsize::Integer, ysize::Integer) =
    rasterio!(rb, buffer, xoffset, yoffset, xsize, ysize, GF_Write)

update!{T <: Real, U <: Integer}(rb::RasterBand, buffer::Array{T,2},
                                 rows::UnitRange{U}, cols::UnitRange{U}) =
    rasterio!(rb, buffer, rows, cols, GF_Write)

fetch!{T <: Real}(dataset::Dataset, buffer::Array{T,2}, i::Integer) =
    fetch!(getband(dataset, i), buffer)

fetch!{T <: Real}(dataset::Dataset, buffer::Array{T,3}, indices::Vector{Cint}) =
    rasterio!(dataset, buffer, indices, GF_Read)

function fetch!{T <: Real}(dataset::Dataset, buffer::Array{T,3})
    nband = nraster(dataset); @assert size(buffer, 3) == nband
    rasterio!(dataset, buffer, collect(Cint, 1:nband), GF_Read)
end

fetch!{T <: Real}(dataset::Dataset, buffer::Array{T,2}, i::Integer,
        xoffset::Integer, yoffset::Integer, xsize::Integer, ysize::Integer) =
    fetch!(getband(dataset, i), buffer, xoffset, yoffset, xsize, ysize)

fetch!{T <: Real}(dataset::Dataset, buffer::Array{T,3}, indices::Vector{Cint},
        xoffset::Integer, yoffset::Integer, xsize::Integer, ysize::Integer) =
    rasterio!(dataset, buffer, indices, xoffset, yoffset, xsize, ysize)

fetch!{T <: Real, U <: Integer}(dataset::Dataset, buffer::Array{T,2},
                i::Integer, rows::UnitRange{U}, cols::UnitRange{U}) =
    fetch!(getband(dataset, i), buffer, rows, cols)

fetch!{T <: Real, U <: Integer}(dataset::Dataset, buffer::Array{T,3},
                indices::Vector{Cint}, rows::UnitRange{U}, cols::UnitRange{U}) =
    rasterio!(dataset, buffer, indices, rows, cols)

fetch(dataset::Dataset, i::Integer) = fetch(getband(dataset, i))

function fetch(dataset::Dataset, indices::Vector{Cint})
    buffer = Array(getdatatype(getband(dataset, indices[1])),
                   width(dataset), height(dataset), length(indices))
    rasterio!(dataset, buffer, indices)
end

function fetch(dataset::Dataset)
    buffer = Array(getdatatype(getband(dataset, 1)),
                   width(dataset), height(dataset), nraster(dataset))
    fetch!(dataset, buffer)
end

fetch(dataset::Dataset, i::Integer, xoffset::Integer, yoffset::Integer,
      xsize::Integer, ysize::Integer) =
    fetch(getband(dataset, i), xoffset, yoffset, xsize, ysize)

function fetch{T <: Integer}(dataset::Dataset, indices::Vector{T},
        xoffset::Integer, yoffset::Integer, xsize::Integer, ysize::Integer)
    buffer = Array(getdatatype(getband(dataset, indices[1])),
                   width(dataset), height(dataset), length(indices))
    rasterio!(dataset, buffer, indices, xsize, ysize, xoffset, yoffset)
end

fetch{U <: Integer}(dataset::Dataset, i::Integer, rows::UnitRange{U},
                    cols::UnitRange{U}) =
    fetch(getband(dataset, i), rows, cols)

function fetch{U <: Integer}(dataset::Dataset, indices::Vector{Cint},
                             rows::UnitRange{U}, cols::UnitRange{U})
    buffer = Array(getdatatype(getband(dataset, indices[1])),
                   width(dataset), height(dataset), length(indices))
    rasterio!(dataset, buffer, indices, rows, cols)
end

update!{T <: Real}(dataset::Dataset, buffer::Array{T,2}, i::Integer) =
    update!(getband(dataset, i), buffer)

update!{T <: Real}(dataset::Dataset, buffer::Array{T,3},
                   indices::Vector{Cint})=
    rasterio!(dataset, buffer, indices, GF_Write)

update!{T <: Real}(dataset::Dataset, buffer::Array{T,2}, i::Integer,
        xoffset::Integer, yoffset::Integer, xsize::Integer, ysize::Integer) =
    update!(getband(dataset, i), buffer, xoffset, yoffset, xsize, ysize)

update!{T <: Real}(dataset::Dataset, buffer::Array{T,3}, indices::Vector{Cint},
        xoffset::Integer, yoffset::Integer, xsize::Integer, ysize::Integer) =
    rasterio!(dataset, buffer, indices, xoffset, yoffset, xsize, ysize,
              GF_Write)

update!{T <: Real, U <: Integer}(dataset::Dataset, buffer::Array{T,2},
                        i::Integer, rows::UnitRange{U}, cols::UnitRange{U}) =
    update!(getband(dataset, i), buffer, rows, cols)

update!{T <: Real, U <: Integer}(dataset::Dataset, buffer::Array{T,3},
            indices::Vector{Cint}, rows::UnitRange{U}, cols::UnitRange{U}) =
    rasterio!(dataset, buffer, indices, rows, cols, GF_Write)

for (T,GT) in _GDALTYPE
    eval(quote
        function rasterio!(dataset::Dataset,
                           buffer::Array{$T, 3},
                           bands::Vector{Cint},
                           xoffset::Integer,
                           yoffset::Integer,
                           xsize::Integer,
                           ysize::Integer,
                           access::GDALRWFlag=GF_Read,
                           pxspace::Integer=0,
                           linespace::Integer=0,
                           bandspace::Integer=0,
                           extraargs=Ptr{GDAL.GDALRasterIOExtraArg}(C_NULL))
            (dataset == C_NULL) && error("Can't read invalid rasterband")
            xbsize, ybsize, zbsize = size(buffer)
            nband = length(bands); @assert nband == zbsize
            result = ccall((:GDALDatasetRasterIOEx,GDAL.libgdal),GDAL.CPLErr,
                           (Dataset,GDAL.GDALRWFlag,Cint,Cint,Cint,Cint,
                            Ptr{Void},Cint,Cint,GDAL.GDALDataType,Cint,
                            Ptr{Cint},GDAL.GSpacing,GDAL.GSpacing,GDAL.GSpacing,
                            Ptr{GDAL.GDALRasterIOExtraArg}),dataset,access,
                            xoffset,yoffset,xsize,ysize,pointer(buffer),xbsize,
                            ybsize,$GT,nband,pointer(bands),pxspace,linespace,
                            bandspace,extraargs)
            @cplerr result "Access in DatasetRasterIO failed."
            buffer
        end

        function rasterio!(rasterband::RasterBand,
                           buffer::Array{$T,2},
                           xoffset::Integer,
                           yoffset::Integer,
                           xsize::Integer,
                           ysize::Integer,
                           access::GDALRWFlag=GF_Read,
                           pxspace::Integer=0,
                           linespace::Integer=0,
                           extraargs=Ptr{GDAL.GDALRasterIOExtraArg}(C_NULL))
            (rasterband == C_NULL) && error("Can't read invalid rasterband")
            xbsize, ybsize = size(buffer)
            result = ccall((:GDALRasterIOEx,GDAL.libgdal),GDAL.CPLErr,
                           (RasterBand,GDAL.GDALRWFlag,Cint,Cint,Cint,Cint,
                            Ptr{Void},Cint,Cint,GDAL.GDALDataType,GDAL.GSpacing,
                            GDAL.GSpacing,Ptr{GDAL.GDALRasterIOExtraArg}),
                            rasterband,access,xoffset,yoffset,xsize,ysize,
                            pointer(buffer),xbsize,ybsize,$GT,pxspace,linespace,
                            extraargs)
            @cplerr result "Access in RasterIO failed."
            buffer
        end
    end)
end

"""
Read a block of image data efficiently.

This method accesses a "natural" block from the raster band without resampling, 
or data type conversion. For a more generalized, but potentially less efficient 
access use RasterIO().

### Parameters
* `xoffset` the horizontal block offset, with zero indicating the left most 
            block, 1 the next block and so forth.
* `yoffset` the vertical block offset, with zero indicating the top most block,
            1 the next block and so forth.
* `buffer`  the buffer into which the data will be read. The buffer must be 
            large enough to hold GetBlockXSize()*GetBlockYSize() words of type 
            GetRasterDataType().
"""
function readblock!(rb::RasterBand, xoffset::Integer, yoffset::Integer, buffer)
    result = GDAL.readblock(rb, xoffset, yoffset, buffer)
    @cplerr result "Failed to read block at ($xoffset,$yoffset)"
    buffer
end

readblock(rb::RasterBand, xoff::Integer, yoff::Integer) =
    readblock!(rb,xoff,yoff,Array(getdatatype(rb),width(rb),height(rb)))

"""
Write a block of image data efficiently.

This method accesses a "natural" block from the raster band without resampling,
or data type conversion. For a more generalized, but potentially less efficient 
access use RasterIO().

### Parameters
* `xoffset` the horizontal block offset, with zero indicating the left most 
            block, 1 the next block and so forth.
* `yoffset` the vertical block offset, with zero indicating the left most block,
            1 the next block and so forth.
* `buffer`  the buffer from which the data will be written. The buffer must be 
            large enough to hold GetBlockXSize()*GetBlockYSize() words of type
            GetRasterDataType().
"""
function writeblock!(rb::RasterBand, xoffset::Integer, yoffset::Integer, buffer)
    result = GDAL.writeblock(rb, xoffset, yoffset, buffer)
    @cplerr result "Failed to write block at ($xoffset,$yoffset)"
    buffer
end
