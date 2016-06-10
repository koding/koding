_               = require 'lodash'
kd              = require 'kd'
React           = require 'kd-react'
globals         = require 'globals'
whoami          = require 'app/util/whoami'
Tracker         = require 'app/util/tracker'
copyToClipboard = require 'app/util/copyToClipboard'
View            = require './view'
KodingKontrol   = require 'app/kite/kodingkontrol'


module.exports = class KDCliContainer extends React.Component

  constructor: (props) ->

    super props

    @state=
      key : ''
      cmd : ''


  componentWillMount: ->

    whoami().fetchOtaToken (err, token) =>

      key = if globals.os is 'mac' then '⌘ + C' else 'Ctrl + C'
      cmd = if err
        "<a href='#'>Failed to generate your command, click to try again!</a>"
      else
        if globals.config.environment in ['dev', 'default', 'sandbox']
          "export KONTROLURL=#{KodingKontrol.getKontrolUrl()}; curl -sL https://sandbox.kodi.ng/c/d/kd | bash -s #{token}"
        else "curl -sL https://kodi.ng/d/kd | bash -s #{token}"

      console.log {cmd}

      @setState
        key : key
        cmd : cmd


  onCMDClick: ->

    codeblock =  @refs.view.refs.codeblock
    copyToClipboard codeblock

    Tracker.track Tracker.KD_INSTALLED


  render: ->

    <View
      ref='view'
      copyKey={@state.key}
      cmd={@state.cmd}
      onCMDClick={@bound 'onCMDClick'} />
