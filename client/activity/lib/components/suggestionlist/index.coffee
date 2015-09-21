kd        = require 'kd'
React     = require 'kd-react'
immutable = require 'immutable'

SuggestionItem = require 'activity/components/suggestionitem'
scrollToTarget = require 'app/util/scrollToTarget'


module.exports = class SuggestionList extends React.Component

  @defaultProps =
    suggestions   : immutable.List()
    selectedIndex : -1


  componentDidUpdate: (prevProps, prevState) ->

    { selectedIndex } = @props
    return  if prevProps.selectedIndex is selectedIndex or selectedIndex < 0

    containerElement = React.findDOMNode @refs.list
    itemElement      = React.findDOMNode @refs["SuggestionItem_#{selectedIndex}"]

    scrollToTarget containerElement, itemElement


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

