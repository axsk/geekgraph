using HTTP
using EzXML

mutable struct Game
    id
    name
    own
    wish
    mechanics
end


function usergames(username = "plymth")
    r = HTTP.request("GET", "https://www.boardgamegeek.com/xmlapi/collection/$username")
    x = parsexml(r.body)

    games = Game[]
    for g in findall("//item", x)
        id = g["objectid"]
        s = findfirst("status", g)
        g = Game(id, nothing, s["own"]=="1", s["wishlist"]=="1", nothing)
        push!(games, g)
    end
    games
end

function mechanics(games::Vector)

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

function adjacency(g::Vector{Game})
    adjacency([g.mechanics for g in g])
end

function adjacency(v)
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

using NetworkLayout
using SimpleWeightedGraphs
using GLMakie
using GraphMakie
using Graphs



function plot(games=mechanics(usergames()))

    ed = -1
    #er = 2
    el = 4
    
    
    A = adjacency(games)
    dists = map(x->x>0 ? x .^ ed : 0, A)
    G = SimpleWeightedGraphs.SimpleWeightedGraph(dists)


    width=[w^(1/ed) for (i,j,w) in edges(G).iter]
    width = repeat(width, inner=2)
    width = (width / maximum(width)).^el * 0.5


    #if er == :auto 
        layout = Stress()
    #else
    #    weight = map(x->x>0 ? x^er : 0.1^er, A)
    #    layout = Stress(weights = weight)
    #end

    names = [g.name for g in games]
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
        layout = layout)
    

    hidedecorations!(ax); hidespines!(ax)
    f#, ax, p, A, G, layout
end