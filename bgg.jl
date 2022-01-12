using HTTP
using EzXML

using Main.Revisable

@revisable mutable struct Game
    id::Int
    name
    own
    wish
    mechanics
    similar
    rating
end

Game(id, name=nothing) = Game(id, name, nothing, nothing, nothing, nothing)

function games() 
    g=usergames()
    mechanics!(g)
    recommend!(g)
    return g
end

function top100()
    r=HTTP.request("GET", "https://boardgamegeek.com/browse/boardgame/") 
    x = parsehtml(r.body)

    ids = Int[]
    for r in findall("//td[@class='collection_thumbnail']/a", x)
        m = match(r"\d+", r["href"])
        id = parse(Int, m.match)
        push!(ids, id)
    end
    return ids
end

function usergames(username = "plymth")
    r = HTTP.request("GET", "https://www.boardgamegeek.com/xmlapi/collection/$username")
    x = parsexml(r.body)

    games = Game[]
    for g in findall("//item", x)
        id = parse(Int, g["objectid"])
        s = findfirst("status", g)
        rating = parse(Float64, findfirst("stats/rating/average",g)["value"])
        rating += parse(Float64, findfirst("stats/rating/bayesaverage",g)["value"])
        rating /= 2
        g = Game(id, nothing, s["own"]=="1", s["wishlist"]=="1", nothing, nothing, rating)
        push!(games, g)
    end
    games
end

function mechanics!(games::Vector)
    i = join([g.id for g in games], ",")
    r=HTTP.request("GET", "https://www.boardgamegeek.com/xmlapi/boardgame/$i")
    x=parsexml(r.body)

    for g in games
        xgame = "//boardgame[@objectid='$(g.id)']"
        g.name = findfirst("$xgame/name[@primary='true']", root(x)).content
        g.mechanics = nodecontent.(findall("$xgame/boardgamemechanic", root(x)))
    end
    games
end

using Statistics
function getgames(ids)
    i = join(ids, ",")
    r=HTTP.request("GET", "https://www.boardgamegeek.com/xmlapi/boardgame/$i?stats=1")
    x=parsexml(r.body)
    gs = Game[]
    for id in ids
        xgame = "//boardgame[@objectid='$(id)']"
        name = findfirst("$xgame/name[@primary='true']", root(x)).content
        mechanics = nodecontent.(findall("$xgame/boardgamemechanic", root(x)))
        rating = nodecontent(findfirst("$xgame/statistics/ratings/bayesaverage", root(x)))
        rating = parse(Float64, rating)
        push!(gs, Game(id, name, nothing, nothing, mechanics, nothing, rating))
    end
    gs
end

function adjacency(g::Vector{<:Game}, mechs=.5)
    M = mechanics_match(g)
    M /= mean(M)
    S = fanslikedists(g)
    S /= mean(S)
    A = S * (1-mechs) + M * mechs 
    A + A'
end

mechanics_matchdist(x) = map(x -> x>0 ? 1/x : 0, mechanics_match(x))

mechanics_match(g::Vector{<:Game}) = mechanics_match([g.mechanics for g in g])

function mechanics_match(v)
    n = length(v)
    A = zeros(n,n)
    for i in 1:n
        for j in 1:n
            i == j && continue
            w = length(intersect(v[i], v[j])) / sqrt(length(v[i]) * length(v[j]))
            if w > 0
                A[i,j] = w
            end
        end
    end
    A = A ./ replace(sum(A, dims=1), 0=>1)
    A = A ./ replace(sum(A, dims=2), 0=>1)
    A
end

mechanics_hammingdist(g::Vector{Game}) = mechanics_hammingdist([g.mechanics for g in g])

function mechanics_hammingdist(v)
    n = length(v)
    A = zeros(n,n)
    for i in 1:n, j in 1:n
        i==j && continue
        A[i,j] = length(union(v[i], v[j])) - length(intersect(v[i], v[j]))
    end
    A
end

function distances(g::Vector{Game}, match = 1, hamming = 1, similar = 1)
    H = mechanics_hammingdist(g)
    M = mechanics_matchdist(g)
    S = fanslikedists(g)
    S = (S + S') / 2

    return match * M + hamming * H + similar * S
end


using NetworkLayout
using SimpleWeightedGraphs
using GLMakie
using GraphMakie
using Graphs



function plot(games=games(); seed=1)

    ed = -1  # scaling of distances
    er = :auto  # scaling of weights
    el = 2  # scaling of linewidth
    
    
    A = adjacency(games)
    dists = map(x->x>0 ? x .^ ed : 0, A)
    G = SimpleWeightedGraphs.SimpleWeightedGraph(dists)


    width=[w^(1/ed) for (i,j,w) in edges(G).iter]
    width = repeat(width, inner=2)
    width = (width / maximum(width)).^el * 2


    if er == :auto 
        layout = Stress(seed=seed)
    else
        weight = map(x->x>0 ? x^er : 0, A)
        #return weight, dists
        layout = Stress(weights = weight, seed=seed)
    end

    names = [name(g.name) for g in games]
    colors = [g.own == true ? :green : g.wish == true ? :blue : :black for g in games]
    colors = [(c, 0.3) for c in colors]

    sizes = [(g.rating/10)^4 * 40 + 5 for g in games]

    f, ax, p = graphplot(G, 
        node_size=sizes, 
        nlabels=names,
        nlabels_align=(:center, :center),
        nlabels_textsize=16,
        nlabels_distance=5,
        node_attr = (;alpha=0.1),
        node_color=colors, 
        edge_width=width,        
        layout = layout,
        figure = (resolution=(2480, 1748),))
    

    hidedecorations!(ax); hidespines!(ax)
    save("graph.png", f)
    @show loss(p,g)
    f, ax, p, layout, G
end

loss(p, g) = iterate(LayoutIterator(Stress(initialpos=p[:node_pos][]), g))[2][2]

function name(s::String)
    m = match(r"^([^:]+)", s)
    m[1]
end

function myplot(dists)
    pos = [Point{2}(rand(Float32, 2)) for i in 1:size(dists, 1)]
    G = SimpleWeightedGraph(dists)
    f,ax,p = graphplot(G, layout = x->pos)
    display(f)
    pos = p[:node_pos]

    L = LayoutIterator(Stress(), G)
    pp, st = iterate(L)

    for i in 1:10000
        try
            pp, st = iterate(L, st)
        catch
            break
        end
        pos[] = Point2{Float32}.(pp)
        reset_limits!(ax)
        sleep(0)
    end
end

function lazylayout2(G, layout = Stress())
    Base.Iterators.Stateful(LayoutIterator(layout, G))
    return ()->first(i)
end

