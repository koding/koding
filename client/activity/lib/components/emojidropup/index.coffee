$               = require 'jquery'
kd              = require 'kd'
React           = require 'kd-react'
classnames      = require 'classnames'
formatEmojiName = require 'activity/util/formatEmojiName'
ActivityFlux    = require 'activity/flux'
Dropup          = require 'activity/components/dropup'
EmojiDropupItem = require 'activity/components/emojidropupitem'


module.exports = class EmojiDropup extends React.Component

  isActive: -> @props.items?.size > 0


  hasOnlyItem: -> @props.items?.size is 1


  confirmSelectedItem: ->

    { selectedItem } = @props

    @props.onItemConfirmed? formatEmojiName selectedItem
    @close()


  close: ->

    ActivityFlux.actions.emoji.unsetFilteredListQuery()


  moveToNextPosition: ->

    if @hasOnlyItem()
      @close()
      return no
    else
      ActivityFlux.actions.emoji.moveToNextFilteredListIndex()
      return yes


  moveToPrevPosition: ->

    if @hasOnlyItem()
      @close()
      return no
    else
      ActivityFlux.actions.emoji.moveToPrevFilteredListIndex()
      return yes


  setQuery: (query) ->

    matchResult = query?.match /^\:(.+)/
    query = matchResult?[1]

    if @isActive() or query
      ActivityFlux.actions.emoji.setFilteredListQuery query


  onItemSelected: (index) ->

    ActivityFlux.actions.emoji.setFilteredListSelectedIndex index


  renderList: ->

    { items, selectedItem } = @props

    items.map (item, index) =>
      isSelected = item is selectedItem

      <EmojiDropupItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @bound 'onItemSelected' }
        onConfirmed = { @bound 'confirmSelectedItem' }
        key         = item
      />


  render: ->

    { items, query } = @props

    <Dropup
      className      = "EmojiDropup"
      items          = { items }
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
