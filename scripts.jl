
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

function alobunko_games()
  gs = usergames("alobunko")
  gs = filter(g->!isnothing(g.prating), gs)
  recommend!(gs)
  mechanics!(gs)
  removeduplicates(gs)
end


function alobunko(gs = alobunko_games())
  f,ax,p, = plot(gs, edgeexp = 2, edgemult=3, seed=4)
  p[:node_color] = [(c, 0.8) for c in usercolors(gs)]
  ax.title = "Alobunko's ratings"
  f
end

function removeduplicates(gs)
  gs = copy(gs)
  short = [shortname(g.name) for g in gs]
  i = 1
  while i < length(short)
    match = findall(x->x == short[i], short)
    if length(match) > 1
      @show [g.name for g in gs[match]]
      shortest = argmin(length(g.name) for g in gs[match])
      gs[i] = gs[match[shortest]]
      deleteat!(gs, match[2:end])
      deleteat!(short, match[2:end])
    end
    i += 1
  end
  return gs
end


function waxbottle()
  gs = usergames("alobunko")
  gs = filter(g->g.own == true, gs)
  gs = removeduplicates(gs)
  recommend!(gs)
  mechanics!(gs)
  gs

  f,ax,p, = plot(gs, edgeexp = 2, edgemult=3, seed=4)
  p[:node_color] = [(c, 0.8) for c in usercolors(gs)]
  ax.title = "waxbottles's ratings"
  f
end

function wamsp_games()
  gs = usergames("wamsp")
  gs = filter(g->!isnothing(g.prating), gs)
  gs = filter(g->g.prating >= 8, gs)
  gs = removeduplicates(gs)
  recommend!(gs)
  mechanics!(gs)
  return gs
end

function wamsp(gs=wamsp_games())
  f,ax,p, = plot(gs, edgeexp = 2, edgemult=3, seed=4)
  p[:node_color] = [(c, 0.8) for c in usercolors(gs)]
  ax.title = "wamsp's top ratings (>=8)"
  f
end

function disposablesuperhero_games()
  gs = usergames("disposable.superhero")
  gs = filter(g-> (g.own && !isnothing(g.prating) && g.prating>=7) || g.wish , gs)
 # gs = filter(g->g.prating >= 8, gs)
  gs = removeduplicates(gs)
  @show length(gs)
  recommend!(gs)
  mechanics!(gs)
  return gs
end

function disposablesuperhero(gs=disposablesuperhero_games())
  f,ax,p, = plot(gs, edgeexp = 2, edgemult=3, seed=4)
  #p[:node_color] = [(c, 0.8) for c in usercolors(gs)]
  ax.title = "disposable.superhero's owned and wished (>=7)"
  #p[:node_color] = [(c, 0.8) for c in usercolors(gs)]
  f
end

function tommynomad_games()
  gs = usergames("tommynomad")
  gs = filter(g -> !isnothing(g.prating), gs)
  gs = removeduplicates(gs)
  gs = sort(gs, by = g -> g.prating)
  gs = gs[end:-1:end-99]
  recommend!(gs)
  mechanics!(gs)
  return gs
end

function tommynomad(gs = tommynomad_games())
  f,ax,p, = plot(gs,edgeexp = 2, edgemult = 2,mech=0.6)
  p[:node_color] = [(c, 0.8) for c in usercolors(gs)]
  ax.title = "tommynomad's top 100"
  f
end

function plymth()
  gs = usergames("plymth")
  recommend!(gs)
  mechanics!(gs)
  f,ax,p, = plot(gs)
  #p[:node_color] = [(c, 0.8) for c in usercolors(gs)]
  ax.title = "plymth's top 100"
  f
end

function top_games()
  gs = getgames(top100())
  gs = removeduplicates(gs)
  recommend!(gs)
  mechanics!(gs)
end

function top(gs = top_games())
  f, ax, p, = plot(gs, edgeexp=2.5, edgemult=8)
  ax.title = "BGG Top 100"
  p[:node_color] = [(c, 0.8) for c in usercolors(gs)]
  p[:edge_width] = min.(p[:edge_width][], 1.2)
  save("top100.png", f)
  f
end

function userprofile(user="plymth"; kwargs...)
  gs = usergames(user)
  gs = removeduplicates(gs)
  recommend!(gs)
  mechanics!(gs)
  f,ax,p, = plot(gs; kwargs...)
  #p[:node_color] = [(c, 0.8) for c in usercolors(gs)]
  ax.title = "$user's collection"
  save("$user.png", f)
  f |> display
  f, ax, p, gs
end







function users()

  "alobunko"
  "waxbottle"
  "wamsp"
  "disposable.superhero"
end
