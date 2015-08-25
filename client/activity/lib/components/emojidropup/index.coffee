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


  formatSelectedValue: -> formatEmojiName @props.selectedItem


  getItemKey: (item) -> item


  close: -> ActivityFlux.actions.emoji.unsetFilteredListQuery()


  moveToNextPosition: (keyInfo) ->

    if @hasSingleItem() and keyInfo.isRightArrow
      @close()
      return no

    ActivityFlux.actions.emoji.moveToNextFilteredListIndex()  unless @hasSingleItem()
    return yes


  moveToPrevPosition: (keyInfo) ->

    if @hasSingleItem() and keyInfo.isLeftArrow
      @close()
      return no

    ActivityFlux.actions.emoji.moveToPrevFilteredListIndex()  unless @hasSingleItem()
    return yes


  checkTextForQuery: (textData) ->

    { currentWord } = textData
    return no  unless currentWord

    matchResult = currentWord.match /^\:(.+)/
    return no  unless matchResult

    query = matchResult[1]
    ActivityFlux.actions.emoji.setFilteredListQuery query
    return yes


  onItemSelected: (index) ->

    ActivityFlux.actions.emoji.setFilteredListSelectedIndex index


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

