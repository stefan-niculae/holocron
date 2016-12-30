React = require 'react'
Plotly = require 'plotly.js/lib/core'
{div} = require 'teact'



CONF =
  divId: 'accuracy-plot'



class AccuracyPlot extends React.Component
  render: ->
    div "##{CONF.divId} .plot"

  componentDidMount: ->
    @drawPlot()

  componentDidUpdate: ->
    @drawPlot()

  drawPlot: ->
    ys = @props.training.map (p) -> p * 100

    training =
      x: [1 .. ys.length]
      y: ys
      text: "epoch <b>#{n}</b>" for n in [1 .. ys.length]

    yMin = -1 # of zero so the marker can be fully visible
    yMax =  1 + Math.max ys...

    layout =
      xaxis:
        tickprefix: 'epoch '
        showticklabels: no
        showgrid: no
      yaxis:
        ticksuffix: '% error'
        showticklabels: no
        zeroline: off
        range: [yMin, yMax]
        gridcolor: '#rgba(0,0,0,.065)'
      margin: t: 0, b: 0, l: 0, r: 0

    data = [
      training
    ]

    options =
      displayModeBar: no

    Plotly.newPlot CONF.divId, data, layout, options


module.exports = AccuracyPlot