__precompile__()
module CustomREPLCompletions

function custom_completions end


function custom_complete_methods(ex_org::Expr)
func, found = Base.REPLCompletions.get_value(ex_org.args[1], Main)
    (!found || (found && !isa(func,Function))) && return false, UTF8String[]
    args_ex = DataType[Base.REPLCompletions.get_type(ex_org.args[1],Main)[1]]
    for ex in ex_org.args[2:end]
    val, found = Base.REPLCompletions.get_type(ex, Main)
        push!(args_ex, val)
    end
    t_in = Tuple{args_ex...} # Input types
    if method_exists(custom_completions,t_in)
        args_val=[Base.REPLCompletions.get_value(ex_org.args[i],Main)[1] for i=2:length(args_ex)]
        return true, custom_completions(func,args_val...)
    end
    return false, UTF8String[]
end

function Base.REPLCompletions.completions(string, pos)
    # First parse everything up to the current position
    partial = string[1:pos]
    inc_tag = Base.syntax_deprecation_warnings(false) do
        Base.incomplete_tag(parse(partial, raise=false))
    end

    #This is the extra check if the string ends with " inside function call
    if inc_tag in [:other,:string]
        if inc_tag==:other
            newpartial=endswith(partial,"\"") ? partial*"," : partial
            newinc_tag=inc_tag
        else
            newpartial=partial*"\","
            newinc_tag = Base.syntax_deprecation_warnings(false) do
                Base.incomplete_tag(parse(newpartial, raise=false))
            end
        end
        frange, method_name_end = Base.REPLCompletions.find_start_brace(newpartial)
        ex = Base.syntax_deprecation_warnings(false) do
            parse(newpartial[frange] * ")", raise=false)
        end
        if isa(ex, Expr) && ex.head==:call
            success,suggestions=custom_complete_methods(ex)
            println()
            println(success)
            if success
                m = match(r"[\t\n\r\"'/`@\$><=;|&\{]| (?!\\)", reverse(partial))
                println(m)
                startpos = nextind(partial, reverseind(partial, m.offset))
                r = startpos:pos
                pshort=partial[r]
                println(suggestions)
                println(pshort)
                filter!(x->startswith(x,pshort),suggestions)
                isempty(suggestions) || return suggestions, r, true
            end
        end
    end



    if inc_tag in [:cmd, :string]
        m = match(r"[\t\n\r\"'`@\$><=;|&\{]| (?!\\)", reverse(partial))
        startpos = nextind(partial, reverseind(partial, m.offset))
        r = startpos:pos
        paths, r, success = Base.REPLCompletions.complete_path(replace(string[r], r"\\ ", " "), pos)
        if inc_tag == :string &&
           length(paths) == 1 &&                              # Only close if there's a single choice,
           !isdir(expanduser(replace(string[startpos:start(r)-1] * paths[1], r"\\ ", " "))) &&  # except if it's a directory
           (length(string) <= pos || string[pos+1] != '"')    # or there's already a " at the cursor.
            paths[1] *= "\""
        end
        #Latex symbols can be completed for strings
        (success || inc_tag==:cmd) && return sort(paths), r, success
    end

    ok, ret = Base.REPLCompletions.bslash_completions(string, pos)
    ok && return ret

    # Make sure that only bslash_completions is working on strings
    inc_tag==:string && return UTF8String[], 0:-1, false

    if inc_tag == :other && Base.REPLCompletions.should_method_complete(partial)
        frange, method_name_end = Base.REPLCompletions.find_start_brace(partial)
        ex = Base.syntax_deprecation_warnings(false) do
            parse(partial[frange] * ")", raise=false)
        end
        if isa(ex, Expr) && ex.head==:call
            return Base.REPLCompletions.complete_methods(ex), start(frange):method_name_end, false
        end
    elseif inc_tag == :comment
        return UTF8String[], 0:-1, false
    end

    dotpos = rsearch(string, '.', pos)
    startpos = nextind(string, rsearch(string, Base.REPLCompletions.non_identifier_chars, pos))

    ffunc = (mod,x)->true
    suggestions = UTF8String[]
    comp_keywords = true
    if Base.REPLCompletions.afterusing(string, startpos)
        # We're right after using or import. Let's look only for packages
        # and modules we can reach from here

        # If there's no dot, we're in toplevel, so we should
        # also search for packages
        s = string[startpos:pos]
        if dotpos <= startpos
            for dir in [Pkg.dir(); LOAD_PATH; pwd()]
                isdir(dir) || continue
                for pname in readdir(dir)
                    if pname[1] != '.' && pname != "METADATA" &&
                        pname != "REQUIRE" && startswith(pname, s)
                        # Valid file paths are
                        #   <Mod>.jl
                        #   <Mod>/src/<Mod>.jl
                        #   <Mod>.jl/src/<Mod>.jl
                        if isfile(joinpath(dir, pname))
                            endswith(pname, ".jl") && push!(suggestions, pname[1:end-3])
                        else
                            mod_name = if endswith(pname, ".jl")
                                pname[1:end - 3]
                            else
                                pname
                            end
                            if isfile(joinpath(dir, pname, "src",
                                               "$mod_name.jl"))
                                push!(suggestions, mod_name)
                            end
                        end
                    end
                end
            end
        end
        ffunc = (mod,x)->(isdefined(mod, x) && isa(mod.(x), Module))
        comp_keywords = false
    end
    startpos == 0 && (pos = -1)
    dotpos <= startpos && (dotpos = startpos - 1)
    s = string[startpos:pos]
    comp_keywords && append!(suggestions, Base.REPLCompletions.complete_keyword(s))
    append!(suggestions, Base.REPLCompletions.complete_symbol(s, ffunc))
    return sort(unique(suggestions)), (dotpos+1):pos, true
end

include("examples.jl")

end # module
