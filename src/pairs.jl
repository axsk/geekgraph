function compairpair(c1, c2)
    int = intersect(keys.([c1, c2])...) |> collect
    deltas = map(int) do user
        d = commentrating(c1[user]) - commentrating(c2[user])
        w = log2(2 + length(commenttext(c1[user])) + length(commenttext(c2[user])))
        #println(w)
        d *= w
        return d
    end
    return deltas
end

# since we switched to (rating, txt) tuples inbetween scraping
commentrating(c::Number) = c
commentrating(c::Tuple) = c[1]
commenttext(c::Number) = ""
commenttext(c::Tuple) = c[2]
using LinearAlgebra

# canstay=false && mode=:prob  ==  mode=:rate     (with weight=:none)

function compairmatrixsig(cd::AbstractDict; scale=1, weight=:log, mode=:rate, canstay=true)
    k = sort(collect(keys(cd)))
    n = length(k)
    A = zeros(n,n)
    Threads.@threads for i in 1:n
        for j in i+1:n
            comparisons = compairpair(cd[k[i]], cd[k[j]])
            #@show length(comparisons)
            if weight == :log
                w = log(length(comparisons)) / length(comparisons) # log
            elseif weight == :full
                w = 1 # weight with counts
            else
                w = 1/length(comparisons) # dont weight with counts
            end
            for c in comparisons
                s = 1 / (1+exp(-scale*c))
                A[j,i] += w * s
                A[i,j] += w * (1-s)

                A[i,i] += w * s     # probability to stay
                A[j,j] += w * (1-s)
            end
        end
    end

    if mode == :rate
        A[diagind(A)] .= 0
        A[diagind(A)] .-= sum(A, dims=2)
    else
        !canstay && (A[diagind(A)] .= 0)
        A ./= sum(A, dims=2) # P Matrix
    end



    return A
end

function compair(cd::AbstractDict; kwargs...)
    A = compairmatrixsig(cd; kwargs...)
    v = eigen(A').vectors[:, end] .|> abs
    p = sortperm(v, rev=true)
    k = sort(collect(keys(cd)))
    k[p], v[p] ./ sum(v), A
end

function compair(games::Vector{<:Game}, comments::AbstractDict=comments(games); kwargs...)

    k, v, A = compair(comments; kwargs...)
    gs = [games[findfirst(x->x.id == k, games)] for k in k]
    gs, v, A, comments
end

function bggcompair(gs,v,a,comments)
    ar = @show invperm(sortperm(@show [-g.rating for g in gs]))
    br = invperm(sortperm([-g.dict["brating"] for g in gs]))
    println("[c]")
    for i in 1:length(gs)
        g = gs[i]
        r = v[i]
        db = br[i] - i
        db > 0 && (db = "+$db")
        da = ar[i] - i
        da > 0 && (da = "+$da")
        ranks = rpad("$(rpad("$i.",3," ")) $(lpad("$db", 3, " "))/$(lpad("$da",3," "))", 12, " ")
        println("$ranks [thing=$(g.id)][/thing] ($(round(r*100, digits=1))%) ")
    end
    println("[/c]")
end

function bggreport(games, comparison=compair(games); linked=false)
    k,v,_ = comparison
    for i in 1:length(k)
        id = k[i]
        rank = findfirst(x->x.id == id, games)
        delta = rank - i
        if delta > 0
            delta = "+$delta"
        end
        if linked
            game = "[thing=$(games[rank].id)][/thing]"
        else
            game = games[rank].name
        end

        println("$(lpad(i, 3, " ")). ($(lpad(delta, 3, " "))) $(game)")
    end
end

findgame(games, id) = games[findfirst(x->x.id == id, games)]

function comments(games::Vector{<:Game})
    comm = Dict()
try
    for g in games
        println("Fetching comments for $(g.name)")
        comm[g.id] = comments(g.id)
    end
catch e
    @show e
end
    return comm
end

function bggpairs(str::String;kwargs...)
    ids = [parse(Int, m.match[2:end]) for m in eachmatch(r"=(\d)+", str)]
    bggpairs(ids;kwargs...)
end

function bggpairs(ids::AbstractArray{<:Integer};kwargs...)
    gs = getgames(ids)
    cs = comments(gs)
    c = compair(gs, cs;kwargs...)
    bggcompair(c...)
    return nothing
end
