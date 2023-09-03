using LMDB
if !isdefined(Main, :cache)
    global cache = LMDBDict{UInt64, Vector{UInt8}}("db")
    LMDB.setindex!(cache.env, 10*10_485_760 , :MapSize) #100mb
end

# cached http request
function myrequest(str)
    r = get!(cache, hash(str)) do
        @info("Requesting HTTP site...")
        HTTP.request("GET", str).body
    end
    length(r) < 300 && delete!(cache, hash(str))
    return r
end
