kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'
StackscriptSearchBox = require '../components/stackscriptsearchbox'


module.exports = class StackScriptSearchView extends ReactView

  renderReact: ->
    <StackscriptSearchBox.Container />
