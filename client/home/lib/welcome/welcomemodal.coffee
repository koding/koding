kd = require 'kd'
HomeWelcome = require './'

module.exports = class WelcomeModal extends kd.ModalView

  viewAppended: ->

    super

    @addSubView new HomeWelcome

