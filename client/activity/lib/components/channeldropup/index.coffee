kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
classnames           = require 'classnames'
ActivityFlux         = require 'activity/flux'
Dropup               = require 'activity/components/dropup'
ChannelDropupItem    = require 'activity/components/channeldropupitem'
DropupWrapperMixin   = require 'activity/components/dropup/dropupwrappermixin'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class ChannelDropup extends React.Component

  @include [ImmutableRenderMixin, DropupWrapperMixin]


  @defaultProps =
    items          : immutable.List()
    visible        : no
    selectedIndex  : 0
    selectedItem   : null


  formatSelectedValue: -> "##{@props.selectedItem.get 'name'}"


  getItemKey: (item) -> item.get 'id'


  close: ->

    { stateId } = @props
    ActivityFlux.actions.channel.setChatInputChannelsVisibility stateId, no


  moveToNextPosition: (keyInfo) ->

    if keyInfo.isRightArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ActivityFlux.actions.channel.moveToNextChatInputChannelsIndex stateId

    return yes


  moveToPrevPosition: (keyInfo) ->

    if keyInfo.isLeftArrow
      @close()
      return no

    { stateId } = @props
    unless @hasSingleItem()
      ActivityFlux.actions.channel.moveToPrevChatInputChannelsIndex stateId

    return yes


  checkTextForQuery: (textData) ->

    { currentWord } = textData
    return no  unless currentWord

    matchResult = currentWord.match /^#(.*)/
    return no  unless matchResult

    query = matchResult[1]
    { stateId } = @props
    ActivityFlux.actions.channel.setChatInputChannelsQuery stateId, query
    ActivityFlux.actions.channel.setChatInputChannelsVisibility stateId, yes
    return yes


  onItemSelected: (index) ->

    { stateId } = @props
    ActivityFlux.actions.channel.setChatInputChannelsSelectedIndex stateId, index


  renderList: ->

    { items, selectedIndex } = @props

    items.map (item, index) =>
      isSelected = index is selectedIndex

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

