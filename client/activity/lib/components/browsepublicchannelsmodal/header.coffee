kd         = require 'kd'
React      = require 'kd-react'
Tabs       = require 'activity/constants/sidebarpublicchannelstabs'
classnames = require 'classnames'

module.exports = class Header extends React.Component

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