kd = require 'kd'
React = require 'app/react'
EnvironmentFlux = require 'app/flux/environment'
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

    @getStackScript = kd.utils.debounce 500, @getStackScript


  onChange: (event) ->

    event.persist()
    @setState { searchQuery: event.target.value }
    @setState { loading: yes }
    @getStackScript @state.searchQuery


  getStackScript: (value) ->

    return  unless value
    @doRequest value

  onFocus: (event) ->

    @setState { close: no }  if @state.scripts.length


  onClick: (script, event) ->

    { title } = script
    @doRequest title, yes

  showPreview: (markdown, query) ->

    scrollView = new kd.CustomScrollView { cssClass : 'stack-example-scroll' }
    markdown = applyMarkdown markdown, { sanitize : no, breaks: yes }
    scrollView.wrapper.addSubView markdown_content = new kd.CustomHTMLView
      tagName : 'p'
      cssClass : 'markdown-content stack-script'
      partial : markdown

    new ContentModal
      width : 1024
      cssClass : 'has-markdown content-modal stack-script'
      title : "Stack Script: #{query} Preview"
      content : scrollView


  doRequest: (query, type = no) ->

    return  unless query
    EnvironmentFlux.actions.searchStackScript(query, type)
    .then (data) =>
      if type then @showPreview data, query
      else @setState { loading: no, scripts: data }
    .catch =>
      @setState { loading: no }  unless type
      kd.NotificationView { title: 'Error occured while fetching stack script' }


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

