kd                      = require 'kd'
React                   = require 'kd-react'
immutable               = require 'immutable'
classnames              = require 'classnames'
ActivityFlux            = require 'activity/flux'
Dropup                  = require 'activity/components/dropup'
ChannelDropupItem       = require 'activity/components/channeldropupitem'
KeyboardNavigatedDropup = require 'activity/components/dropup/keyboardnavigateddropup'
KeyboardScrolledDropup  = require 'activity/components/dropup/keyboardscrolleddropup'
ImmutableRenderMixin    = require 'react-immutable-render-mixin'


module.exports = class ChannelDropup extends React.Component

  @include [ImmutableRenderMixin, KeyboardNavigatedDropup, KeyboardScrolledDropup]


  @defaultProps =
    items        : immutable.List()
    visible      : no
    selectedItem : null


  formatSelectedValue: -> "##{@props.selectedItem.get 'name'}"


  getItemKey: (item) -> item.get 'id'


  close: -> ActivityFlux.actions.channel.setChatInputChannelsVisibility no


  requestNextIndex: -> ActivityFlux.actions.channel.moveToNextChatInputChannelsIndex()


  requestPrevIndex: -> ActivityFlux.actions.channel.moveToPrevChatInputChannelsIndex()


  setQuery: (query) ->

    matchResult = query?.match /^#(.*)/
    if matchResult
      query = matchResult[1]
      ActivityFlux.actions.channel.setChatInputChannelsQuery query
      ActivityFlux.actions.channel.setChatInputChannelsVisibility yes
    else if @isActive()
      @close()


  onItemSelected: (index) ->

    ActivityFlux.actions.channel.setChatInputChannelsSelectedIndex index


  renderList: ->

    { items, selectedItem } = @props

    items.map (item, index) =>
      isSelected = item is selectedItem

      <ChannelDropupItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @bound 'onItemSelected' }
        onConfirmed = { @bound 'confirmSelectedItem' }
        key         = { @getItemKey item }
        ref         = { @getItemKey item }
      />


  render: ->

    <Dropup
      className      = "ChannelDropup"
      visible        = { @isActive() }
      onOuterClick   = { @bound 'close' }
      ref            = 'dropup'
    >
      <div className="Dropup-innerContainer">
        <div className="Dropup-header">
          Channels
        </div>
        <div className="ChannelDropup-list">
          {@renderList()}
        </div>
      </div>
    </Dropup>
