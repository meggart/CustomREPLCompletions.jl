using NetCDF
function custom_completions(f::typeof(ncread),filename::AbstractString,varname::AbstractString)
    !isfile(filename) && return UTF8STring[]
    try
        nc=NetCDF.open(filename)
        return collect(keys(nc.vars))
    end
    return UTF8String[]
end

using HDF5
function custom_completions(f::typeof(h5read),filename::AbstractString,var::AbstractString)
    !isfile(filename) && return UTF8STring[]
    try
        #First try to split expression in var
        m=match(r"/",reverse(var))
        if m==nothing
          h=h5open(filename,"r")
          nlist=names(h)
          return UTF8String[isa(h[nn],HDF5.HDF5Group) ? nn*"/" : nn for nn in nlist]
        else
          h=h5open(filename,"r")
          sleft=var[1:(end-m.offset)]
          d=h[sleft]
          nlist=names(d)
          return UTF8String[isa(d[nn],HDF5.HDF5Group) ? nn*"/" : nn for nn in nlist]
        end
    end
    return UTF8String[]
end
