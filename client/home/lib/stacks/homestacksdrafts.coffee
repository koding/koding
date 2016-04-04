kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'

DraftsList = require './components/draftslist'


module.exports = class HomeStacksDrafts extends ReactView

  renderReact: ->
    <DraftsList />


