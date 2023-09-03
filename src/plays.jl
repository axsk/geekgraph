import HTTP: HTTP
import EzXML: EzXML

# fetch the logged play's times
function playlengths(gameid::Integer; pages=5)
    lengths = Int[]
    for page in 1:pages
        r = HTTP.request("GET", "https://boardgamegeek.com/xmlapi2/plays?id=$gameid&page=$page")
        x = EzXML.parsexml(r.body)

        for play in findall("//play", x)
            length = parse(Int, play["length"])
            incomplete = play["incomplete"] == 1
            incomplete && continue
            length == 0 && continue
            push!(lengths, length)
        end
    end

    return lengths
end

using StatsBase: median



function length18xx(pages=1;
    games=Dict(12750 => "1860",
        63170 => "1817",
        421 => "1830",
        282435 => "1882",
        66837 => "1862",
        23540 => "1889",
        17405 => "1846",
        359211 => "1871",
        3097 => "1849",
        193867 => "1822"),
    ls=playlengths.(collect(keys(games)), pages=pages))

    ls = map(values(games), ls) do name, l

        #@show sum(l.>2*median(l))
        l = filter(l) do mins
            mins < 2 * median(l)
        end
        return (name, median(l), mean(l), std(l), length(l), quantile(l, [0.3, 0.7]))
    end

    sort(ls, by=x -> x[3])
end
