kd = require 'kd'
HomeWelcome = require './'

module.exports = class WelcomeModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = 'HomeWelcomeModal'
    options.width    = 710

    super options, data

    kd.singletons.router.once 'RouteInfoHandled', @bound 'destroy'


  viewAppended: ->

    super

    @addSubView new HomeWelcome

