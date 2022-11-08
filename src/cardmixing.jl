using Distributions

hand(n=52) = collect(1:n)

function riffle(cards=hand(); keepbias=1)
    n = length(cards)
    cut = floor(Int, n/2)

    stacks = [cards[1:cut], cards[cut+1:end]]
    
    shuffled = zeros(Int, n)
    pick = rand([1,2])
    for pos in 1:n
        l = length(stacks[pick]) / (length(stacks[1]) + length(stacks[2]))
        pick = rand() / keepbias < l ? pick : 3-pick
        length(stacks[pick]) == 0 && (pick=3-pick)


        shuffled[pos] = popfirst!(stacks[pick])
    end
    return shuffled
end

function sequencelengths(cards)
    switch = cards[2:end] .!= (cards[1:end-1] .+ 1)
    diff([0;findall(switch);length(cards)])
end

function rifflestats(n=1000)
    s = sequencelengths(vcat((riffle() for i in 1:n)...))
    mean(s), std(s)
end

struct Riffle end
struct Cut
    pos::Float64
end
struct Overhand
    folds::Int
end

(::Riffle)(cards) = riffle(cards)
(s::Cut)(cards) = cut(cards, s.pos)
(s::Overhand)(cards) = overhand(cards, s.folds)



function cut(cards, pos=1/3; stdfact=1/3)
    pos = pos + randn() * pos * stdfact
    n = length(cards)
    
    cut = floor(Int, pos*n)
    cut = min(cut, n-2)
    cut = max(cut, 1)
    shuffled = copy(cards)
    shuffled[1:cut] = cards[end-cut+1:end]
    shuffled[cut+1:end] = cards[1:end-cut]
    shuffled
end

function overhand(cards, folds = 7; stdfact = .5)
    n = length(cards)
    meansize = n / folds
    cards = reverse(cards)  # reverse to take from the back
    shuffled = copy(cards)
    start = 1
    while start <= n
        #len = rand(foldrange)
        len = round(Int,rand(Normal(meansize, stdfact * meansize)))
        len < 0 && (len=0)
        upto = start + len
        if upto > n
            upto = n
        end
        @views shuffled[start:upto] = cards[start:upto]  # reverse again to reconstruct order
        @views reverse!(shuffled[start:upto])
        start += len + 1
    end
    return shuffled
end




function deckentropy(decks)
    
    pos = zero(decks[1])
    dists = zero(decks[1])
    for deck in decks 
        n = length(deck)
        i = findfirst(deck .== 1)
        j = findfirst(deck .== 2)
        pos[i] +=1 
        dists[(i-j+n)%n] += 1 
    end
    #entropy(pos)
    entropy(pos) + entropy(dists)
end

function entropy(counts::Vector{<:Number})
    p = counts ./ sum(counts)
    h = - sum(log(pi) * pi for pi in p if pi > 0)
end

function evaluate(protocol; n=1000)
    decks = []
    for i in 1:n
        cards = hand()
        for p in protocol
            cards = p(cards)
        end
        push!(decks, cards)
    end
    deckentropy(decks) / (-2 * log(1/length(decks[1])))
end

function plot_overhand(;folds=1:20, repeats=1:20, n=2_000)
    oh = [(i,j) for i in folds, j in repeats]
    hoh = map(oh) do (i,j)
        evaluate(repeat([Overhand(i)],j), n=n)
        end
    contour(hoh, fill=true, clim=((0,1)))
    ylims!((0,maximum(folds)))
    zlims!((0,1))
    for cost in [10, 20, 30, 40,50]
        plot!(repeats, x->cost/x, label=nothing, color=:black)
    end
    xlabel!("number of repeats")
    ylabel!("number of folds")
    plot!()
end

