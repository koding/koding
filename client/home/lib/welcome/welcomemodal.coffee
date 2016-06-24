kd = require 'kd'
HomeWelcome = require './'

module.exports = class WelcomeModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = 'HomeWelcomeModal'
    options.width    = 660

    super options, data



  viewAppended: ->

    super

    @addSubView new HomeWelcome

