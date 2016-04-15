kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'

DesktopApp = require './components/desktopapp/view.coffee'

module.exports = class HomeUtilitiesDesktopApp extends ReactView

  renderReact: ->
    <DesktopApp />
