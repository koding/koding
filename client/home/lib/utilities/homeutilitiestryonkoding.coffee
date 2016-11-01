kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'
TryOnKoding = require './components/tryonkoding'


module.exports = class HomeUtilitiesTryOnKoding extends ReactView

  renderReact: ->
    <TryOnKoding.Container />
