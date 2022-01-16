@revisable mutable struct Game
    id::Int
    name
    own
    wish
    mechanics
    similar
    rating
    prating
end

Game(id, name=nothing) = Game(id, name, nothing, nothing, nothing, nothing, nothing, nothing)

function games(user = "plymth") 
    g=usergames(user)
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

function usergames(username = "plymth", narrow = false)
    r = HTTP.request("GET", "https://www.boardgamegeek.com/xmlapi/collection/$username?stats=1")
    x = parsexml(r.body)


    games = Game[]
    for g in findall("//item", x)
        #try 
            id = parse(Int, g["objectid"])
            name = nodecontent(findfirst("name", g))
            s = findfirst("status", g)

            rating = parse(Float64, findfirst("stats/rating/average",g)["value"])
            rating += parse(Float64, findfirst("stats/rating/bayesaverage",g)["value"])
            rating /= 2

            prating = try 
                parse(Float64, findfirst("stats/rating",g)["value"])
            catch
                nothing
            end

            g = Game(id, name)
            g.own = s["own"] == "1"
            g.wish = s["wishlist"]=="1"
            g.rating = rating
            g.prating = prating
            push!(games, g)
        #catch
            #@show "error $g"
        #end
    end
    games
end

function mechanics!(games::Vector)
    i = join([g.id for g in games], ",")
    r = try 
        HTTP.request("GET", "https://www.boardgamegeek.com/xmlapi/boardgame/$i")
    catch
        sleep(10)
        HTTP.request("GET", "https://www.boardgamegeek.com/xmlapi/boardgame/$i")
    end
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
      g = Game(id, name)
      g.mechanics = mechanics
      g.rating = rating
      push!(gs, g)
  end
  gs
end


recommend!(games::Vector{<:Game}) = foreach(games) do g
    recommend!(g)
    print(".")
end

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
    Game(id, name)
  end
end