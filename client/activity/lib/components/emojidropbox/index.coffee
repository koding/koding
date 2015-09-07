$                    = require 'jquery'
kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
formatEmojiName      = require 'activity/util/formatEmojiName'
ChatInputFlux        = require 'activity/flux/chatinput'
Dropbox              = require 'activity/components/dropbox'
EmojiDropboxItem     = require 'activity/components/emojidropboxitem'
DropboxWrapperMixin  = require 'activity/components/dropbox/dropboxwrappermixin'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class EmojiDropbox extends React.Component

  @include [ImmutableRenderMixin, DropboxWrapperMixin]


  @defaultProps =
    items          : immutable.List()
    selectedIndex  : 0
    selectedItem   : null


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

    { currentWord } = textData
    return no  unless currentWord

    matchResult = currentWord.match /^\:(.+)/
    return no  unless matchResult

    query = matchResult[1]
    { stateId } = @props
    ChatInputFlux.actions.emoji.setFilteredListQuery stateId, query
    return yes


  onItemSelected: (index) ->

    { stateId } = @props
    ChatInputFlux.actions.emoji.setFilteredListSelectedIndex stateId, index


  renderList: ->

    { items, selectedIndex } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

      <EmojiDropboxItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @bound 'onItemSelected' }
        onConfirmed = { @bound 'confirmSelectedItem' }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
      />


  render: ->

    { query } = @props

    <Dropbox
      className    = 'EmojiDropbox'
      visible      = { @isActive() }
      onOuterClick = { @bound 'close' }
      direction    = 'up'
      ref          = 'dropbox'
    >
      <div className="Dropbox-innerContainer">
        <div className="Dropbox-header">
          Emojis matching <strong>:{query}</strong>
        </div>
        <div className="EmojiDropbox-list">
          {@renderList()}
          <div className="clearfix" />
        </div>
      </div>
    </Dropbox>

