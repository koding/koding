kd         = require 'kd'
React      = require 'kd-react'

module.exports = class BrowsePublicChannelsModalHeaderView extends React.Component

  @propTypes =
    query               : React.PropTypes.string
    onSearchInputChange : React.PropTypes.func

  @defaultProps =
    query               : ''
    onSearchInputChange : kd.noop

  render: ->

    <div>
      <div className='ChannelList-title'>Channels</div>
      <div>
        <input
          className   = 'ChannelList-searchInput'
          placeholder = 'Search'
          ref         = 'ChannelSearchInput'
          value       = { @props.query }
          onChange    = { @props.onSearchInputChange }
        />
      </div>
    </div>