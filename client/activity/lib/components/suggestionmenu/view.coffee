kd        = require 'kd'
React     = require 'kd-react'
ReactView = require 'app/react/reactview'

KDCustomHTMLView = kd.CustomHTMLView
SuggestionList   = require './index'


module.exports = class SuggestionMenuView extends KDCustomHTMLView

  viewAppended: ReactView::viewAppended


  renderReact: ->
    <SuggestionList />


