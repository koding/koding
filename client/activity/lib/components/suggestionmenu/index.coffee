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

    { getters } = ActivityFlux
    return {
      messages : getters.currentSuggestionMessages
      query    : getters.currentSuggestionQuery
    }


  handleClose: (e) ->

    e.preventDefault()
    ActivityFlux.actions.suggestions.changeAccess no


  isVisible: -> @state.messages?.length > 0


  checkVisibility: -> @props.checkVisibility? @isVisible()


  componentDidMount: -> @checkVisibility()


  componentDidUpdate: -> @checkVisibility()


  render: ->

    { messages, query } = @state
    className = "ActivitySuggestionMenu #{ unless @isVisible() then 'hidden' }"

    <div className={className}>
      <div className="ActivitySuggestionMenu-header">
        Searching for one of these?
        <a href="#" className="ActivitySuggestionMenu-closeIcon" onClick={@handleClose} />
      </div>
      <SuggestionList messages={messages} query={query} />
    </div>


React.Component.include.call SuggestionMenu, [KDReactorMixin]