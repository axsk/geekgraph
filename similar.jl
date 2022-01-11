using EzXML
using HTTP
using SparseArrays
using JSON
#=
mutable struct Game2
  id
  name
  wish
  own
  mechanics
  similar
end

Game = Game2
=#

recommend!(games::Vector{Game}) = foreach(recommend!, games)

function recommend!(game::Game) 
  recs = fanslike(game.id)
  game.similar = [r.id for r in recs]
end

GLOOMHAVEN = 174430

function fanslike(id::Int=GLOOMHAVEN)
  r = HTTP.get("https://api.geekdo.com/api/geekitem/recs?&objectid=$id")
  #EzXML.parsexml(r.body)
  s = String(r.body)
  j = JSON.parse(s)
  games = j["recs"]
  map(games) do game
    game = game["item"]
    id = parse(Int, game["id"])
    name = game["name"]
    Game(id, name, nothing, nothing, nothing, missing)
  end
end

function fanslikedists(games::Vector; minweight = 1/2)
  A = spzeros(length(games), length(games))
  gameids = [game.id for game in games]
  for (i,g) in enumerate(games)
    sim = g.similar
    weights = collect(range(1, minweight, length(sim)))
    for (s,w) in zip(sim, weights)
      j = findfirst(isequal(s), gameids)
      if !isnothing(j)
        A[i,j] += w
      end
    end
  end
  A
end