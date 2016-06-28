kd = require 'kd'
HomeWelcome = require './'

module.exports = class WelcomeModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = 'HomeWelcomeModal'
    options.width    = 710

    super options, data

    kd.singletons.router.once 'RouteInfoHandled', => @destroy no


  viewAppended: ->

    super

    @addSubView new HomeWelcome


  destroy: (selfInitiated = yes) ->

    kd.singletons.router.handleRoute '/IDE'  if selfInitiated

    super