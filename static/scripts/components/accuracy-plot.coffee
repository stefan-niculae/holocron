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
    epochs = [1 .. @props.maxEpoch]
    nrRemaining = @props.maxEpoch - epochs.length
    remainings = Array(nrRemaining).fill(null)
    # TODO 0 digits precision
    training =
      x: epochs
      y: @props.training.concat remainings
      name: 'training'
      text: "epoch <b>#{n}</b>" for n in [1 .. epochs.length]
      line:
        width: 2
        shape: 'spline'  # a little curved
        color: 'purple'

    test =
      x: epochs
      y: @props.test.concat remainings
      name: 'test'
      line:
        width: 1
        shape: 'spline'  # a little curved
        color: 'grey'

    yMin = -1 # of zero so the marker can be fully visible
    yMax = 105 # 1.1 * Math.max Math.max(@props.training...), Math.max(@props.test...)

    layout =
      xaxis:
        tickprefix: 'epoch '
        showticklabels: no
        showgrid: no
        zeroline: off
      yaxis:
        ticksuffix: '% error'
        showticklabels: no
        zeroline: off
        range: [yMin, yMax]
        gridcolor: '#rgba(0,0,0,.065)'
      margin: t: 0, b: 0, l: 0, r: 0
      paper_bgcolor: 'rgba(0,0,0,.025)'
      legend:  # TODO always make this stay inside
        x: .85
        y: .9


    data = [
      training
      test
    ]

    options =
      displayModeBar: no

    Plotly.newPlot CONF.divId, data, layout, options


module.exports = AccuracyPlot