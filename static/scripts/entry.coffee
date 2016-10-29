$ = require 'jQuery'
Plotly = require 'plotly.js/lib/core'


$ ->
  drawPlot()

  $ '#regen-button'
    .click ->
      $.ajax '/regen'
      drawPlot()


drawPlot = ->
  $.getJSON '/coords', (coords) ->
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
    layout =
      xaxis: range: [0, 10]
      yaxis: range: [0, 10]


    Plotly.newPlot 'plot', data, layout