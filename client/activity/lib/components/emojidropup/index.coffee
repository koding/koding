$                    = require 'jquery'
kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
formatEmojiName      = require 'activity/util/formatEmojiName'
ChatInputFlux        = require 'activity/flux/chatinput'
Dropup               = require 'activity/components/dropup'
EmojiDropupItem      = require 'activity/components/emojidropupitem'
DropupWrapperMixin   = require 'activity/components/dropup/dropupwrappermixin'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class EmojiDropup extends React.Component

  @include [ImmutableRenderMixin, DropupWrapperMixin]


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

      <EmojiDropupItem
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

    <Dropup
      className    = "EmojiDropup"
      visible      = { @isActive() }
      onOuterClick = { @bound 'close' }
      ref          = 'dropup'
    >
      <div className="Dropup-innerContainer">
        <div className="Dropup-header">
          Emojis matching <strong>:{query}</strong>
        </div>
        <div className="EmojiDropup-list">
          {@renderList()}
          <div className="clearfix" />
        </div>
      </div>
    </Dropup>

