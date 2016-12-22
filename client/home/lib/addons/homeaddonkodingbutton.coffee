React = require 'app/react'
ReactView = require 'app/react/reactview'
BusinessAddOnKodingButton = require './components/businessaddonkodingbutton'

module.exports = class HomeAddOnKodingButton extends ReactView

  constructor: (options = {}, data) ->

    super options, data


  renderReact: -> <BusinessAddOnKodingButton.Container />
