# style
require '../style/custom'
#$ = require('jquery'); window.jQuery = $  # needed for semantic
#semantic = require 'semantic-ui/dist/semantic'

# library imports
React = require 'react'
ReactDOM = require 'react-dom'
{div, button, crel, i, text} = require 'teact'

# user imports
PointsPlot = require './components/points-plot'
getJSON = require './utils'

CONF =
  nextEpochDelay: 50  #ms



class Interface extends React.Component
  constructor: ->
    @state =
      bounds: null
      points: null
      history: null

      isTraining: no
      currentEpoch: null


    getJSON '/bounds', (bounds) =>
      @setState {bounds}
    getJSON '/points', (points) =>
      @setState {points}
    getJSON '/training_history', (history) =>
      @setState {history}
      console.log history


  startTraining: =>
    @setState {currentEpoch: 0, isTraining: yes}, ->
      setTimeout(@trainingIterator, CONF.nextEpochDelay)


  trainingIterator: =>
    epoch = @state.currentEpoch
    return if epoch >= @state.history.length - 1
    @setState currentEpoch: epoch + 1, ->
      setTimeout(@trainingIterator, CONF.nextEpochDelay)


  pauseTraining: =>
    @setState isTraining: no

  render: ->
    div '#interface', =>
      if not(@state.bounds? and @state.points?)
        text 'loading'  # TODO loading animation
        return

      if @state.history? and @state.isTraining
        currentWeights = @state.history[@state.currentEpoch].weights
        console.log 'interf render', currentWeights

      crel PointsPlot,
        bounds: @state.bounds
        points: @state.points
        weights: currentWeights

      if not @state.isTraining
        button '#train-button .ui positive large labeled icon button', onClick: @startTraining, ->
          i '.play.icon'
          text 'Train'
      else
        button '#train-button .ui large labeled icon button', onClick: @pauseTraining, ->
          i '.pause.icon'
          text 'Pause'






ReactDOM.render crel(Interface),
  document.getElementById 'react-container'
