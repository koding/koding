kd = require 'kd'
BasePageController = require './basepagecontroller'
StartMachinePageView = require '../views/startmachinepageview'
StartMachineProgressPageView = require '../views/startmachineprogresspageview'
StartMachineSuccessPageView = require '../views/startmachinesuccesspageview'
StartMachineErrorPageView = require '../views/startmachineerrorpageview'
StopMachineProgressPageView = require '../views/stopmachineprogresspageview'
StopMachineErrorPageView = require '../views/stopmachineerrorpageview'

module.exports = class MachineFlowController extends BasePageController

  constructor: (options, data) ->

    super options, data

    { container } = @getOptions()
    machine = @getData()

    @startMachinePage = new StartMachinePageView()
    @startMachineProgressPage = new StartMachineProgressPageView {}, machine
    @startMachineSuccessPage = new StartMachineSuccessPageView()
    @startMachineErrorPage = new StartMachineErrorPageView()
    @stopMachineProgressPage = new StopMachineProgressPageView {}, machine
    @stopMachineErrorPage = new StopMachineErrorPageView()

    @registerPages [
      @startMachinePage
      @startMachineProgressPage
      @startMachineSuccessPage
      @startMachineErrorPage
      @stopMachineProgressPage
      @stopMachineErrorPage
    ]

    @startMachinePage.on 'StartMachine', @bound 'startMachine'
    @startMachineErrorPage.on 'StartMachine', @bound 'startMachine'
    @forwardEvent @startMachineSuccessPage, 'ClosingRequested'
    @stopMachineErrorPage.on 'StopMachine', @bound 'stopMachine'


  show: (state) ->

    page = switch state
      when 'Starting' then @startMachineProgressPage
      when 'Stopped'  then @startMachinePage
      when 'Stopping' then @stopMachineProgressPage
    return  unless page

    @setCurrentPage page


  showError: (error, state,  prevState) ->

    page = switch
      when state is 'Stopped' and prevState is 'Starting' then @startMachineErrorPage
      when state is 'Running' and prevState is 'Stopping' then @stopMachineErrorPage
    return  unless page

    page.setErrors [ error ]
    @setCurrentPage page


  updateProgress: (percentage, message, state) ->

    page = switch state
      when 'Starting' then @startMachineProgressPage
      when 'Stopping' then @stopMachineProgressPage
    return  unless page

    page.updateProgress percentage, message
    @setCurrentPage page


  completeProcess: (state) ->

    page = switch state
      when 'Running' then @startMachineSuccessPage
    return  unless page

    @setCurrentPage page


  startMachine: ->

    machine = @getData()
    { computeController } = kd.singletons

    computeController.start machine

    page = @show 'Starting'
    page.updateProgress() # reset previous progress

    @emit 'MachineTurnOnStarted', machine


  stopMachine: ->

    machine = @getData()
    { computeController } = kd.singletons

    computeController.stop machine

    page = @show 'Stopping'
    page.updateProgress() # reset previous progress
