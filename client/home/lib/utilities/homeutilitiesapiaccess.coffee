kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'
ApiAcess = require './components/apiaccess'


module.exports = class HomeUtilitiesApiAccess extends ReactView

  renderReact: ->
    <ApiAcess.Container />
