kd = require 'kd'
BasePageController = require './basepagecontroller'
StartMachinePageView = require '../views/startmachinepageview'
StartMachineProgressPageView = require '../views/startmachineprogresspageview'
StartMachineSuccessPageView = require '../views/startmachinesuccesspageview'
StartMachineErrorPageView = require '../views/startmachineerrorpageview'

module.exports = class MachineFlowController extends BasePageController

  constructor: (options, data) ->

    super options, data

    { container } = @getOptions()
    machine = @getData()

    @startMachinePage = new StartMachinePageView()
    @startMachineProgressPage = new StartMachineProgressPageView {}, machine
    @startMachineSuccessPage = new StartMachineSuccessPageView()
    @startMachineErrorPage = new StartMachineErrorPageView()

    @registerPages [
      @startMachinePage
      @startMachineProgressPage
      @startMachineSuccessPage
      @startMachineErrorPage
    ]

    @startMachinePage.on 'StartMachine', @bound 'startMachine'
    @startMachineErrorPage.on 'StartMachine', @bound 'startMachine'
    @forwardEvent @startMachineSuccessPage, 'ClosingRequested'


  show: (state) ->

    page = switch state
      when 'Starting' then @startMachineProgressPage
      when 'Stopped'  then @startMachinePage
    return  unless page

    @setCurrentPage page


  showError: (error, state) ->

    page = switch state
      when 'Stopped' then @startMachineErrorPage
    return  unless page

    page.setErrors [ error ]
    @setCurrentPage page


  updateProgress: (percentage, message, state) ->

    page = switch state
      when 'Starting' then @startMachineProgressPage
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

