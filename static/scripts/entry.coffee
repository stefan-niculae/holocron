# Stylesheets
require '../style/custom'

$ = require 'jquery'
Plotly = require 'plotly.js/lib/core'

window.jQuery = $
# semantic = require '../../semantic/dist/semantic'
semantic = require 'semantic-ui/dist/semantic'

#ReactDOM = require 'react-dom'
#{h1, h2, div, text, span, crel} = require 'teact'

CONF =
  epsilon:    1e-5
  markerSize: 8
  lineWidth:  1.5
  colors:
    orange:      'rgba(250, 125, 45,  1)'
    blue:        'rgba(42,  122, 177, 1)'
    fadedOrange: 'rgba(252, 189, 149, .25)'
    fadedBlue:   'rgba(148, 188, 216, .25)'
    purple:      'rgba(128, 0,   128, .6)'
    lightGrey:   'rgba(200, 200, 200, 1)'


# TODO, from backend
#ws = [-.75, 1, 0]  # /
ws = [1.25, 1, .4]  #  \
#ws = [.5, 1, -.25]  #  \
clamp_magnitude = (x) ->
  sign = if x >= 0 then 1 else -1
  if Math.abs(x) < CONF.epsilon
    CONF.epsilon * sign
  else
    x
[a, b, c] = ws.map clamp_magnitude

###
  ax + by + c = 0
  by + ax + c = 0
  by = -(ax + c)
   y = -(ax + c) / b
###
f = (x) -> -(a * x + c) / b


orientation = (A, B, C) ->
  """
  =0    C is on the line AB
  <0    C is to the left of AB
  >0    C is to the right of AB
  """
  (B.y - A.y) * (C.x - B.x) - (B.x - A.x) * (C.y - B.y)




$ ->
  drawPlot()

  $ '#regen-button'
    .click ->
      $.ajax '/regen'
      drawPlot()


drawPlot = ->
  # TODO more elegant solution, state?
  $.getJSON '/bounds', (bounds) ->

    corners = [
      {x: bounds.x.min, y: bounds.y.min},
      {x: bounds.x.max, y: bounds.y.min},
      {x: bounds.x.max, y: bounds.y.max},
      {x: bounds.x.min, y: bounds.y.max}
    ]
    A = {x: bounds.x.min, y: f bounds.x.min}
    B = {x: bounds.x.max, y: f bounds.x.max}

    cornersA = corners.filter (c) -> orientation(A, B, c) <  0
    cornersB = corners.filter (c) -> orientation(A, B, c) >= 0

    coordsA = [{x: bounds.x.min, y: f bounds.x.min}, cornersA..., {x: bounds.x.max, y: f bounds.x.max}]
    debugger

    $.getJSON '/points', (points) ->
      pointsA =
        x:       points.A.x
        y:       points.A.y
        mode:   'markers'
        marker:
          color: CONF.colors.blue
          size: CONF.markerSize
        name:   'class A'

      pointsB =
        x:    points.B.x
        y:    points.B.y
        mode: 'markers'
        marker:
          color: CONF.colors.orange
          size: CONF.markerSize
        name: 'class B'

      xm = bounds.x.min
      xM = bounds.x.max
      ym = bounds.y.min
      yM = bounds.y.max
        
      layout =
      #  title:     'classification'
        hovermode: 'closest'
        xaxis:
          zerolinecolor: CONF.colors.lightGrey
          hoverformat: '.1f'
          range: [bounds.x.min, bounds.x.max]
        yaxis:
          zerolinecolor: CONF.colors.lightGrey
          hoverformat: '.1f'
          range: [bounds.y.min, bounds.y.max]
        shapes: [
          {
            type: 'line'
            x0:   bounds.x.min
            y0:   f(bounds.x.min)
            x1:   bounds.x.max
            y1:   f(bounds.x.max)
            line:
              color:   CONF.colors.purple
              width: CONF.lineWidth
          }
          {
            type: 'path',
            path: 'M ' + coordsA.map((p) -> "#{p.x},#{p.y}").join(' L ') + ' Z'
            fillcolor: CONF.colors.fadedBlue
            line: color: 'rgba(0,0,0,0)'
          }
        ]


      data = [
        pointsA
        pointsB
      ]

      Plotly.newPlot 'plot', data, layout
