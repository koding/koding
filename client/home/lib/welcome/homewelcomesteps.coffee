kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'
WelcomeSteps = require './components/welcomesteps'

module.exports = class HomeWelcomeSteps extends ReactView

  constructor: (options = {}, data) ->

    options.mini ?= no

    super options, data


  renderReact: ->

    <WelcomeSteps.Container kdParent={this} mini={ @getOption('mini') or no } />
