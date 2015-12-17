kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
Dropbox              = require 'activity/components/dropbox/portaldropbox'
ChannelDropboxItem   = require 'activity/components/channeldropboxitem'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class ChannelDropbox extends React.Component

  @include [ImmutableRenderMixin]


  @defaultProps =
    items          : immutable.List()
    selectedIndex  : 0
    selectedItem   : null


  getItemKey: (item) -> item.get 'id'


  updatePosition: (inputDimensions) ->

    @refs.dropbox.setInputDimensions inputDimensions


  renderList: ->

    { items, selectedIndex } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <ChannelDropboxItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @props.onItemSelected }
        onConfirmed = { @props.onItemConfirmed }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
      />


  render: ->

    { items } = @props

    <Dropbox
      className = 'ChannelDropbox'
      visible   = { items.size > 0 }
      onClose   = { @props.onClose }
      type      = 'dropup'
      title     = 'Channels'
      ref       = 'dropbox'
    >
      {@renderList()}
    </Dropbox>

