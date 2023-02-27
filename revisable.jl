module Revisable
  using MacroTools

  export @revisable

  macro revisable(ex)
    @capture(ex, (mutable struct T_ fields__ end) | (struct T_ fields__ end))
    TN = gensym(T)
    quote
      abstract type $(T) end
      mutable struct $(esc(TN)) <: $(esc(T))
        $(fields...)
      end
      $(esc(T))(x...) = $(esc(TN))(x...)
    end
  end
end

using .Revisable
#
#using Main.R
#
#@revisable struct Game
#  id
#  name
#end
#
#gm(g::Game) = g.id