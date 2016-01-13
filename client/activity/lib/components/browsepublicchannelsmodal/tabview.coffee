kd         = require 'kd'
React      = require 'kd-react'
Tabs       = require 'activity/constants/sidebarpublicchannelstabs'
classnames = require 'classnames'

module.exports = class BrowsePublicChannelsModalTabView extends React.Component

  @propTypes =
    className : React.PropTypes.string
    activeTab : React.PropTypes.string

  @defaultProps =
    className : ''
    activeTab : ''

  onYourChannelsClick: -> @props.onChange Tabs.YourChannels


  onOtherChannelsClick: -> @props.onChange Tabs.OtherChannels


  getTabClassName: (isYoursChannels) ->

    { activeTab } = @props

    isActive = if isYoursChannels
    then activeTab is Tabs.YourChannels
    else activeTab is Tabs.OtherChannels

    return classnames
      'ChannelList-tab' : yes
      'active-tab'      : isActive


  render: ->

    <div className={kd.utils.curry 'ChannelList-tabs', @props.className}>
      <div ref='yourChannels' className={@getTabClassName yes} onClick={@bound 'onYourChannelsClick'}>Your Channels</div>
      <div ref='otherChannels' className={@getTabClassName no} onClick={@bound 'onOtherChannelsClick'}>Other Channels</div>
      <div className='clearfix'></div>
    </div>
