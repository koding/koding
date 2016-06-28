kd               = require 'kd'
HomeWelcomeSteps = require './homewelcomesteps'

module.exports = class HomeWelcome extends kd.CustomScrollView

  constructor:(options = {}, data) ->

    options.cssClass = kd.utils.curry 'WelcomeStacksView', options.cssClass

    super options, data


  viewAppended: ->

    super

    @wrapper.addSubView new HomeWelcomeSteps
