function graph(g; seed=1, d=-1/2, w=1, m=.3, a=1/2, legacy=false, offset=0, kwargs...)
  
  # legacy is kindof reconstructed with d=-1, m=.5, w=2
  if legacy
    A = adjacency(g, m)
    G = SimpleWeightedGraphs.SimpleWeightedGraph(A)
    B = NetworkLayout.pairwise_distance(A, Float64)
    weights = map(x->x>0 ? x^(-2) : 0, B)
    layout = Stress(weights = weights, seed=seed, iterations=1_000_000_000)
  else
    A = similarity(g, m, a)
    D = replace(A .^ d, Inf=>0)
    D = NetworkLayout.pairwise_distance(D, Float64)
    G = SimpleWeightedGraphs.SimpleWeightedGraph(D)
    weights = D .^ (1/d * w) .+ offset
    layout = Stress(weights = weights, seed=seed, reltols=10e-7,
      abstolx=10e-7, iterations=1_000_000_000)
  end

  width = [weights[i,j] - offset for (i,j,w) in edges(G).iter]
  return G, layout, width
end

function pmi_graph(gs; m=.3, a=0)
  A = similarity(gs, m, 0) .+ 0.1
  A += A'
  A ./= sum(A)  # probabilistic
  X = sum(A, dims=1)
  Y = sum(A, dims=2)
  pmi = log.(A ./ (X .* Y))
  npmi = replace(pmi ./ -log.(A), NaN => 0)
  D = replace(exp.(-pmi), Inf => 0)

  G = SimpleWeightedGraph(LinearAlgebra.Symmetric(D))
  weights = (npmi) .^ 1 .+ 0.1
  layout = Stress(weights = weights)
  width = [weights[i,j] for (i,j,w) in edges(G).iter]
  return G, layout, width
end

function similarity(g, m=.2, a=0)
  #postprocess(fanvotes(g)) + postprocess(mechanics_match(g))
  pp = postprocess
  F = pp(fanvotes(g), a)
  M = pp(mechanics_match(g),a)
  F * (1-m) + m* M
end

function fanvotes(games::Vector; minweight = 1/2)
  A = spzeros(length(games), length(games))
  gameids = [game.id for game in games]
  for (i,g) in enumerate(games)
    sim = g.similar
    isnothing(sim) && continue

    halfweight = 8
    rate = log(.5) / (halfweight - 1)
    weights = exp.( rate * (0:length(sim)-1))

    if length(sim) > 1
      weights = collect(range(1., minweight, length(sim)))
    else
      weights = [1.]
    end

    for (s,w) in zip(sim, weights)
      j = findfirst(isequal(s), gameids)
      if !isnothing(j)
        A[i,j] += w
      end
    end
  end
  return A
end

function postprocess(A, a=1/2, b=a)
  rows = (replace(sum(A, dims=1), 0=>1)).^a
  cols = (replace(sum(A, dims=2), 0=>1)).^b
  A = A ./ (rows .* cols)
  A = (A + A') / 2
end

function adjacency(g::Vector{<:Game}, m=.5)
  M = mechanics_match(g)
  M = M ./ replace(sum(M, dims=1).^(1/2), 0=>1)
  M = M ./ replace(sum(M, dims=2).^(1/4), 0=>1)
  #M = map(x->x>.5 ? x : 0, M)

  M /= mean(M)
  S = fanvotes(g)

  # scaling from old fanslikedists
  colexp = 1/2.  #/2  # scale connections of popular games
  rowexp = 1/4.  #/4 #1/4  # scale connections of games with many recommendations
  S = S ./ (replace(sum(S, dims=1), 0=>1)).^colexp  ./ replace(sum(S, dims=2), 0=>1).^rowexp

  S /= mean(S)

  A = S * (1-m) + M * m
  fixzeros!(A)
  A = A + A'
  spinv(A)
  ##=#
  #M = normalize(mechanics_hammingdist(g))
  #M = (normalize(mechanics_match(g)))
  #S = (normalize(fanslikedists(g)))
  #spinv(M * m + S * (1-m))
end

spinv(A) = map(x -> x>0 ? 1/x : 0., A)
normalize(A) = (A + A') / mean(filter(x->x>0, A))
function fixzeros!(A)
  m = minimum(filter(x->x>0, A)) / 10
  for i in 1:size(A,1)
    if sum(A[:,i]) == 0
      A[:,i] .= m
    end
  end
end

mechanics_matchdist(x) = map(x -> x>0 ? 1/x : 0, mechanics_match(x))

mechanics_match(g::Vector{<:Game}) = mechanics_match([g.mechanics for g in g])

function mechanics_match(v)
  n = length(v)
  A = zeros(n,n)
  for i in 1:n
      for j in 1:n
          i == j && continue
          w = length(intersect(v[i], v[j])) / sqrt(length(v[i]) * length(v[j]))
          if w > 0
              A[i,j] = w
          end
      end
  end
  A
end

mechanics_hammingdist(g::Vector{Game}) = mechanics_hammingdist([g.mechanics for g in g])

function mechanics_hammingdist(v)
  n = length(v)
  A = zeros(n,n)
  for i in 1:n, j in 1:n
      i==j && continue
      A[i,j] = length(union(v[i], v[j])) - length(intersect(v[i], v[j]))
  end
  A
end

function distances(g::Vector{Game}, match = 1, hamming = 1, similar = 1)
  H = mechanics_hammingdist(g)
  M = mechanics_matchdist(g)
  S = fanslikedists(g)
  S = (S + S') / 2

  return match * M + hamming * H + similar * S
end
