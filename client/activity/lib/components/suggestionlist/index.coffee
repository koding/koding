kd        = require 'kd'
React     = require 'kd-react'
immutable = require 'immutable'

SuggestionItem = require 'activity/components/suggestionitem'


module.exports = class SuggestionList extends React.Component

  @defaultProps =
    suggestions   : immutable.List()
    selectedIndex : -1


  componentDidUpdate: (prevProps, prevState) ->

    { selectedIndex } = @props
    return  if prevProps.selectedIndex is selectedIndex or selectedIndex < 0

    containerElement = $ React.findDOMNode @refs.list
    itemElement      = $ React.findDOMNode @refs["SuggestionItem_#{selectedIndex}"]

    containerScrollTop    = containerElement.scrollTop()
    containerHeight       = containerElement.outerHeight()
    containerScrollBottom = containerScrollTop + containerHeight
    itemTop               = itemElement.position().top
    itemHeight            = itemElement.outerHeight()
    itemBottom            = itemTop + itemHeight

    # scroll container if selected item is outside the visible area
    isUnderContainerBottom = itemBottom > containerScrollBottom
    isAboveContainerTop    = itemTop < containerScrollTop
    fitContainerHeight     = itemHeight < containerHeight

    if isUnderContainerBottom and fitContainerHeight
      containerElement.scrollTop itemBottom - containerHeight
    else if isAboveContainerTop or (isUnderContainerBottom and not fitContainerHeight)
      containerElement.scrollTop itemTop


  renderChildren: ->

    { suggestions, selectedIndex, onItemSelected, onItemConfirmed } = @props
    suggestions.map (suggestion, index) =>
      <SuggestionItem
        suggestion  = { suggestion }
        index       = { index }
        isSelected  = { index is selectedIndex }
        onSelected  = { onItemSelected }
        onConfirmed = { onItemConfirmed }
        key         = { suggestion.getIn(['message', 'id']) }
        ref         = { "SuggestionItem_#{index}" }
      />


  render: ->

    <div className={kd.utils.curry 'SuggestionList', @props.className} ref='list'>
      <div className='SuggestionList-innerContainer'>
        {@renderChildren()}
      </div>
    </div>

