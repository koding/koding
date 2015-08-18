kd             = require 'kd'
React          = require 'kd-react'
immutable      = require 'immutable'
classnames     = require 'classnames'
ActivityFlux   = require 'activity/flux'
Dropup         = require 'activity/components/dropup'
UserDropupItem = require 'activity/components/userdropupitem'
scrollToTarget  = require 'activity/util/scrollToTarget'


module.exports = class UserDropup extends React.Component

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
    
    @props.onItemConfirmed? "@#{selectedItem.getIn ['profile', 'nickname']}"
    @close()


  close: ->

    ActivityFlux.actions.user.setChatInputUsersVisibility no


  moveToNextPosition: ->

    if @hasOnlyItem()
      @close()
      return no
    else
      ActivityFlux.actions.user.moveToNextChatInputUsersIndex()
      return yes


  moveToPrevPosition: ->

    if @hasOnlyItem()
      @close()
      return no
    else
      ActivityFlux.actions.user.moveToPrevChatInputUsersIndex()
      return yes


  setQuery: (query) ->

    matchResult = query?.match /^@(.*)/
    if matchResult
      query = matchResult[1]
      ActivityFlux.actions.user.setChatInputUsersQuery query
      ActivityFlux.actions.user.setChatInputUsersVisibility yes
    else if @isActive()
      @close()


  componentDidUpdate: (prevProps, prevState) ->

    { selectedItem } = @props
    return  if prevProps.selectedItem is selectedItem or not selectedItem

    containerElement = @refs.dropup.getMainElement()
    itemElement      = React.findDOMNode @refs[selectedItem.get '_id']

    scrollToTarget containerElement, itemElement


  onItemSelected: (index) ->

    ActivityFlux.actions.user.setChatInputUsersSelectedIndex index


  renderList: ->

    { items, selectedItem } = @props

    items.map (item, index) =>
      isSelected = item is selectedItem

      <UserDropupItem
        isSelected  = { isSelected }
        index       = { index }
        item        = { item }
        onSelected  = { @bound 'onItemSelected' }
        onConfirmed = { @bound 'confirmSelectedItem' }
        key         = { item.get '_id' }
        ref         = { item.get '_id' }
      />


  render: ->

    <Dropup
      className      = "UserDropup"
      visible        = { @isActive() }
      onOuterClick   = { @bound 'close' }
      ref            = 'dropup'
    >
      <div className="UserDropup-innerContainer">
        <div className="Dropup-header">
          People
        </div>
        <div className="UserDropup-list">
          {@renderList()}
        </div>
      </div>
    </Dropup>
