kd        = require 'kd'
View      = require './view'
React     = require 'kd-react'
immutable = require 'immutable'

module.exports = class ChannelInfoContainer extends React.Component

  @propTypes =
    channel       : React.PropTypes.instanceOf immutable.Map
    onInviteClick : React.PropTypes.func.isRequired


  @defaultProps =
    channel       : immutable.Map()


  constructor: (props) ->

    super props

    @state = { collabTooltipVisible: no, integrationTooltipVisible: no }


  onCollaborationClick: (event) ->

    kd.utils.stopDOMEvent event

    @setState collabTooltipVisible: yes

    kd.utils.wait 2000, => @setState collabTooltipVisible: no


  onIntegrationClick: (event) ->

    kd.utils.stopDOMEvent event

    @setState integrationTooltipVisible: yes

    kd.utils.wait 2000, => @setState integrationTooltipVisible: no


  onInviteClick: (event) ->

    kd.utils.stopDOMEvent event

    @props.onInviteClick?()


  render: ->

    <View
      channel={@props.channel}
      onInviteClick={@bound 'onInviteClick'}
      onIntegrationClick={@bound 'onIntegrationClick'}
      onCollaborationClick={@bound 'onCollaborationClick'}
      integrationTooltipVisible={@state.integrationTooltipVisible}
      collabTooltipVisible={@state.collabTooltipVisible} />

