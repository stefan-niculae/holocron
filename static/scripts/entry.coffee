# style
require '../style/custom'
#$ = require('jquery'); window.jQuery = $  # needed for semantic
#semantic = require 'semantic-ui/dist/semantic'

# TODO switch to latest coffeescript version and use import * from '...' syntax
# library imports
React = require 'react'
ReactDOM = require 'react-dom'
{div, button, crel, i, text, section, span} = require 'teact'

# user imports
getJSON = require './utils'
PointsPlot = require './components/points-plot'
AccuracyPlot = require './components/accuracy-plot'


CONF =
  nextEpochDelay: 100  #ms



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
    div '#interface .ui centered container', =>

      @pointsPlot()

      button '#regen-button .ui vertical animated button', onClick: @regeneratePoints, ->
        # TODO make the button clickable even when the hidden content has not fully appeared
        div '.visible content', -> i '.refresh icon'
        div '.hidden content', 'Regen'

      @trainButton()

      @accuracyPlot()


  pointsPlot: =>
    section '#points-plot-segment .ui segment plot-segment', =>
      if not(@state.bounds? and @state.points?)  # loading
        section '#points-plot-segment .ui loading segment plot-segment'
        return

      if @state.hasStartedTraining
        currentWeights = @state.history[@state.currentEpoch].weights

      section '#points-plot-segment .ui segment plot-segment', =>
        crel PointsPlot,
          bounds: @state.bounds
          points: @state.points
          weights: currentWeights

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

  accuracyPlot: =>
    section '#accuracy-plot-segment .ui segment plot-segment', =>
      if not @state.hasStartedTraining
        div '#not-started-info .ui grid row', ->
          div '.middle aligned column', ->
            i '.hand pointer icon'; text 'start Training to see the accuracy chart'
        return


      nrPoints = @state.points.A.x.length + @state.points.B.x.length
      errorPercentages = @state.history[0 ... @state.currentEpoch + 1]
        .map (h) => h.misclassified / nrPoints * 100

      crel AccuracyPlot,
        training: errorPercentages
        maxEpoch: @state.history.length




ReactDOM.render crel(Interface),
  document.getElementById 'react-container'
