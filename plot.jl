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
    @show loss(p,G)
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

