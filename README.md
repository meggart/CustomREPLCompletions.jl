# CustomREPLCompletions

[![Build Status](https://travis-ci.org/meggart/CustomREPLCompletions.jl.svg?branch=master)](https://travis-ci.org/meggart/CustomREPLCompletions.jl)

This package provides a hook into Julia's REPL completions system, so that you can customize the completions behavior depending on the context.
That means that when the REPL cursor is inside a String that one wants to complete, the package's code will check if this string is inside
a function call and if so, if there are special complete methods for strings inside the function.
E.g. if you want to access a Dict `d` with String keys, in the REPL you would type

    using CustomREPLCompletions
    d=Dict("aa"=>5,"bb"=>6)
    d["


and on hitting *tab* you will get completions suggestions depending on your Dict's keys.
In order to achieve this behavior you define a method of the `custom_completions` function, taking the function type of `getindex` as its first argument:

````julia
function custom_completions{K<:AbstractString,V}(::typeof(getindex),a::Dict{K,V},s::AbstractString)
    return UTF8String[utf8(x) for x in keys(a)]
end
````

The following arguments of the methods are the arguments of the function that provides the context, in our case this will be a Dict and an empty
String. It is also assumed that completion is always performed on the last argument.
The function should always return an array of UTF8Strings including the completion suggestions.

Another example would be a completion for the `ncgetatt` function from the NetCDF package. It has the following signature:

````julia
ncgetatt(fil::AbstractString, vname::AbstractString, att::AbstractString)
````

NetCDF is a data storage format that allows one to store multiple variables in a single file, where each variable is additionally allowed to have some named attributes.
In order to customize the completion for this function one needs to define 2 methods of `custom_completions`:

````julia
function custom_completions(f::typeof(ncgetatt),filename::AbstractString,varname::AbstractString)
    # Read and return list of variable names from filename
end
````
The method above is responsible for the variable name completion, assuming the cursor is at the position of the second string argument.

````julia
function custom_completions(f::typeof(ncgetatt),filename::AbstractString,varname::AbstractString,attname::AbstractString)
    #Read list of attributes associated to the variable varname and return them
end
````
Above method is responsible for completion of the attribute name and already has access to the variable name given by the user.

Have a look at the examples folder for the full examples.
