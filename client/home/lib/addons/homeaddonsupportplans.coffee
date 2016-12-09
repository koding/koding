React = require 'app/react'
ReactView = require 'app/react/reactview'
SupportPlans = require './components/supportplans'

module.exports = class HomeAddOnSupportPlans extends ReactView

  constructor: (options = {}, data) ->

    super options, data


  renderReact: -> <SupportPlans.Container />

