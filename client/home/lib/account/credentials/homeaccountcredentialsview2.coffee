kd = require 'kd'
React = require 'app/react'
ReactView = require 'app/react/reactview'
CredentialList = require './components/'

module.exports = class HomeAccountCredentialsView2 extends ReactView

  renderReact: ->
    <CredentialList.Container />


