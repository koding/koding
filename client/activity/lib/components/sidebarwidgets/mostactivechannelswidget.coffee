React                     = require 'kd-react'
immutable                 = require 'immutable'
Link                      = require 'app/components/common/link'
MostActiveChannelListItem = require './mostactivechannellistitem'

module.exports = class MostActiveChannelsWidget extends React.Component

  MAX_PREVIEW_COUNT = 5

  @defaultProps=
    popularChannels = immutable.Map()


  renderChannelList: ->

    return null  unless @props.popularChannels.size

    popularChannels = @props.popularChannels.slice 0, MAX_PREVIEW_COUNT

    popularChannels.toList().map (channel, index) ->
      <MostActiveChannelListItem key={channel.get 'id'} channel={channel} />


  render: ->
    <div className='MostActiveChannelsWidget ActivitySidebar-widget'>
      <h3>Most active channels</h3>
      <div>
        {@renderChannelList()}
      </div>
    </div>
