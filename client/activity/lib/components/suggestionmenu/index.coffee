kd        = require 'kd'
React     = require 'kd-react'
immutable = require 'immutable'

ActivityFlux   = require 'activity/flux'
KDReactorMixin = require 'app/flux/reactormixin'
SuggestionList = require 'activity/components/suggestionlist'

module.exports = class SuggestionMenu extends React.Component

  constructor: (props) ->

    super props

    @state = { suggestions : immutable.List(), query : '', state : immutable.Map() }


  getDataBindings: ->

    { getters } = ActivityFlux
    return {
      suggestions : getters.currentSuggestions
      query       : getters.currentSuggestionsQuery
      state       : getters.currentSuggestionsState
    }


  handleClose: (e) ->

    e.preventDefault()
    ActivityFlux.actions.suggestions.setAccess no


  isVisible: ->

    { suggestions, state } = @state
    return suggestions.size > 0 and state.get('accessible') and state.get('visible')



  checkVisibility: -> @props.checkVisibility? @isVisible()


  componentDidMount: -> @checkVisibility()


  componentDidUpdate: -> @checkVisibility()


  render: ->

    { suggestions, query } = @state
    return <div className="hidden" />  unless @isVisible()

    <div className="ActivitySuggestionMenu">
      <div className="ActivitySuggestionMenu-header">
        Searching for one of these?
        <a href="#" className="ActivitySuggestionMenu-closeIcon" onClick={@handleClose} />
      </div>
      <SuggestionList suggestions={suggestions} query={query} />
      <div className="ActivitySuggestionMenu-footer">
        None of the above answers your questions? Post yours
        <button type="submit" className="kdbutton solid green small" onClick={@props.onSubmit}>
          <span className="button-title">SEND</span>
        </button>
      </div>
    </div>


React.Component.include.call SuggestionMenu, [KDReactorMixin]