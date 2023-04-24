function extractgames(str) # e.g. used for manual geekbuddie toplist copy
    ids = [parse(Int,m.captures[1]) for m in eachmatch(r"\/(\d*)\/", str)]
    gs = getgames(ids)
end


#=
df = DataFrame(gs)
df[!,:rank] = 1:600
df[!,:arank] = invperm(sortperm(-df[!,:rating]))

select!(df, :rank, :name, :category, :mechanics, :weight, :owners, :rating, :brating, :usersrated, :playtime,:)
score = mapreduce(x->invperm(sortperm(df[!, x])), +, [:playtime, :weight, :rank, :arank,])

