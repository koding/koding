kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
Encoder              = require 'htmlencode'
ButtonWithMenu       = require 'app/components/buttonwithmenu'
ChannelLabel         = require 'activity/components/channellabel'
VideoComingSoonModal = require 'activity/components/videocomingsoonmodal'
StartVideoCallLink   = require 'activity/components/common/startvideocalllink'

module.exports = class ChannelThreadHeaderView extends React.Component

  @propTypes =
    menuItems                : React.PropTypes.array
    className                : React.PropTypes.string
    isModalOpen              : React.PropTypes.bool
    editingPurpose           : React.PropTypes.bool
    onKeyDown                : React.PropTypes.func.isRequired
    onVideoStart             : React.PropTypes.func.isRequired
    onClose                  : React.PropTypes.func.isRequired
    onChange                 : React.PropTypes.func.isRequired
    thread                   : React.PropTypes.instanceOf immutable.Map


  @defaultProps =
    menuItems                : []
    className                : ''
    isModalOpen              : no
    editingPurpose           : no
    thread                   : immutable.Map()


  getPurposeAreaClassNames: -> classnames
    'ChannelThreadPane-purposeWrapper': yes
    'editing': @props.editingPurpose


  renderPurposeArea: ->

    purpose = Encoder.htmlDecode @props.thread.getIn ['channel', 'purpose']

    valueLink =
      value         : purpose
      requestChange : @props.onChange

    <div className={@getPurposeAreaClassNames()}>
      <span className='ChannelThreadPane-purpose'>{purpose}</span>
      <input
        ref='purposeInput'
        type='text'
        valueLink={valueLink}
        onKeyDown={@props.onKeyDown} />
    </div>


  render: ->

    return null  unless @props.thread

    <div className={kd.utils.curry "ThreadHeader", @props.className}>
      <ChannelLabel channel={@props.thread.get 'channel'} />
      <ButtonWithMenu
        listClass='ChannelThreadPane-menuItems'
        items={@props.menuItems} />
      {@renderPurposeArea()}
      <StartVideoCallLink onStart={@props.onVideoStart}/>
      <VideoComingSoonModal
        onClose={@props.onClose}
        isOpen={@props.isModalOpen}/>
    </div>
