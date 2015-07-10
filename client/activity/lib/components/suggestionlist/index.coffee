kd        = require 'kd'
React     = require 'kd-react'
immutable = require 'immutable'

SuggestionItem = require 'activity/components/suggestionitem'


module.exports = class SuggestionList extends React.Component

  @defaultProps =
    messages: []


  renderChildren: ->

    { messages, query } = @props
    messages ?= []
    messages.map (message) ->
      <SuggestionItem message={message} query={query} />


  render: ->

    <div className={kd.utils.curry 'SuggestionList', @props.className}>
      {@renderChildren()}
    </div>

