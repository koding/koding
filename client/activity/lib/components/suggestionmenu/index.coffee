kd        = require 'kd'
React     = require 'kd-react'
immutable = require 'immutable'

ActivityFlux   = require 'activity/flux'
KDReactorMixin = require 'app/flux/reactormixin'

SuggestionList = require 'activity/components/suggestionlist'


module.exports = class SuggestionMenu extends React.Component

  constructor: (props) ->

    super props

    @state = { messages : [], query : '' }


  getDataBindings: ->

    return {
      messages : ActivityFlux.getters.currentSuggestionMessages
      query    : ActivityFlux.getters.currentSuggestionQuery
    }


  render: ->

    { messages, query } = @state
    <div className="ActivitySuggestionMenu">
      <SuggestionList messages={messages} query={query} />
    </div>


React.Component.include.call SuggestionMenu, [KDReactorMixin]