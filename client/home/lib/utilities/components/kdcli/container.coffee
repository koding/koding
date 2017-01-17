kd = require 'kd'
React = require 'app/react'
globals = require 'globals'
whoami = require 'app/util/whoami'
Tracker = require 'app/util/tracker'
copyToClipboard = require 'app/util/copyToClipboard'
View  = require './view'
TeamFlux = require 'app/flux/teams'
KDReactorMixin = require 'app/flux/base/reactormixin'

module.exports = class KDCliContainer extends React.Component

  getDataBindings: ->

    return {
      otaToken: TeamFlux.getters.otaToken
    }


  constructor: (props) ->

    super props

    @state =
      key : if globals.os is 'mac' then '⌘ + C' else 'Ctrl + C'


  onCMDClick: ->

    codeblock =  @refs.view.refs.codeblock
    copyToClipboard codeblock

    Tracker.track Tracker.KD_INSTALLED


  render: ->

    <View
      ref='view'
      copyKey={@state.key}
      cmd={@state.otaToken}
      onCMDClick={@bound 'onCMDClick'} />

KDCliContainer.include [KDReactorMixin]
