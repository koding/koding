kd        = require 'kd'
React     = require 'kd-react'
immutable = require 'immutable'

ActivityFlux   = require 'activity/flux'
KDReactorMixin = require 'app/flux/base/reactormixin'
SuggestionList = require 'activity/components/suggestionlist'

module.exports = class SuggestionMenu extends React.Component

  constructor: (props) ->

    super props

    @state = { suggestions : immutable.List(), flags : immutable.Map() }


  getDataBindings: ->

    { getters } = ActivityFlux

    return {
      suggestions   : getters.currentSuggestions
      flags         : getters.currentSuggestionsFlags
      selectedIndex : getters.currentSuggestionsSelectedIndex
    }


  handleClose: (e) ->

    e.preventDefault()
    @props.onDisabled?()


  isVisible: ->

    { suggestions, flags } = @state
    return suggestions.size > 0 and flags.get('accessible') and flags.get('visible')


  checkVisibility: -> @props.checkVisibility? @isVisible()


  componentDidMount: -> @checkVisibility()


  componentDidUpdate: -> @checkVisibility()


  onItemSelected: (index) -> ActivityFlux.actions.suggestions.setSelectedIndex index


  render: ->

    { suggestions, selectedIndex } = @state
    { onItemConfirmed } = @props
    return <div className="hidden" />  unless @isVisible()

    <div className="ActivitySuggestionMenu">
      <div className="ActivitySuggestionMenu-header">
        Searching for one of these?
        <div className="ActivitySuggestionMenu-closeIcon" onClick={@bound 'handleClose'} />
      </div>
      <SuggestionList
        suggestions     = { suggestions }
        selectedIndex   = { selectedIndex }
        onItemSelected  = { @bound 'onItemSelected' }
        onItemConfirmed = { onItemConfirmed }
      />
      <div className="ActivitySuggestionMenu-footer">
        If none of these are relevant, post yours
        <button type="submit" className="kdbutton solid green small" onClick={@props.onSubmit}>
          <span className="button-title">SEND</span>
        </button>
      </div>
    </div>


React.Component.include.call SuggestionMenu, [KDReactorMixin]