kd                     = require 'kd'
React                  = require 'kd-react'
immutable              = require 'immutable'
classnames             = require 'classnames'
Dropbox                = require 'activity/components/dropbox/portaldropbox'
ChannelDropboxItem     = require 'activity/components/channeldropboxitem'
ImmutableRenderMixin   = require 'react-immutable-render-mixin'
ScrollableDropboxMixin = require 'activity/components/dropbox/scrollabledropboxmixin'

module.exports = class ChannelDropbox extends React.Component

  @defaultProps =
    query           : ''
    items           : immutable.List()
    selectedItem    : null
    selectedIndex   : 0
    flags           : null
    onItemSelected  : kd.noop
    onItemConfirmed : kd.noop
    onClose         : kd.noop


  getItemKey: (item) -> item.get 'id'


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
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
      />


  render: ->

    { items, onClose } = @props

    <Dropbox
      className = 'ChannelDropbox'
      visible   = { items.size > 0 }
      onClose   = { onClose }
      type      = 'dropup'
      title     = 'Channels'
      ref       = 'dropbox'
    >
      {@renderList()}
    </Dropbox>


ChannelDropbox.include [ ImmutableRenderMixin, ScrollableDropboxMixin ]

