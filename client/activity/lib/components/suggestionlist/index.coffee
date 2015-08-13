kd        = require 'kd'
React     = require 'kd-react'
immutable = require 'immutable'

SuggestionItem = require 'activity/components/suggestionitem'


module.exports = class SuggestionList extends React.Component

  @defaultProps =
    suggestions: immutable.List()


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
      />


  render: ->

    <div className={kd.utils.curry 'SuggestionList', @props.className}>
      {@renderChildren()}
    </div>

