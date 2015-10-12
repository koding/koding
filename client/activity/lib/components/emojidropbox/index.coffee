$                    = require 'jquery'
kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
formatEmojiName      = require 'activity/util/formatEmojiName'
ChatInputFlux        = require 'activity/flux/chatinput'
Dropbox              = require 'activity/components/dropbox/portaldropbox'
EmojiDropboxItem     = require 'activity/components/emojidropboxitem'
DropboxWrapperMixin  = require 'activity/components/dropbox/dropboxwrappermixin'
ImmutableRenderMixin = require 'react-immutable-render-mixin'
isWithinCodeBlock    = require 'app/util/isWithinCodeBlock'


module.exports = class EmojiDropbox extends React.Component

  @include [ImmutableRenderMixin, DropboxWrapperMixin]


  @defaultProps =
    items          : immutable.List()
    selectedIndex  : 0
    selectedItem   : null
    query          : ''


  formatSelectedValue: -> formatEmojiName @props.selectedItem


  getItemKey: (item) -> item


  close: ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.unsetFilteredListQuery stateId


  moveToNextPosition: (keyInfo) ->

    if @hasSingleItem() and keyInfo.isRightArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ChatInputFlux.actions.emoji.moveToNextFilteredListIndex stateId

    return yes


  moveToPrevPosition: (keyInfo) ->

    if @hasSingleItem() and keyInfo.isLeftArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ChatInputFlux.actions.emoji.moveToPrevFilteredListIndex stateId

    return yes


  checkTextForQuery: (textData) ->

    { currentWord, value, position } = textData
    return no  unless currentWord

    matchResult = currentWord.match /^\:(.+)/
    return no  unless matchResult
    return no  if isWithinCodeBlock value, position

    query = matchResult[1]
    { stateId } = @props
    ChatInputFlux.actions.emoji.setFilteredListQuery stateId, query
    return yes


  onItemSelected: (index) ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.setFilteredListSelectedIndex stateId, index


  renderList: ->

    { items, selectedIndex, query } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <EmojiDropboxItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        query       = { query }
        onSelected  = { @bound 'onItemSelected' }
        onConfirmed = { @bound 'confirmSelectedItem' }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
      />


  render: ->

    { query } = @props

    <Dropbox
      className = 'EmojiDropbox'
      visible   = { @isActive() }
      onClose   = { @bound 'close' }
      type      = 'dropup'
      title     = 'Emojis matching '
      subtitle  = { ":#{query}" }
      ref       = 'dropbox'
    >
      {@renderList()}
      <div className="clearfix" />
    </Dropbox>

