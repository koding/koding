$                 = require 'jquery'
kd                = require 'kd'
React             = require 'kd-react'
classnames        = require 'classnames'
ActivityFlux      = require 'activity/flux'
Dropup            = require 'activity/components/dropup'
ChannelDropupItem = require 'activity/components/channeldropupitem'


module.exports = class ChannelDropup extends React.Component

  isActive: ->

    { items, visible } = @props
    return items?.size > 0 and visible


  hasOnlyItem: -> @props.items?.size is 1


  confirmSelectedItem: ->

    { selectedItem } = @props
    
    @props.onItemConfirmed? "##{selectedItem.get 'name'}"
    @close()


  close: ->

    ActivityFlux.actions.channel.setChatInputChannelsVisibility no


  moveToNextPosition: ->

    if @hasOnlyItem()
      @close()
      return no
    else
      ActivityFlux.actions.channel.moveToNextChatInputChannelsIndex()
      return yes


  moveToPrevPosition: ->

    if @hasOnlyItem()
      @close()
      return no
    else
      ActivityFlux.actions.channel.moveToPrevChatInputChannelsIndex()
      return yes


  setQuery: (query) ->

    matchResult = query?.match /^#(.*)/
    if matchResult
      query = matchResult[1]
      ActivityFlux.actions.channel.setChatInputChannelsQuery query
      ActivityFlux.actions.channel.setChatInputChannelsVisibility yes
    else
      @close()


  componentDidUpdate: (prevProps, prevState) ->

    { selectedItem } = @props
    return  if prevProps.selectedItem is selectedItem or not selectedItem

    containerElement = $ @refs.dropup.getMainElement()
    itemElement      = $ React.findDOMNode @refs[selectedItem.get 'id']

    containerScrollTop    = containerElement.scrollTop()
    containerHeight       = containerElement.height()
    containerScrollBottom = containerScrollTop + containerHeight
    itemTop               = itemElement.position().top
    itemHeight            = itemElement.outerHeight()
    itemBottom            = itemTop + itemHeight

    # scroll container if selected item is outside the visible area
    if itemBottom > containerScrollBottom
      scrollTop = if itemElement.next().length > 0
      then itemBottom - containerHeight
      else containerElement.get(0).scrollHeight

      containerElement.scrollTop scrollTop
    else if itemTop < containerScrollTop
      scrollTop = if itemElement.prev().length then itemTop else 0
      containerElement.scrollTop scrollTop


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
        ref         = { item.get 'id' }
      />


  render: ->

    { items, query } = @props

    <Dropup
      className      = "ChannelDropup"
      items          = { items }
      visible        = { @isActive() }
      onOuterClick   = { @bound 'close' }
      ref            = 'dropup'
    >
      <div className="ChannelDropup-innerContainer">
        <div className="Dropup-header">
          Channels
        </div>
        <div className="ChannelDropup-list">
          {@renderList()}
        </div>
      </div>
    </Dropup>
