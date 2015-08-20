kd                           = require 'kd'
React                        = require 'kd-react'
immutable                    = require 'immutable'
classnames                   = require 'classnames'
ActivityFlux                 = require 'activity/flux'
Dropup                       = require 'activity/components/dropup'
ChannelDropupItem            = require 'activity/components/channeldropupitem'
KeyboardNavigatedDropupMixin = require 'activity/components/dropup/keyboardnavigateddropupmixin'
KeyboardScrolledDropupMixin  = require 'activity/components/dropup/keyboardscrolleddropupmixin'
ImmutableRenderMixin         = require 'react-immutable-render-mixin'


module.exports = class ChannelDropup extends React.Component

  @include [ImmutableRenderMixin, KeyboardNavigatedDropupMixin, KeyboardScrolledDropupMixin]


  @defaultProps =
    items        : immutable.List()
    visible      : no
    selectedItem : null


  formatSelectedValue: -> "##{@props.selectedItem.get 'name'}"


  getItemKey: (item) -> item.get 'id'


  close: -> ActivityFlux.actions.channel.setChatInputChannelsVisibility no


  requestNextIndex: -> ActivityFlux.actions.channel.moveToNextChatInputChannelsIndex()


  requestPrevIndex: -> ActivityFlux.actions.channel.moveToPrevChatInputChannelsIndex()


  checkTextForQuery: (textData) ->

    { currentWord } = textData

    matchResult = currentWord?.match /^#(.*)/
    if matchResult
      query = matchResult[1]
      ActivityFlux.actions.channel.setChatInputChannelsQuery query
      ActivityFlux.actions.channel.setChatInputChannelsVisibility yes
      return yes


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
