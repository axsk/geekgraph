function plot(games=games(); seed=1, parms...)


    G, layout, w = graph(games; parms...)

    names = [name(g.name) for g in games]
    colors = [g.own == true ? :green : g.wish == true ? :blue : :black for g in games]
    colors = [(c, 0.3) for c in colors]

    layout = Base.Iterators.Stateful(LayoutIterator(layout, G))
    point = popfirst!(layout)

    sizes = [(g.rating/10)^4 * 40 + 5 for g in games]

    f, ax, p = graphplot(G, 
        node_size=sizes, 
        nlabels=names,
        nlabels_align=(:center, :bottom),
        nlabels_textsize=sqrt.(sizes)*4,
        nlabels_distance=5,
        node_attr = (;alpha=0.1),
        node_color=colors, 
        edge_width=w,        
        layout = (G)->point,
        figure = (resolution=(2480, 1748),))
    
    hidedecorations!(ax); hidespines!(ax)
    display(f)
    #sleep(2)
    
    for (i,pn) in enumerate(layout)
        point = pn
        i%10 == 0 && (p[:node_pos][] = Point2{Float32}.(point))
        yield()
        #sleep(0.1)
    end
    
    #save("graph.png", f)
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



