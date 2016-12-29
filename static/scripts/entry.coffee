# style
require '../style/custom'
#$ = require('jquery'); window.jQuery = $  # needed for semantic
#semantic = require 'semantic-ui/dist/semantic'

# TODO switch to latest coffeescript version and use import * from '...' syntax
# library imports
React = require 'react'
ReactDOM = require 'react-dom'
{div, button, crel, i, text} = require 'teact'

# user imports
PointsPlot = require './components/points-plot'
getJSON = require './utils'


CONF =
  nextEpochDelay: 10  #ms



class Interface extends React.Component
  constructor: ->
    @state =
      bounds: null
      points: null
      history: null

      currentEpoch: null
      isTraining: no
      finishedTraining: no


    getJSON '/bounds', (bounds) =>
      @setState {bounds}
    getJSON '/points', (points) =>
      @setState {points}
    getJSON '/training_history', (history) =>
      @setState {history}

  startTraining: =>
    @setState
      currentEpoch: 0
      isTraining: yes
      finishedTraining: no
      , ->
      setTimeout(@trainingIterator, CONF.nextEpochDelay)


  trainingIterator: =>
    epoch = @state.currentEpoch
    if epoch >= @state.history.length - 1  # reached last epoch
      @setState
        isTraining: no
        finishedTraining: yes
      return  # stop recursing
    @setState currentEpoch: epoch + 1, ->
      setTimeout(@trainingIterator, CONF.nextEpochDelay)


  pauseTraining: =>
    @setState isTraining: no


  regeneratePoints: =>
    console.log 'regen'


  render: ->
    div '#interface', =>
      if not(@state.bounds? and @state.points?)
        text 'loading'  # TODO loading animation
        return

      if @state.history? and (@state.isTraining or @state.finishedTraining)
        currentWeights = @state.history[@state.currentEpoch].weights

      crel PointsPlot,
        bounds: @state.bounds
        points: @state.points
        weights: currentWeights

      button '#regen-button .ui vertical animated button', onClick: @regeneratePoints, ->
        div '.visible content', -> i '.refresh icon'
        div '.hidden content', 'Regen'

      @trainButton()


  trainButton: =>
    # either Train, Pause or Restart
    if @state.isTraining
      button '#train-button .ui yellow large labeled icon button', onClick: @pauseTraining, ->
        i '.pause icon'; text 'Pause'
    else  # not training
      if @state.finishedTraining
        button '#train-button .ui blue large labeled icon button', onClick: @startTraining, ->
          i '.repeat icon'; text 'Restart'
      else  # training has not started
        button '#train-button .ui blue large labeled icon button', onClick: @startTraining, ->
          i '.play icon'; text 'Train'



ReactDOM.render crel(Interface),
  document.getElementById 'react-container'
