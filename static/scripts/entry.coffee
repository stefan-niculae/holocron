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
      hasStartedTraining: no
      isTraining: no

    @fetchData()


  fetchData: =>
    getJSON '/bounds', (bounds) =>
      @setState {bounds}
    getJSON '/points', (points) =>
      @setState {points}
    getJSON '/training_history', (history) =>
      @setState {history}


  startTraining: =>
    @setState
      currentEpoch: 0
      hasStartedTraining: yes
      isTraining: yes
      , => @scheduleTrainingTimeout()

  scheduleTrainingTimeout: =>
    @trainingTimeout = setTimeout(@trainingIterator, CONF.nextEpochDelay)


  trainingIterator: =>
    epoch = @state.currentEpoch
    if epoch >= @state.history.length - 1  # reached last epoch
      @setState
        isTraining: no
        finishedTraining: yes
      return  # stop recursing
    @setState currentEpoch: epoch + 1, =>
      @scheduleTrainingTimeout()


  pauseTraining: =>
    @setState isTraining: no, =>
      clearTimeout @trainingTimeout if @trainingTimeout?

  resumeTraining: =>
    @setState isTraining: yes, =>
      @scheduleTrainingTimeout()


  regeneratePoints: =>
    getJSON '/regen', =>
      @setState
        currentEpoch: null
        hasStartedTraining: no
        isTraining: no
      , =>
        @fetchData()


  render: ->
    div '#interface', =>
      if not(@state.bounds? and @state.points?)
        text 'loading'  # TODO loading animation
        return

      if @state.history? and @state.hasStartedTraining
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
      if @state.hasStartedTraining
        if @state.currentEpoch >= @state.history.length - 1  # it has finished training
          button '#train-button .ui large labeled icon button', onClick: @startTraining, ->
            i '.repeat icon'; text 'Restart'
        else  # hasn't finished training, it's resumed
          button '#train-button .ui blue large labeled icon button', onClick: @resumeTraining, ->
            i '.play icon'; text 'Resume'
      else  # training has not started
        button '#train-button .ui blue large labeled icon button', onClick: @startTraining, ->
          i '.play icon'; text 'Train'



ReactDOM.render crel(Interface),
  document.getElementById 'react-container'
