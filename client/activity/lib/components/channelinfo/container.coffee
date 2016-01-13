kd        = require 'kd'
View      = require './view'
React     = require 'kd-react'
immutable = require 'immutable'

module.exports = class ChannelInfoContainer extends React.Component

  @propTypes =
    channel        : React.PropTypes.instanceOf immutable.Map
    onInviteOthers : React.PropTypes.func


  @defaultProps =
    channel        : immutable.Map()
    onInviteOthers : kd.noop


  constructor: (props) ->

    super props

    @state = { collabTooltipVisible: no, integrationTooltipVisible: no }


  onCollaborationHelp: (event) ->

    kd.utils.stopDOMEvent event

    @setState collabTooltipVisible: yes

    kd.utils.wait 2000, => @setState collabTooltipVisible: no


  onIntegrationHelp: (event) ->

    kd.utils.stopDOMEvent event

    @setState integrationTooltipVisible: yes

    kd.utils.wait 2000, => @setState integrationTooltipVisible: no


  onInviteOthers: (event) ->

    kd.utils.stopDOMEvent event

    @props.onInviteOthers?()


  render: ->

    <View
      channel={@props.channel}
      onInviteOthers={@bound 'onInviteOthers'}
      onIntegrationHelp={@bound 'onIntegrationHelp'}
      onCollaborationHelp={@bound 'onCollaborationHelp'}
      integrationTooltipVisible={@state.integrationTooltipVisible}
      collabTooltipVisible={@state.collabTooltipVisible} />

