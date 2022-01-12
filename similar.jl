
function manys(c, n)
  d=[]
  for i in c
      if count(x->x.id == i.id, c) > n
        push!(d, i)
      end
  end
  unique(x->x.id,d)
end

function neighbours(g)
  mg = reduce(vcat, fanslike(g.id) for g in g)
  manys(mg, 10)
end