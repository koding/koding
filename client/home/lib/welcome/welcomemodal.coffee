kd = require 'kd'
HomeWelcome = require './'

module.exports = class WelcomeModal extends kd.ModalView

  constructor: (options = {}, data) ->

    { landedOnWelcome } = localStorage

    options.cssClass = "HomeWelcomeModal#{if landedOnWelcome then ' hidden' else ''}"
    options.width    = 710

    super options, data

    { router, mainController } = kd.singletons

    router.once 'RouteInfoHandled', => @destroy no

    mainController.once 'AllWelcomeStepsDone', @bound 'destroy'
    mainController.once 'AllWelcomeStepsNotDoneYet', @bound 'initialShow'

    localStorage.landedOnWelcome = ''


  initialShow: ->
    @show()
    @_windowDidResize()


  viewAppended: ->

    super

    @addSubView new HomeWelcome


  destroy: (selfInitiated = yes) ->

    kd.singletons.router.handleRoute '/IDE'  if selfInitiated

    super

