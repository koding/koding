$                      = require 'jquery'
kd                     = require 'kd'
React                  = require 'kd-react'
immutable              = require 'immutable'
classnames             = require 'classnames'
Dropbox                = require 'activity/components/dropbox/portaldropbox'
EmojiDropboxItem       = require 'activity/components/emojidropboxitem'
ImmutableRenderMixin   = require 'react-immutable-render-mixin'
ScrollableDropboxMixin = require 'activity/components/dropbox/scrollabledropboxmixin'

module.exports = class EmojiDropbox extends React.Component

  @propTypes =
    query           : React.PropTypes.string
    items           : React.PropTypes.instanceOf immutable.List
    selectedItem    : React.PropTypes.string
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


  getItemKey: (item) -> item


  updatePosition: (inputDimensions) ->

    @refs.dropbox.setInputDimensions inputDimensions


  renderList: ->

    { items, selectedIndex, query, onItemSelected, onItemConfirmed } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <EmojiDropboxItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        query       = { query }
        onSelected  = { onItemSelected }
        onConfirmed = { onItemConfirmed }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
      />


  render: ->

    { query, items, onClose } = @props

    <Dropbox
      className = 'EmojiDropbox'
      visible   = { items.size > 0 }
      onClose   = { onClose }
      type      = 'dropup'
      title     = 'Emojis matching '
      subtitle  = { ":#{query}" }
      ref       = 'dropbox'
    >
      {@renderList()}
      <div className="clearfix" />
    </Dropbox>


EmojiDropbox.include [ ImmutableRenderMixin, ScrollableDropboxMixin ]

