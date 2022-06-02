# GOAL: Given ratings, years etc, factor out correlations to obtain unbiased data
# metagoal: formulate/learn about the problem in general

using LsqFit

expmodel(x, p) = p[1] .+ exp.(p[2] * (x.-p[3]))

function exponentialfit(x, y)
    p0 = [0., 1, 2000]
    fit = curve_fit(expmodel, x, y, p0)
    p = coef(fit)
end


function factoroutexp(x, y)
    @show p = exponentialfit(x, y)
    y = y - expmodel(x, p) .+ p[1]
end

function modstatistics(d)
    d = copy(d)
    d[:, :rating_mod_year] = factoroutexp(d[:, :year], d[:, :rating])
    d[:,:playrate_mod_year] = exp.(factoroutexp(d[:,:year], log.(d[:,:playrate])))
    d
end

filteryear(d, year=1980) = filter(d->d[:year] >= year, d)

filtercat(d, category="Wargames") = filter(d->in(category, d[:subdomain]), d)