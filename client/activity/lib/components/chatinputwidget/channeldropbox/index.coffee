kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
PortalDropbox        = require 'activity/components/dropbox/portaldropbox'
ChannelDropboxItem   = require './item'
DropboxItem          = require 'activity/components/dropboxitem'
ImmutableRenderMixin = require 'react-immutable-render-mixin'
ScrollableDropbox    = require 'activity/components/dropbox/scrollabledropbox'

class ChannelDropbox extends React.Component

  @propTypes =
    query           : React.PropTypes.string
    items           : React.PropTypes.instanceOf immutable.List
    selectedItem    : React.PropTypes.instanceOf immutable.Map
    selectedIndex   : React.PropTypes.number
    onItemSelected  : React.PropTypes.func
    onItemConfirmed : React.PropTypes.func
    onClose         : React.PropTypes.func


  @defaultProps =
    query           : ''
    items           : immutable.List()
    selectedItem    : null
    selectedIndex   : 0
    onItemSelected  : kd.noop
    onItemConfirmed : kd.noop
    onClose         : kd.noop


  updatePosition: (inputDimensions) ->

    @refs.dropbox.setInputDimensions inputDimensions


  renderList: ->

    { items, selectedIndex, onItemSelected, onItemConfirmed } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <ChannelDropboxItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { onItemSelected }
        onConfirmed = { onItemConfirmed }
        key         = { item.get 'id' }
      />


  renderNewChannelSuggestion: ->

    { items } = @props
    return  if items.size > 0

    <DropboxItem className='DropboxItem-singleLine ChannelDropbox-newChannelSuggestion'>
      Do you want to create this channel?
    </DropboxItem>


  render: ->

    { items, query, onClose } = @props

    <PortalDropbox
      className = 'ChannelDropbox'
      visible   = { items.size > 0 or Boolean query }
      onClose   = { onClose }
      type      = 'dropup'
      title     = 'Channels'
      ref       = 'dropbox'
    >
      {@renderList()}
      {@renderNewChannelSuggestion()}
    </PortalDropbox>


ChannelDropbox.include [ ImmutableRenderMixin ]

module.exports = ScrollableDropbox ChannelDropbox
