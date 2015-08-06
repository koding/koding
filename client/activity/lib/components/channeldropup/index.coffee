$                 = require 'jquery'
kd                = require 'kd'
React             = require 'kd-react'
classnames        = require 'classnames'
ActivityFlux      = require 'activity/flux'
Dropup            = require 'activity/components/dropup'
ChannelDropupItem = require 'activity/components/channeldropupitem'


module.exports = class ChannelDropup extends React.Component

  isActive: -> @props.items?.size > 0


  hasOnlyItem: -> @props.items?.size is 1


  confirmSelectedItem: ->

    { selectedItem } = @props
    
    @props.onItemConfirmed? "##{selectedItem.get 'name'}"
    @clearQuery()


  clearQuery: ->

    ActivityFlux.actions.channel.unsetChatInputChannelsQuery()


  moveToNextPosition: ->

    if @hasOnlyItem()
      @clearQuery()
      return no
    else
      ActivityFlux.actions.channel.moveToNextChatInputChannelsIndex()
      return yes


  moveToPrevPosition: ->

    if @hasOnlyItem()
      @clearQuery()
      return no
    else
      ActivityFlux.actions.channel.moveToPrevChatInputChannelsIndex()
      return yes


  setQuery: (query) ->

    matchResult = query?.match /^#(.+)/
    query = matchResult?[1]

    if @isActive() or query
      ActivityFlux.actions.channel.setChatInputChannelsQuery query


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
        key         = { item.get 'id' }
      />


  render: ->

    { items, query } = @props

    <Dropup
      className      = "ChannelDropup"
      items          = { items }
      visible        = { @isActive() }
      onOuterClick   = { @bound 'clearQuery' }
    >
      <div className="Dropup-header">
        Channels
      </div>
      <div className="ChannelDropup-list">
        {@renderList()}
      </div>
    </Dropup>
