kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'

PrivateStacksList = require './components/privatestackslist'


module.exports = class HomeStacksPrivateStacks extends ReactView

  renderReact: ->
    <PrivateStacksList.Container />


