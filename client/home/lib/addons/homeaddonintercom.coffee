React = require 'app/react'
ReactView = require 'app/react/reactview'
BusinessAddOnIntercom = require './components/businessaddonintercom'

module.exports = class HomeAddOnIntercom extends ReactView

  constructor: (options = {}, data) ->

    super options, data


  renderReact: -> <BusinessAddOnIntercom.Container />

