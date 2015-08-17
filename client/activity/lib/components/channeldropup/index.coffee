kd                = require 'kd'
React             = require 'kd-react'
immutable         = require 'immutable'
classnames        = require 'classnames'
ActivityFlux      = require 'activity/flux'
Dropup            = require 'activity/components/dropup'
ChannelDropupItem = require 'activity/components/channeldropupitem'
scrollToTarget    = require 'activity/util/scrollToTarget'


module.exports = class ChannelDropup extends React.Component

  @defaultProps =
    items        : immutable.List()
    visible      : no
    selectedItem : null


  isActive: ->

    { items, visible } = @props
    return items.size > 0 and visible


  hasOnlyItem: -> @props.items.size is 1


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
    else if @isActive()
      @close()


  componentDidUpdate: (prevProps, prevState) ->

    { selectedItem } = @props
    return  if prevProps.selectedItem is selectedItem or not selectedItem

    containerElement = @refs.dropup.getMainElement()
    itemElement      = React.findDOMNode @refs[selectedItem.get 'id']

    scrollToTarget containerElement, itemElement


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

    <Dropup
      className      = "ChannelDropup"
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
