macro load_examples()
  #Add some String Dict lookup
  Dict_example=quote
    function custom_completions{K<:AbstractString,V}(::typeof(getindex),a::Dict{K,V},s::AbstractString)
      return UTF8String[utf8(x) for x in keys(a)]
    end
  end


  #Add lookup of names in NetCDF variables
  NetCDF_example=quote
    using NetCDF
    function custom_completions(f::typeof(ncread),filename::AbstractString,varname::AbstractString)
      !isfile(filename) && return UTF8STring[]
      try
        nc=NetCDF.open(filename)
        return collect(keys(nc.vars))
      end
      return UTF8String[]
    end

    function custom_completions(f::typeof(ncgetatt),filename::AbstractString,varname::AbstractString)
      !isfile(filename) && return UTF8STring[]
      try
        nc=NetCDF.open(filename)
        return collect(keys(nc.vars))
      end
      return UTF8String[]
    end

    function custom_completions(f::typeof(ncgetatt),filename::AbstractString,varname::AbstractString,attname::AbstractString)
      !isfile(filename) && return UTF8STring[]
      try
        nc=NetCDF.open(filename)
        return collect(keys(nc.vars[varname].atts))
      end
      return UTF8String[]
    end
  end
  HDF5_example=quote
    #Add group and variable name lookup in HDF5
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
  end
  retex=Dict_example
  if Pkg.installed("NetCDF")!=nothing
    retex=quote
      $retex
      $NetCDF_example
    end
  end
  if Pkg.installed("HDF5")!=nothing
    retex=quote
      $retex
      $HDF5_example
    end
  end
  esc(retex)
end
