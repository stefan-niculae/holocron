$ ->
  $.getJSON '/coords', (data) ->
    drawPlot 'plot', data


drawPlot = (container, coords) ->
  trace0 =
    x: coords.A.map (point) -> point[0]
    y: coords.A.map (point) -> point[1]
    mode: 'markers'
    type: 'scatter'

  trace1 =
    x: coords.B.map (point) -> point[0]
    y: coords.B.map (point) -> point[1]
    mode: 'markers'
    type: 'scatter'

  data = [trace0, trace1]

  Plotly.newPlot container, data