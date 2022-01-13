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

function games(u="plymth") 
    g=usergames(u)
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


recommend!(games::Vector{<:Game}) = foreach(recommend!, games)

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
    println(name)
    Game(id, name, nothing, nothing, nothing, nothing, nothing)
  end
end