kd        = require 'kd'
React     = require 'kd-react'
immutable = require 'immutable'

SuggestionItem = require 'activity/components/suggestionitem'


module.exports = class SuggestionList extends React.Component

  @defaultProps =
    suggestions: immutable.List()


  renderChildren: ->

    { suggestions, query } = @props
    suggestions.map (suggestion) ->
      <SuggestionItem suggestion={suggestion} query={query} key={suggestion.get('id')} />


  render: ->

    <div className={kd.utils.curry 'SuggestionList', @props.className}>
      {@renderChildren()}
    </div>

