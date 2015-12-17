$                    = require 'jquery'
kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
Dropbox              = require 'activity/components/dropbox/portaldropbox'
EmojiDropboxItem     = require 'activity/components/emojidropboxitem'
ImmutableRenderMixin = require 'react-immutable-render-mixin'
EmojiBoxWrapperMixin = require 'activity/components/emojiboxwrapper/mixin'


module.exports = class EmojiDropbox extends React.Component

  @include [ImmutableRenderMixin, EmojiBoxWrapperMixin]


  @defaultProps =
    items          : immutable.List()
    selectedIndex  : 0
    selectedItem   : null
    query          : ''


  getItemKey: (item) -> item


  updatePosition: (inputDimensions) ->

    @refs.dropbox.setInputDimensions inputDimensions


  renderList: ->

    { items, selectedIndex, query } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <EmojiDropboxItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        query       = { query }
        onSelected  = { @props.onItemSelected }
        onConfirmed = { @props.onItemConfirmed }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
      />


  render: ->

    { query, items } = @props

    <Dropbox
      className = 'EmojiDropbox'
      visible   = { items.size > 0 }
      onClose   = { @props.onClose }
      type      = 'dropup'
      title     = 'Emojis matching '
      subtitle  = { ":#{query}" }
      ref       = 'dropbox'
    >
      {@renderList()}
      <div className="clearfix" />
    </Dropbox>

