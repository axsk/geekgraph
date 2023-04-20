function playercounts!(gs::Vector{Game})
    BESTFACTOR = 2
    for g in gs
        suitable = zeros(8)
        for k in 1:length(suitable)
            v = get(g.playercounts, "$k", nothing)
            if !isnothing(v)
                v = v ./ sum(v)
                best, rec, no = v
                score = BESTFACTOR * best + rec
                suitable[k] = score
            else
                suitable[k] = 0
            end
        
        end
        g.dict["playerscore"] = suitable
    end
end

using CSV
function exportplayercounts(gs)
    playercounts!(gs)
    df = DataFrame(gs)
    X = hcat(df[!, :id], reduce(hcat,df[!, :playerscore])')
    CSV.write("playercounts.csv", Tables.table(X))
end