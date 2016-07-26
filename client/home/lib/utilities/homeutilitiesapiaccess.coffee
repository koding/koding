kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'
ApiAcess = require './components/apiaccess'


module.exports = class HomeUtilitiesApiAccess extends ReactView

  renderReact: ->
    <ApiAcess.Container />
