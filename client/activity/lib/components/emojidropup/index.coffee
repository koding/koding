$                       = require 'jquery'
kd                      = require 'kd'
React                   = require 'kd-react'
immutable               = require 'immutable'
classnames              = require 'classnames'
formatEmojiName         = require 'activity/util/formatEmojiName'
ActivityFlux            = require 'activity/flux'
Dropup                  = require 'activity/components/dropup'
EmojiDropupItem         = require 'activity/components/emojidropupitem'
KeyboardNavigatedDropup = require 'activity/components/dropup/keyboardnavigateddropup'
ImmutableRenderMixin    = require 'react-immutable-render-mixin'


module.exports = class EmojiDropup extends React.Component

  @include [ImmutableRenderMixin, KeyboardNavigatedDropup]


  @defaultProps =
    items        : immutable.List()
    selectedItem : null


  formatSelectedValue: -> formatEmojiName @props.selectedItem


  close: -> ActivityFlux.actions.emoji.unsetFilteredListQuery()


  requestNextIndex: -> ActivityFlux.actions.emoji.moveToNextFilteredListIndex()


  requestPrevIndex: -> ActivityFlux.actions.emoji.moveToPrevFilteredListIndex()


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
