function fanslikedists(games::Vector; minweight = 1/2)
  A = spzeros(length(games), length(games))
  gameids = [game.id for game in games]
  for (i,g) in enumerate(games)
    sim = g.similar
    ismissing(sim) && continue
    weights = collect(range(1, minweight, length(sim)))
    for (s,w) in zip(sim, weights)
      j = findfirst(isequal(s), gameids)
      if !isnothing(j)
        A[i,j] += w
      end
    end
  end
  colexp = 1/2  # scale connections of popular games
  rowexp = 1/4  # scale connections of games with many recommendations
  A = A ./ (replace(sum(A, dims=1), 0=>1)).^colexp  ./ replace(sum(A, dims=2), 0=>1).^rowexp
  A
end


function adjacency(g::Vector{<:Game}, mechs=.5)
  M = mechanics_match(g)
  M /= mean(M)
  S = fanslikedists(g)
  S /= mean(S)
  A = S * (1-mechs) + M * mechs 
  A + A'
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
  A = A ./ replace(sum(A, dims=1), 0=>1)
  A = A ./ replace(sum(A, dims=2), 0=>1)
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
