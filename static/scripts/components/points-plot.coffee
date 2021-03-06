#Plot = require './components/plot'  # TODO make Plot abstract after doing the error-plot as well
React = require 'react'
Plotly = require 'plotly.js/lib/core'
{div} = require 'teact'
{extend, arraysEqual} = require '../utils'


CONF =
  divId:      'points-plot'
  epsilon:    1e-8
  markerSize: 8
  lineWidth:  1.5
  colors:
    orange:      'rgba(250, 125, 45,  1)'
    blue:        'rgba(42,  122, 177, 1)'
    fadedOrange: 'rgba(252, 189, 149, .05)'
    fadedBlue:   'rgba(148, 188, 216, .05)'
    purple:      'rgba(128, 0,   128, .5)'
    lightGrey:   'rgba(220, 220, 220, 1)'


pointsOptions =
  mode: 'markers'
  marker: size:  CONF.markerSize
  # will be extended with x, y, name and symbol


class PointsPlot extends React.Component
  render: ->
    div "##{CONF.divId} .plot"

  shouldComponentUpdate: (nextProps) ->
    # No need to redraw the plot if the points are the same
    if arraysEqual @props.points, nextProps.points
      # But we still need to redraw the prediction line if it is different
      @drawPredictionLine(nextProps.weights) if !arraysEqual @props.weights, nextProps.weights
      return false

    return true

  componentDidMount: ->
    @drawPlot()

  componentDidUpdate: ->
    @drawPlot()


  drawPlot: ->
    trainA = extend pointsOptions,
      x:      @props.points.filter((p) => p.label is 'A' and p.set is 'train').map (p) => p.x
      y:      @props.points.filter((p) => p.label is 'A' and p.set is 'train').map (p) => p.y
      marker:
        symbol: 'circle'
        color: CONF.colors.blue
      name:   'A training'

    trainB = extend pointsOptions,
      x:      @props.points.filter((p) => p.label is 'B' and p.set is 'train').map (p) => p.x
      y:      @props.points.filter((p) => p.label is 'B' and p.set is 'train').map (p) => p.y
      name:   'B training'
      marker:
        symbol: 'circle'
        color: CONF.colors.orange

    testA = extend pointsOptions,
      x:      @props.points.filter((p) => p.label is 'A' and p.set is 'test').map (p) => p.x
      y:      @props.points.filter((p) => p.label is 'A' and p.set is 'test').map (p) => p.y
      name:   'A test'
      marker:
        symbol: 'circle-open'
        color: CONF.colors.blue

    testB = extend pointsOptions,
      x:      @props.points.filter((p) => p.label is 'B' and p.set is 'test').map (p) => p.x
      y:      @props.points.filter((p) => p.label is 'B' and p.set is 'test').map (p) => p.y
      name:   'B test'
      marker:
        symbol: 'circle-open'
        color: CONF.colors.orange


    layout =
      hovermode: 'closest'
      xaxis:
        zerolinecolor: CONF.colors.lightGrey
        showticklabels: no
        hoverformat: '.1f'
        range: [@props.bounds.x.min, @props.bounds.x.max]
      yaxis:
        zerolinecolor: CONF.colors.lightGrey
        showticklabels: no
        hoverformat: '.1f'
        range: [@props.bounds.y.min, @props.bounds.y.max]
      paper_bgcolor: 'rgba(0,0,0,.025)'
      margin: t: 0, b: 0, l: 0, r: 0
      legend:
        x: .05
        y: .95

    data = [
      trainA
      trainB
      testA
      testB
    ]

    options =
      displayModeBar: no

    Plotly.newPlot CONF.divId, data, layout, options
    @drawPredictionLine @props.weights


  drawPredictionLine: (weights) ->
    if weights?
      Plotly.relayout CONF.divId, shapes: @getShapes weights

  getShapes: (weights) ->
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

    xMin = @props.bounds.x.min
    xMax = @props.bounds.x.max

    fL = new Point xMin, f(xMin), 'fA'  # left
    fR = new Point xMax, f(xMax), 'fB'  # right
    interwoven = interweaveIntersections fL, fR, @props.bounds
    interwovenA = interwoven.filter (c) -> flip(orientation fL, fR, c) >= 0  # all corners to the left AND the intersections
    interwovenB = interwoven.filter (c) -> flip(orientation fL, fR, c) <= 0  # all corners to the right AND the intersections

    shapes = [
      type: 'line'
      x0:   xMin
      y0:   f(xMin)
      x1:   xMax
      y1:   f(xMax)
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

    return shapes



class Point
  constructor: (@x, @y, @name) ->

  toString: -> "#{@x},#{@y}"


class Line
  constructor: (@start, @end) ->



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


lineIntersection = (line1, line2) ->
  # if the lines intersect, the result contains the x and y of the intersection (treating the lines as infinite)
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


module.exports = PointsPlot
