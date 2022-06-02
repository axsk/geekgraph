@revisable mutable struct Game
    id::Int
    name
    own
    wish
    mechanics
    similar
    rating
    prating
    playercounts
    playtime
    weight
    description
    dict
end

Game(id, name=nothing) = Game(id, name, nothing, nothing, nothing, nothing, nothing, nothing, nothing, nothing, nothing, nothing, Dict())

function games(user = "plymth") 
    g=usergames(user)
    mechanics!(g)
    recommend!(g)
    return g
end

function top100(url = "https://boardgamegeek.com/browse/boardgame/")
    r=HTTP.request("GET", url) 
    x = parsehtml(r.body)

    ids = Int[]
    for r in findall("//td[@class='collection_thumbnail']/a", x)
        m = match(r"\d+", r["href"])
        id = parse(Int, m.match)
        push!(ids, id)
    end
    return ids
end

wargames() = top100("https://boardgamegeek.com/wargames/browse/boardgame")

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
  @time r=HTTP.request("GET", "https://www.boardgamegeek.com/xmlapi/boardgame/$i?stats=1")
  x=parsexml(r.body)
  gs = Game[]
  for id in ids
      xgame = "//boardgame[@objectid='$(id)']"
      name = findfirst("$xgame/name[@primary='true']", root(x)).content

      g = Game(id, name)

      getproperty(prop) = nodecontent.(findall("$xgame/$prop", root(x)))
          
      g.rating =  parse(Float64, getproperty("statistics/ratings/average")[1])
      g.weight = parse(Float64, getproperty("statistics/ratings/averageweight")[1])
      g.dict["usersrated"] = parse(Int, getproperty("statistics/ratings/usersrated")[1])
      g.dict["brating"] = parse(Float64, getproperty("statistics/ratings/bayesaverage")[1])
      g.dict["stddev"] = parse(Float64, getproperty("statistics/ratings/stddev")[1])
      g.dict["subdomain"] = getproperty("boardgamesubdomain")

         
      g.mechanics = getproperty("boardgamemechanic")
      g.description = getproperty("description")[1]

      g.dict["designer"] = nodecontent(findfirst("$xgame/boardgamedesigner", root(x)))
      g.dict["year"] =  parse(Int, nodecontent(findfirst("$xgame/yearpublished", root(x))))
      g.dict["thumbnail"] = nodecontent(findfirst("$xgame/image", root(x)))
      g.dict["category"] = getproperty("boardgamecategory")
      g.dict["family"] = getproperty("boardgamefamily")
      g.dict["owners"] = parse(Int, getproperty("statistics/ratings/owned")[1])
      
      g.playercounts = playercounts(x, xgame)
      g.playtime = playtime(x, id)
      push!(gs, g)
  end
  gs
end

function playercounts(x::EzXML.Document, xgame)
    res = findall("$xgame/poll[@name='suggested_numplayers']/results", x)
    counts = Dict()
    for rs in res
        n = rs["numplayers"]
        v = [parse(Int, r["numvotes"]) for r in elements(rs)]
        counts[n] = v
    end
    return counts
end

function playtime(x, id)
    res = findfirst("//boardgame[@objectid='$(id)']/playingtime", x)
    t = parse(Int, nodecontent(res))
    return t
end

function recommend!(games::Vector{<:Game})
    println("getting recommendations")
    foreach(games) do g
        recommend!(g)
        print(".")
    end
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

using Dates

function plays(id)
    sleep(3)
    r = HTTP.get("https://boardgamegeek.com/xmlapi2/plays?id=$id")
    x = parsexml(r.body)
    plays = root(x)
    total = parse(Int, plays["total"])
    allplays = collect(eachelement(plays))
    playdays = (today() - Date(allplays[end]["date"])).value
    playsperyear = 365 * length(allplays) / playdays
    return total, playsperyear
end

function playstats!(g)
    id = g.id
    total, ppy = plays(id)
    g.dict["plays"] = total
    g.dict["playrate"] = ppy / g.dict["owners"]
    @show g.name, g.dict["playrate"]
end

function playstats!(games::Vector) 
    foreach(playstats!, games)
    return games
end

Int(s::String) = parse(Int, s)

function parselist(id = 292940)
    r = HTTP.get("https://boardgamegeek.com/xmlapi/geeklist/292940")
    x = parsexml(r.body)
    ids = []
    for n in findall("//item", root(x))
        
        push!(ids, Int(n["objectid"]))
        text = nodecontent(findfirst("body", n))
        for m in eachmatch(r"thing=(.*?)]", text)
           push!(ids, Int(String(m.captures[1])))
        end

    end
    ids

end

wargamelist() = playstats!(getgames(unique(parselist())))

import Base.Dict
function Dict(g::Game)
    #d = copy(g.dict)
    d = Dict()
    for (k,v) in g.dict
        d[Symbol(k)] = v
    end
    d[:id] = g.id
    d[:mechanics] = g.mechanics
    d[:desc] = g.description
    d[:name] = g.name
    d[:recplayers] = g.playercounts
    d[:playtime] = g.playtime
    d[:rating] = g.rating
    d[:similar] = g.similar
    d[:weight] = g.weight
    d[:playerwish] = g.wish
    d[:playerrating] = g.prating
    d[:playerown] = g.own
    return d
end

#DataFrame(t::Vector{Game}) = DataFrame(permutedims(hcat([collect(values(Dict(t))) for t in t]...)), keys(Dict(t[1])) |> collect)
using DataFrames
import DataFrames.DataFrame
function DataFrame(t::Vector{Game})
    df = DataFrames.DataFrame()
    for g in t
        push!(df, Dict(g), cols=:union)
    end
    #df = df[!, Cols(:id, :year, :name, :rating, :weight, :playrate, :plays, :playtime, :owners, :category, :family, :)]
    #df[!, :timeyear] = df[!, :playrate] .* df[!, :playtime]
    df
end

allgameids() = union([g.id for g in usergames()], wargames(), parselist(), top100())

function allgames()
    gs = getgames(allgameids())
    gs = playstats!(gs)
    DataFrame(gs)
end
