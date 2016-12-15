CONFIGS =
  minVal: 1e-5
  markerSize: 8
  lineWidth: 1.5

# from backend
colors =
  orange:      'rgba(250, 125, 45,  1)'
  blue:        'rgba(42,  122, 177, 1)'
  fadedOrange: 'rgba(252, 189, 149, .25)'
  fadedBlue:   'rgba(148, 188, 216, .25)'
  purple:      'rgba(128, 0,   128, .6)'

# from backend
bounds =
  x: min: 0, max: 1
  y: min: 0, max: 1
# from backend
ws = [-1.25, 1, 0]

# from backend
points =
  A:
    x: [.1, .3, .2]
    y: [.4123, .2,.05]
  B:
    x: [.6, .5, .9]
    y: [.4123, .7, .85]


clamp_magnitude = (x) ->
  if Math.abs(x) < CONFIGS.minVal
    CONFIGS.minVal * Math.sign(x)
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


predictA =
  x: [bounds.x.min,   bounds.x.min,    bounds.x.max,  bounds.x.max]
  y: [bounds.y.min, f(bounds.x.min), f(bounds.x.max), bounds.y.max]
  fill:      'tozeroy'
  mode:      'none'
  fillcolor: colors.fadedBlue
  hoverinfo: 'skip'
  name:      'predict A'

predictB =
  x: [bounds.x.min,   bounds.x.min,    bounds.x.max,  bounds.x.max]
  y: [bounds.y.min, f(bounds.x.min), f(bounds.x.max), bounds.y.max]
  fill:      'tonextx'
  mode:      'none'
  fillcolor: colors.fadedOrange
  hoverinfo: 'skip'
  name:      'predict B'


pointsA =
  x:       points.A.x
  y:       points.A.y
  mode:   'markers'
  marker:
    color: colors.blue
    size: CONFIGS.markerSize
  name:   'class A'

pointsB =
  x:    points.B.x
  y:    points.B.y
  mode: 'markers'
  marker:
    color: colors.orange
    size: CONFIGS.markerSize
  name: 'class B'


layout =
#  title:     'classification'
  hovermode: 'closest'
  xaxis:
#    zeroline:    off
    hoverformat: '.1f'
    range: [bounds.x.min, bounds.x.max]
  yaxis:
#    zeroline:    off
    hoverformat: '.1f'
    range: [bounds.y.min, bounds.y.max]

  shapes: [
    type: 'line'
    x0: bounds.x.min
    y0: f(bounds.x.min)

    x1: bounds.x.max
    y1: f(bounds.x.max)

    line:
      color: colors.purple
      width: CONFIGS.lineWidth
  ]

data = [
  predictB
  predictA
  pointsB
  pointsA
]

Plotly.newPlot('chart-div', data, layout);
