kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'
TryOnKoding = require './components/tryonkoding'


module.exports = class HomeUtilitiesTryOnKoding extends ReactView

  renderReact: ->
    <TryOnKoding.Container />
