kd = require 'kd'
React = require 'app/react'
EnvironmentFlux = require 'app/flux/environment'
View = require './view'
applyMarkdown = require 'app/util/applyMarkdown'
ContentModal = require 'app/components/contentModal'
makeHttpClient = require 'app/util/makeHttpClient'


exports.client = client = makeHttpClient { baseURL: '/-/terraform/' }

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
    @setState { close: no, loading: yes }
    @getStackScript @state.searchQuery


  getStackScript: (query) ->

    resultbox = @refs.view.refs.resultbox
    if resultbox
      resultbox.refs.scrollContainer.refs.container.scrollTop = 0

    return  unless query

    client.post("document-search", { query })
    .then ({ data }) =>
      @setState { loading: no, scripts: data }
    .catch =>
      @setState { loading: no }
      kd.NotificationView { title: 'Error occured while fetching stack script' }


  onFocus: (event) ->

    @setState { close: no }  if @state.scripts.length


  onClick: (script, event) ->

    { title } = script
    @setState { close: yes, searchQuery: title }
    client.post("document-content", { query: title })
    .then ({ data }) => @showPreview data, title
    .catch =>
      kd.NotificationView { title: 'Error occured while fetching stack script' }


  showPreview: (markdown, query) ->

    scrollView = new kd.CustomScrollView { cssClass : 'stack-example-scroll' }
    markdown = applyMarkdown markdown, { sanitize : no, breaks: yes }
    scrollView.wrapper.addSubView markdown_content = new kd.CustomHTMLView
      tagName : 'p'
      cssClass : 'markdown-content stack-script'
      partial : markdown

    new ContentModal
      width : 1024
      overlay: yes
      cssClass : 'has-markdown content-modal stack-script'
      title : "Stack Script: #{query} Preview"
      content : scrollView


  onIconClick: (event) ->

    @setState
      close: yes
      searchQuery: ''


  onKeyUp: (event) ->

    @onIconClick()  if event.keyCode is 27



  render: ->

    <View
      ref='view'
      onChange={@bound 'onChange'}
      onFocus={@bound 'onFocus'}
      onClick={@bound 'onClick'}
      onIconClick={@bound 'onIconClick'}
      onKeyUp={@bound 'onKeyUp'}
      scripts={@state.scripts}
      query={@state.searchQuery}
      loading={@state.loading}
      close={@state.close}
    />
