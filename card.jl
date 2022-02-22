function cards()
  gs=getgames([g.id for g in usergames("plymth") if g.own])
  savecard(g)
  gs
end

function card(g)

  title = g.name
  playtime = g.playtime
  designer = g.dict["designer"]
  year = g.dict["year"]
  description = g.description
  rating = round(g.rating, digits=1)
  weight = round(g.weight, digits=1)
  thumb = g.dict["thumbnail"]
  
  if length(description) > 300
    description = description[1:300] * " [...]"
  end

  playercounts = ""
  for k in sort(collect(keys(g.playercounts)))
    #v = get(g.playercounts, "$i", [0,0,1])
    i = k
    v = get(g.playercounts, k, nothing)
    v = v ./ sum(v) .* 100
    best, rec, no = v
    tmp = "<div id='rating'>          
            <div class='ratingbest' style='height: $(best)%'></div>
            <div class='ratingrec' style='height: $(rec)%'></div>
            <div class='ratingn' style='position: absolute; width: 28'>$i</div>
          </div>"
    playercounts *= tmp
  end

  mechanics = reduce(*, map(m->"<div>$m</div>", g.mechanics))


  html = #="
    <div id='card'>
      <div id='header'>
        <div id='bggrating'>$rating</div>
        <div id='ratings'>$playercounts</div>
        <div id='playtime'>$playtime</div>
        <div id='weight'>$weight</div>
      </div>
      <div id='main'>
        <div id='title'>$title</div>
        <div id='image'><img src='$thumb' width=100% heigth=100%></div>
        <div id='designer'>$designer, $year</div>
        <div id='description' lang='en'>$description</div>
        <div id='mechanics'>$mechanics</div>
      </div>
      
    </div>
    =#
    "<div id='card'>
     
      <div id='main'>
        <div class='left'>
          <div id='title'>$title</div>
          <div id='image'><img src='$thumb' width=100% heigth=100%></div>
          <div id='designer'>$designer, $year</div>
          <div id='description' lang='en'>$description</div>
          <div id='mechanics'>$mechanics</div>
        </div>
      
        <div class='right'>
        <div id='bggrating' class='texticon'>$rating</div>
        <div id='weight' class='texticon'>$weight</div>
        <div id='playtime' class='texticon'>$playtime</div>
        <div id='ratings' class='texticon'>$playercounts</div>
        
        </div>
      </div>
    </div>"

  return html
end



header(cards::Vector) = header(reduce(*, cards))

function header(cards)
  "<html>
  <head>
    <title>Game Card</title>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <link rel='stylesheet' href='styles.css'>
  </head>
  <body>" * 
  cards * 
  "</body>
  </html>"
end

function savecards(gs)
  open("test.html", "w") do f
    write(f, header(map(card,gs)))
  end
end
