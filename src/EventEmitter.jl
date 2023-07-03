module EventEmitter

# exports
export Listener, Event,
    addlisteners!, prependlisteners!, removelistener!, removealllisteners!,
    on!, once!, off!, emit!,
    eventnames, listenercount, getlisteners

# Types
struct Listener
    callback::Function
    once::Bool

    Listener(cb::Function, once::Bool=false) = new(cb, once)
    (l::Listener)(args...) = l.callback(args...)
end

struct Event
    name::Union{Symbol,AbstractString}
    listeners::Vector{Listener}

    function Event(n::Union{Symbol,AbstractString}, cbs::Function...; once::Bool=false)
        new(n, [Listener(cb, once) for cb ∈ cbs])
    end
    Event(n::Union{Symbol,AbstractString}, l::Listener...) = new(n, [l...])
    Event(n::Union{Symbol,AbstractString}) = new(n, [])
    (e::Event)(args::Any...) = emit!(e, args...)
end

# Functions
addlisteners!(e::Event, l::Listener...) = push!(e.listeners, l...)
function addlisteners!(e::Event, cbs::Function...; once::Bool)
    addlisteners!(e, (Listener(cb, once) for cb ∈ cbs)...)
end

prependlisteners!(e::Event, l::Listener...) = pushfirst!(e.listeners, l...)
function prependlisteners!(e::Event, cbs::Function...; once::Bool)
    prependlisteners!(e, (Listener(cb, once) for cb ∈ cbs)...)
end

# use negative index to count back from the last element
removelistener!(e::Event, i::Int) = popat!(e.listeners, i ≤ 0 ? i += length(e.listeners) : i)
removelistener!(e::Event) = pop!(e.listeners)

function removealllisteners!(e::Event; once::Bool)
    deleteat!(e.listeners, [l.once === once for l ∈ e.listeners])
end
removealllisteners!(e::Event) = empty!(e.listeners)

on!(e::Event, cbs::Function...) = addlisteners!(e, cbs...; once=false)
on!(cb::Function, e::Event) = addlisteners!(e, cb; once=false)

once!(e::Event, cbs::Function...) = addlisteners!(e, cbs...; once=true)
once!(cb::Function, e::Event) = addlisteners!(e, cb; once=true)

off!(e::Event, i::Int) = removelistener!(e, i)
off!(e::Event) = removelistener!(e)

function emit!(e::Event, args::Any...)
    results::Vector{Any} = []
    todelete::Vector{Bool} = []
    for l ∈ e.listeners
        try
            push!(results, l(args...))
            push!(todelete, l.once)
        catch exc
            push!(results, exc)
            push!(todelete, false)
        end
    end
    deleteat!(e.listeners, todelete)
    return results
end
emit!(cb::Function, e::Event, args::Any...) = cb(emit!(e, args...)...)
emit!(arr::AbstractArray{Event}, args::Any...) = [e() for e in arr]
emit!(arr::AbstractArray, args::Any...) = [isa(i, Event) ? i() : i for i in arr]
emit!(t::Tuple{Vararg{Event}}, args::Any...) = Tuple(e() for e in t)
emit!(t::Tuple, args::Any...) = Tuple(isa(i, Event) ? i() : i for i in t)

eventnames(arr::AbstractArray{Event}) = [e.name for e in arr]
eventnames(arr::AbstractArray) = [isa(i, Event) ? i.name : i for i in arr]

listenercount(e::Event; once::Bool) = length(filter((l::Listener) -> l.once === once, e.listeners))
listenercount(e::Event) = length(e.listeners)

getlisteners(e::Event; once::Bool) = filter((l::Listener) -> l.once === once, e.listeners)
getlisteners(e::Event) = e.listeners

end # module
