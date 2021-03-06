## context

## A context stores objects where named values are looked up.
mutable struct Context
    view ## of what? a Dict, Module, CompositeKind, DataFrame.parent.
    parent ## a context or nothing
    _cache::Dict
end
function Context(view, parent=nothing)
    d = Dict()
    d["."] = isa(view, AnIndex) ? view.value : view
    Context(view, parent, d)
end

## used by renderTokens
function ctx_push(ctx::Context, view)
    Context(view, ctx) ## add context as a parent
end

# we have some rules here
# * Each part of a dotted name should resolve only against its parent.
# * Any falsey value prior to the last part of the name should yield ''. 
# * The first part of a dotted name should resolve as any other name.
function lookup_dotted(ctx::Context, dotted)
    for key in split(dotted, ".")
        nctx = lookup(Context(ctx.view), key)
        falsy(nctx) && return nothing
        ctx = Context(nctx, ctx)
    end
    ctx.view
end

## Lookup value by key in the context
function lookup(ctx::Context, key)

    if haskey(ctx._cache, key)
        value = ctx._cache[key]
    else
        context = ctx
        value = nothing
        while value == nothing && context != nothing
            ## does name have a .?
            if occursin(r"\.", key)

                value = lookup_dotted(context, key)
                value != nothing && break
                
                ## do something with "."
                ## we use .[ind] to refer to value in parent of given index;
                m = match(r"^\.\[(.*)\]$", key)
                m == nothing && break
#                m == nothing && error("Not implemented. Can use Composite Kinds in the view.")

                idx = m.captures[1]
                vals = context.parent.view

                # this has limited support for indices: "end", or a number, but no
                # arithmetic, such as `end-1`.
                if isa(vals, Vector) # supports getindex(v, i)?
                   if idx == "end"
                       value = AnIndex(-1, vals[end])
                   else
                       ind = Base.parse(Int, idx) 
                       value = AnIndex(ind, vals[ind])
                   end
                    break
                end
            else
                ## strip leading, trailing whitespace in key
                value = lookup_in_view(context.view, stripWhitespace(key))
            end
            context = context.parent


        end

        ## cache
        ctx._cache[key] = value
    end

   
    return(value)
end

## Lookup value in an object by key
## This of course varies based on the view.
## we special case dataframes here, so that we don't have to assume package is loaded
function lookup_in_view(view, key)
    if is_dataframe(view)
        if occursin(r":", key)  key = key[2:end] end
        key = Symbol(key)
        out = nothing
        if haskey(view, key)
            out = view[1, key] ## first element only
        end
        return out
    else
        _lookup_in_view(view, key)
    end
end


function _lookup_in_view(view::Dict, key)
    ## is it a symbol?
    if occursin(r"^:", key)
        key = Symbol(key[2:end])
    end
    
    get(view, key, nothing)

end

function _lookup_in_view(view::Module, key)

    hasmatch = false
    re = Regex("^$key\$")
    for i in names(view, all=true)
        if occursin(re, string(i))
            hasmatch = true
            break
        end
    end

    out = nothing
    if hasmatch
        out = getfield(view, Symbol(key))  ## view.key
    end
    out

end

## Default is likely not great, but we use CompositeKind
function _lookup_in_view(view, key)
    nms = fieldnames(typeof(view))
    re = Regex(key)
    has_match = false
    for i in nms
        if occursin(Regex(key), string(i))
            has_match=true
            break
        end
    end

    out = nothing
    if has_match
        out = getfield(view, Symbol(key))  ## view.key
    end

    out
end
