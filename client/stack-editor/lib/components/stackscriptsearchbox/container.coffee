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


  getDataBindings: ->
    return {
      scripts: EnvironmentFlux.getters.stackScripts
    }


  onChange: (event) ->

    event.persist()
    @setState { searchQuery: event.target.value }
    kd.utils.wait 500, =>
      return  unless event.target.value
      @setState { loading: yes }
      EnvironmentFlux.actions.searchStackScript event.target.value
      .then () => @setState { loading: no }
      .catch () => @setState { loading: no }


  onFocus: (event) ->
    @setState { close: no }  if @state.scripts.length


  onClick: (script, event) ->

    { markdown, title } = script
    scrollView = new kd.CustomScrollView { cssClass : 'stack-example-scroll' }

    markdown = applyMarkdown markdown, { sanitize : no }

    scrollView.wrapper.addSubView markdown_content = new kd.CustomHTMLView
      tagName : 'p'
      cssClass : 'markdown-content stack-script'
      partial : markdown

    new ContentModal
      width : 1024
      cssClass : 'has-markdown content-modal stack-script'
      title : "Stack Script: #{title} Preview"
      content : scrollView


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

StackScriptSearchBoxContainer.include [KDReactorMixin]
