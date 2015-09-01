$                    = require 'jquery'
kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
formatEmojiName      = require 'activity/util/formatEmojiName'
ActivityFlux         = require 'activity/flux'
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
    keyboardScroll : no


  formatSelectedValue: -> formatEmojiName @props.selectedItem


  close: ->

    { stateId } = @props
    ActivityFlux.actions.emoji.unsetFilteredListQuery stateId


  moveToNextPosition: (keyInfo) ->

    if @hasSingleItem() and keyInfo.isRightArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ActivityFlux.actions.emoji.moveToNextFilteredListIndex stateId

    return yes


  moveToPrevPosition: (keyInfo) ->

    if @hasSingleItem() and keyInfo.isLeftArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ActivityFlux.actions.emoji.moveToPrevFilteredListIndex stateId

    return yes


  checkTextForQuery: (textData) ->

    { currentWord } = textData
    return no  unless currentWord

    matchResult = currentWord.match /^\:(.+)/
    return no  unless matchResult

    query = matchResult[1]
    { stateId } = @props
    ActivityFlux.actions.emoji.setFilteredListQuery stateId, query
    return yes


  onItemSelected: (index) ->

    { stateId } = @props
    ActivityFlux.actions.emoji.setFilteredListSelectedIndex stateId, index


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
        key         = item
      />


  render: ->

    { query } = @props

    <Dropup
      className      = "EmojiDropup"
      visible        = { @isActive() }
      onOuterClick   = { @bound 'close' }
    >
      <div className="Dropup-header">
        Emojis matching <strong>:{query}</strong>
      </div>
      <div className="EmojiDropup-list">
        {@renderList()}
        <div className="clearfix" />
      </div>
    </Dropup>

