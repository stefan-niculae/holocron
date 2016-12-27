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
  epsilon:    1e-8
  markerSize: 8
  lineWidth:  1.5
  colors:
    orange:      'rgba(250, 125, 45,  1)'
    blue:        'rgba(42,  122, 177, 1)'
    fadedOrange: 'rgba(252, 189, 149, .25)'
    fadedBlue:   'rgba(148, 188, 216, .25)'
    purple:      'rgba(128, 0,   128, .6)'
    lightGrey:   'rgba(200, 200, 200, 1)'
  nextEpochDelay: 100  #ms


clamp_magnitude = (x) ->
  """
  no smaller than configured epsilon
  guards against purely vertical or purely horizontal lines
  """
  sign = if x >= 0 then 1 else -1
  if Math.abs(x) < CONF.epsilon
    CONF.epsilon * sign
  else
    x


orientation = (A, B, C) ->
  """
  =0    C is on the line AB
  <0    C is to the left of AB
  >0    C is to the right of AB
  """
  result = (B.y - A.y) * (C.x - B.x) - (B.x - A.x) * (C.y - B.y)
  if Math.abs(result) < CONF.epsilon
    0  # avoid floating point imprecisions
  else
    result



class Point
  constructor: (@x, @y, @name) ->

  toString: -> "#{@x},#{@y}"

class Line
  constructor: (@start, @end) ->


lineIntersection = (line1, line2) ->
  # if the lines intersect, the result contains the x and y of the intersection (treating the lines as infinite)
  # and booleans for whether line segment 1 or line segment 2 contain the point
  result = new Point
  result.onLine1 = no
  result.onLine2 = no

  denominator = (line2.end.y - line2.start.y) * (line1.end.x - line1.start.x) -
                (line2.end.x - line2.start.x) * (line1.end.y - line1.start.y)
  if denominator is 0
    return result

  a = line1.start.y - line2.start.y
  b = line1.start.x - line2.start.x
  numerator1 = (line2.end.x - line2.start.x) * a - (line2.end.y - line2.start.y) * b
  numerator2 = (line1.end.x - line1.start.x) * a - (line1.end.y - line1.start.y) * b
  a = numerator1 / denominator
  b = numerator2 / denominator

  # if we cast these lines infinitely in both directions, they intersect here:
  result.x = line1.start.x + a * (line1.end.x - line1.start.x)
  result.y = line1.start.y + a * (line1.end.y - line1.start.y)
  """
  it is worth noting that this should be the same as:
  x = line2.start.x + b * (line2.end.x - line2.start.x)
  y = line2.start.x + b * (line2.end.y - line2.start.y)
  """
  # if line1 is a segment and line2 is infinite, they intersect if:
  if 0 <= a <= 1
      result.onLine1 = yes

  # if line2 is a segment and line1 is infinite, they intersect if:
  if 0 <= b <= 1
      result.onLine2 = yes

  # if line1 and line2 are segments, they intersect if both of the above are true
  return result


interweaveIntersections = (fL, fR, bounds) ->
  """
  b-----P----c
  |    /     |
  |  /       |
  |/         |
  Q          |
  |          |
  a__________d
  we want the order a Q b P c d
  ie: in one direction (clockwise chosen here)
  """
  corners = [
    new Point bounds.x.min, bounds.y.min, 'left bottom'
    new Point bounds.x.min, bounds.y.max, 'left top'
    new Point bounds.x.max, bounds.y.max, 'right top'
    new Point bounds.x.max, bounds.y.min, 'right bottom'
  ]
  fLine = new Line fL, fR

  interwoven = []
  for i in [0...corners.length]
    start = corners[i]
    endIndex = i + 1
    endIndex = 0 if endIndex == corners.length # wraparound at last element
    end = corners[endIndex]
    edge = new Line start, end

    interwoven.push start  # always put the corner
    intersection = lineIntersection edge, fLine
    if intersection.onLine1  # if on edge
      interwoven.push intersection  # add the point between correct corners

  return interwoven

$ ->
  drawPlot()

  $ '#regen-button'
    .click ->
      $.ajax '/regen'
      # TODO: clear the timeout for iterating training history here
      drawPlot()


drawPlot = ->

  # TODO more elegant solution, state?
  $.getJSON '/bounds', (bounds) ->

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

      data = [
        pointsA
        pointsB
      ]

      Plotly.newPlot 'points-chart', data, layout


      $.getJSON '/training_history', (history) ->
        i = 0
        iterator = () ->
          updateLine bounds, history[i].weights

          i++
          return if i is history.length  # stop looping
          setTimeout(iterator, CONF.nextEpochDelay)
        iterator()



updateLine = (bounds, weights) ->
  """
  ax + by + c = 0
  by + ax + c = 0
  by = -(ax + c)
   y = -(ax + c) / b
  """
  [a, b, c] = weights.map clamp_magnitude
  f = (x) -> -(a * x + c) / b

  flip = (o) ->  # TODO: is this a hack? test for centroids that are not lower-left and upper-right and check actual number of misclassified against graph
    if -a/b > 1  # slope
      o * -1
    else
      o

  fL = new Point bounds.x.min, f(bounds.x.min), 'fA'  # left
  fR = new Point bounds.x.max, f(bounds.x.max), 'fB'  # right
  interwoven = interweaveIntersections fL, fR, bounds
  interwovenA = interwoven.filter (c) -> flip(orientation fL, fR, c) >= 0  # all corners to the left AND the intersections
  interwovenB = interwoven.filter (c) -> flip(orientation fL, fR, c) <= 0  # all corners to the right AND the intersections

  shapes = [
    type: 'line'
    x0:   bounds.x.min
    y0:   f(bounds.x.min)
    x1:   bounds.x.max
    y1:   f(bounds.x.max)
    line:
      color: CONF.colors.purple
      width: CONF.lineWidth
  ]

  if interwovenA.length > 0  # not outside the viewing window
    shapes.push
      type: 'path'
      path: 'M ' + interwovenA.join(' L ') + ' Z'
      fillcolor: CONF.colors.fadedBlue
      line: color: 'rgba(0,0,0,0)'

  if interwovenB.length > 0
    shapes.push
      type: 'path'
      path: 'M ' + interwovenB.join(' L ') + ' Z'
      fillcolor: CONF.colors.fadedOrange
      line: color: 'rgba(0,0,0,0)'

  # update just the shapes, not the whole chart
  Plotly.relayout 'points-chart', shapes: shapes
