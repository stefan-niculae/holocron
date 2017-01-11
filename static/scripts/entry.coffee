# style
require '../style/custom'
#$ = require('jquery'); window.jQuery = $  # needed for semantic
#semantic = require 'semantic-ui/dist/semantic'

# TODO switch to latest coffeescript version and use import * from '...' syntax
# library imports
React = require 'react'
ReactDOM = require 'react-dom'
{div, button, crel, i, text, section, span, br} = require 'teact'

# user imports
{getJSON} = require './utils'
PointsPlot = require './components/points-plot'
AccuracyPlot = require './components/accuracy-plot'


CONF =
  nextEpochDelay: 1000  #ms



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
        clearTimeout @trainingTimeout if @trainingTimeout?
        @fetchData()


  render: ->
    div '#interface .ui centered container', =>

      @pointsPlot()

      div '.ui grid', =>
        div '.row', =>
          button '#regen-button .ui vertical animated button', onClick: @regeneratePoints, ->
            # TODO make the button clickable even when the hidden content has not fully appeared
            div '.visible content', -> i '.refresh icon'
            div '.hidden content', 'Regen'

          @trainButton()

          # TODO? big statistic?
#      div '.row', =>
#        div '.ui statistic', =>
#          span '.value', '74%'
#          span '.label', 'accuracy'
#
#      div '.row', =>
#        div '.ui statistic', =>
#          span '#nr-misclassified .label', '12 errors'


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


      trainErrors = @state.history[0 ... @state.currentEpoch + 1]
        .map (h) => h.misclassifiedTrain / @state.points.length * 100

      testErrors  = @state.history[0 ... @state.currentEpoch + 1]
        .map (h) => h.misclassifiedTest  / @state.points.length * 100


      crel AccuracyPlot,
        training: trainErrors
        test: testErrors
        maxEpoch: @state.history.length




ReactDOM.render crel(Interface),
  document.getElementById 'react-container'
