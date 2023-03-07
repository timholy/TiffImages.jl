"""
    mmap(f, filepath; mode="r", verbose=true)

Loads a TIFF image using memory-mapping.

```julia
mmap(filename) do img
    # process image here readonly
end

map(filename; mode="w") do img
    # process image here read/write
end
```
"""
function mmap(f, filepath;  mode = "r", kwargs...)
    open(filepath, mode) do io
        load(io; kwargs...)
    end
end

function mmap(f, io::IOStream; kwargs...)
    try
        return mmap(f, read(io, TiffFile); kwargs...)
    finally
        close(io)
    end
end
function mmap(f, tf::TiffFile; verbose=true)
    ifds = IFD{offset(tf)}[]

    nplanes = 0
    for ifd in tf
        load!(tf, ifd)
        push!(ifds, ifd)
        nplanes += 1
    end

    ifd = first(ifds)
    img = if iscontiguous(ifd) && getdata(CompressionType, ifd, COMPRESSION, COMPRESSION_NONE) === COMPRESSION_NONE
        MmappedTIFF(tf, ifds)
    else
        verbose && @warn "Compression and discontiguous planes are not supported by `mmap`, use lazy I/O instead"
        loaded = DiskTaggedImage(tf, ifds)
        fixcolors(loaded, first(ifds))
    end

    return f(img)
end
