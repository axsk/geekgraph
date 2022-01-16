
function olafslomp_games()
  go = usergames("Olafslomp")
  gt = getgames(top100())
  gs = map(gt) do g
    i = findfirst(x->x.id == g.id, go)
    if isnothing(i) 
      return g 
    else
      return go[i]
    end
  end

  recommend!(gs)
  mechanics!(gs)
  gs
end

function olafslomp(gs = olafslomp_games())
  f,ax,p, = plot(gs)
  p[:node_color] = [(c, 0.8) for c in usercolors(gs)]
  ax.title = "Top 100 rated by Olafslomp"
  f
end