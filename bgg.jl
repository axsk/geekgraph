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
end

Game(id, name=nothing) = Game(id, name, nothing, nothing, nothing, nothing)

function games() 
    g=usergames()
    mechanics!(g)
    recommend!(g)
    return g
end

function usergames(username = "plymth")
    r = HTTP.request("GET", "https://www.boardgamegeek.com/xmlapi/collection/$username")
    x = parsexml(r.body)

    games = Game[]
    for g in findall("//item", x)
        id = parse(Int, g["objectid"])
        s = findfirst("status", g)
        g = Game(id, nothing, s["own"]=="1", s["wishlist"]=="1", nothing, nothing)
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

function adjacency(g::Vector{Game}, mechs=.5)
    M = mechanics_match(g)
    S = fanslikedists(g)
    (S + S') / 2 * (1-mechs) + mechs * M
end

mechanics_matchdist(x) = map(x -> x>0 ? 1/x : 0, mechanics_match(x))

mechanics_match(g::Vector{Game}) = mechanics_match([g.mechanics for g in g])

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



function plot(games=games())

    ed = -1  # scaling of distances
    er = :auto  # scaling of weights
    el = 2  # scaling of linewidth
    
    
    A = adjacency(games)
    dists = map(x->x>0 ? x .^ ed : 0, A)
    G = SimpleWeightedGraphs.SimpleWeightedGraph(dists)


    width=[w^(1/ed) for (i,j,w) in edges(G).iter]
    width = repeat(width, inner=2)
    width = (width / maximum(width)).^el * 0.5


    if er == :auto 
        layout = Stress()
    else
        weight = map(x->x>0 ? x^er : 0, A)
        #return weight, dists
        layout = Stress(weights = weight)
    end

    names = [name(g.name) for g in games]
    colors = [g.own ? :green : g.wish ? :blue : :black for g in games]
    colors = [(c, 0.3) for c in colors]

    f, ax, p = graphplot(G, 
        node_size=20, 
        nlabels=names,
        nlabels_align=(:center, :center),
        nlabels_textsize=10,
        nlabels_distance=5,
        node_attr = (;alpha=0.1),
        node_color=colors, 
        edge_width=width,        
        layout = layout,
        figure = (resolution=(1920,1080),))
    

    hidedecorations!(ax); hidespines!(ax)
    save("graph.png", f)
    f#, ax, p, A, G, layout
end

function name(s::String)
    m = match(r"^([^:]+)", s)
    m[1]
end