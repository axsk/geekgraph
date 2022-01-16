

function plot(games=games(); seed=1)
    #ed = -1  # scaling of distances
    er = -2 #-1.2  # scaling of weights
    el = 3  # scaling of linewidth
    linemult = 1.5
    
    A = adjacency(games)
    #dists = map(x->x>0 ? x .^ ed : 0, A)
    G = SimpleWeightedGraphs.SimpleWeightedGraph(A)

    width=[w^(-1) for (i,j,w) in edges(G).iter]
    width = repeat(width, inner=2)
    width = (width / maximum(width)).^el * linemult

    if er == :auto 
        layout = Stress(seed=seed, iterations=1_000_000_000)
    else
        B = NetworkLayout.pairwise_distance(A, Float64)
        weight = map(x->x>0 ? x^er : 0, B)
        #return weight, dists
        layout = Stress(weights = weight, seed=seed, iterations=1_000_000_000)
    end

    names = [name(g.name) for g in games]
    colors = [g.own == true ? :green : g.wish == true ? :blue : :black for g in games]
    #colors = usercolors(games)
    colors = [(c, 0.3) for c in colors]
    

    layout = Base.Iterators.Stateful(LayoutIterator(layout, G))
    point = popfirst!(layout)

    sizes = [(g.rating/10)^4 * 40 + 5 for g in games]

    f, ax, p = graphplot(G, 
        node_size=sizes, 
        nlabels=names,
        nlabels_align=(:center, :bottom),
        nlabels_textsize=14,
        nlabels_distance=5,
        node_attr = (;alpha=0.1),
        node_color=colors, 
        edge_width=width,        
        layout = (G)->point,
        figure = (resolution=(2480, 1748),))
    
    hidedecorations!(ax); hidespines!(ax)
    display(f)
    #sleep(2)
    for point in layout
        p[:node_pos][] = Point2{Float32}.(point)
        yield()
        #sleep(0.1)
    end

    #save("graph.png", f)
    @show loss(p,G)
    f, ax, p, layout, G
end

using ColorSchemes
function usercolors(gs)
    rating = [g.prating for g in gs]
    min = minimum(filter(!isnothing, rating))
    max = maximum(filter(!isnothing, rating))

    colors = ColorSchemes.roma

    map(rating) do r
        isnothing(r) && return :grey
        get(colors, (r - min) / (max - min))
    end
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


