kd = require 'kd'
React = require 'app/react'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin = require 'app/flux/base/reactormixin'
View = require './view'
applyMarkdown = require 'app/util/applyMarkdown'
ContentModal = require 'app/components/contentModal'

module.exports = class StackScriptSearchBoxContainer extends React.Component

  constructor: (props) ->

    super props
    @state =
      searchQuery: ''
      close: no
      loading: no
      scripts: []

  onChange: (event) ->

    event.persist()
    @setState { searchQuery: event.target.value }
    kd.utils.wait 500, =>
      return  unless event.target.value
      @setState { loading: yes }
      EnvironmentFlux.actions.searchStackScript event.target.value
      .then (scripts) => @setState { loading: no, scripts: scripts }
      .catch () =>
        @setState { loading: no }
        kd.NotificationView { title: 'Error occured while fetching stack script. Try again' }


  onFocus: (event) ->
    @setState { close: no }  if @state.scripts.length


  onClick: (script, event) ->
    { title } = script
    EnvironmentFlux.actions.searchStackScript(title, yes)
    .then (markdown) =>
      scrollView = new kd.CustomScrollView { cssClass : 'stack-example-scroll' }
      markdown = applyMarkdown markdown, { sanitize : no, breaks: yes }
      scrollView.wrapper.addSubView markdown_content = new kd.CustomHTMLView
        tagName : 'p'
        cssClass : 'markdown-content stack-script'
        partial : markdown

      new ContentModal
        width : 1024
        cssClass : 'has-markdown content-modal stack-script'
        title : "Stack Script: #{title} Preview"
        content : scrollView

    .catch () ->
      kd.NotificationView { title: 'Error occured while fetching stack script. Try again' }


  onIconClick: (event) ->

    @setState
      close: yes
      searchQuery: ''


  render: ->

    <View
      onChange={@bound 'onChange'}
      onFocus={@bound 'onFocus'}
      onClick={@bound 'onClick'}
      onIconClick={@bound 'onIconClick'}
      scripts={@state.scripts}
      query={@state.searchQuery}
      loading={@state.loading}
      close={@state.close}
    />

# StackScriptSearchBoxContainer.include [KDReactorMixin]
