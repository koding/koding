_               = require 'lodash'
kd              = require 'kd'
React           = require 'kd-react'
globals         = require 'globals'
whoami          = require 'app/util/whoami'
Tracker         = require 'app/util/tracker'
copyToClipboard = require 'app/util/copyToClipboard'
View            = require './view'

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
        kontrolUrl = if globals.config.environment in ['dev', 'sandbox']
        then "export KONTROLURL=#{globals.config.newkontrol.url}; "
        else ''
        "#{kontrolUrl}curl -sL https://kodi.ng/d/kd | bash -s #{token}"
      
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
