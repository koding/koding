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

    { actionInitiatorId } = @props
    ActivityFlux.actions.emoji.unsetFilteredListQuery actionInitiatorId


  moveToNextPosition: (keyInfo) ->

    if @hasSingleItem() and keyInfo.isRightArrow
      @close()
      return no

    { actionInitiatorId } = @props
    unless @hasSingleItem()
      ActivityFlux.actions.emoji.moveToNextFilteredListIndex actionInitiatorId

    return yes


  moveToPrevPosition: (keyInfo) ->

    if @hasSingleItem() and keyInfo.isLeftArrow
      @close()
      return no

    { actionInitiatorId } = @props
    unless @hasSingleItem()
      ActivityFlux.actions.emoji.moveToPrevFilteredListIndex actionInitiatorId

    return yes


  checkTextForQuery: (textData) ->

    { currentWord } = textData
    return no  unless currentWord

    matchResult = currentWord.match /^\:(.+)/
    return no  unless matchResult

    query = matchResult[1]
    { actionInitiatorId } = @props
    ActivityFlux.actions.emoji.setFilteredListQuery actionInitiatorId, query
    return yes


  onItemSelected: (index) ->

    { actionInitiatorId } = @props
    ActivityFlux.actions.emoji.setFilteredListSelectedIndex actionInitiatorId, index


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

