class ActivityInputView extends KDTokenizedInput

  TOKEN_LIMIT = 5

  constructor: (options = {}, data) ->
    options.cssClass         = KD.utils.curry "input-view", options.cssClass
    options.type           or= "html"
    options.multiline       ?= yes
    options.placeholder     ?= "What's new #{KD.whoami().profile.firstName}?"
    options.tokenViewClass or= TokenView
    options.rules  or=
      tag            :
        type         : "tag"
        prefix       : "#"
        pistachio    : "\#{{#(title)}}"
        dataSource   : @bound "fetchTopics"

    super options, data
    @defaultTokens = initializeDefaultTokens()

  fetchTopics: (inputValue, callback) ->

    KD.singletons.search.searchTopics inputValue
      .then (tags) =>
        pad = 46
        @showMenu
          itemChildClass : TagContextMenuItem
          x              : @getX() + pad
          y              : @getY() + @getHeight()
          cssClass       : 'tags-autocomplete'
        , tags.map (tag) -> new AlgoliaResult tag

  menuItemClicked: (item) ->
    tokenViewClass = SuggestedTokenView  if item.data.$suggest
    super item, tokenViewClass

  setDefaultTokens: (defaultTokens = {}) ->
    @defaultTokens = initializeDefaultTokens()
    fillTokenMap defaultTokens.tags, @defaultTokens.tags

  initializeDefaultTokens = ->
    return  tags: {}

  setContent: (content, activity) ->
    tokens = @defaultTokens or initializeDefaultTokens()
    fillTokenMap activity.tags , tokens.tags  if activity?.tags?.length
    super @renderTokens content, tokens

  selectToken: ->
    return  unless @menu

    {prefix} = @activeRule
    value = @tokenInput.textContent.substring(prefix.length).toLowerCase()
    tokens = @menu.getData().filter @getTokenFilter()
    for token in tokens
      if value is token.title.toLowerCase()
        @addToken token, @getOptions().tokenViewClass
        @hideMenu()
        return  true

  addToken: (item, tokenViewClass = @getOptions().tokenViewClass) ->
    {type, prefix, pistachio} = @activeRule

    switch type
      when 'tag'
        @addTag item
      else
        super item, tokenViewClass

  addTag: ({name}) ->
    view         = new KDCustomHTMLView
      tagName    : 'span'
      attributes : contenteditable: false
      cssClass   : 'token'
      partial    : "##{name}"

    element = view.getElement()

    @tokenInput.parentElement.insertBefore element, @tokenInput
    view.emit "viewAppended"
    @tokenInput.nextSibling.textContent = "\u00a0"

    @utils.selectText @tokenInput.nextSibling, 1
    @tokenInput.remove()

  keyDown: (event) ->

    super event

    return  if event.isPropagationStopped?()

    switch event.which
      when 13 # Enter
        @handleEnter event
      when 27 # Escape
        @emit 'Escape'

    if /\W/.test String.fromCharCode event.which
      if @selectToken() then KD.utils.stopDOMEvent event
      else if @activeRule then @cancel()

    return yes


  keyUp: (event) ->

    return  if @getTokens().length >= TOKEN_LIMIT
    return @matchPrefix()  unless @activeRule

    @_lastKeyUp = Date.now()
    KD.utils.wait 250, =>
      return  if Date.now() - @_lastKeyUp < 250
      super event

  handleEnter: (event) ->

    KD.utils.stopDOMEvent event

    return @insertNewline()  if event.shiftKey

    position = @getPosition() + 1
    value    = @getValue()
    read     = 0

    for part, index in value.split '```'
      blockquote = index %% 2 is 1
      read += part.length + (if blockquote then 0 else 6)
      break  if read > position

    if blockquote
    then @insertNewline()
    else @emit 'Enter', value

  cancel: ->

    if @activeRule
      {prefix} = @activeRule
      value = @tokenInput.textContent.substring(prefix.length).toLowerCase()
      @addToken name: value

    super

  insertNewline: ->
    document.execCommand 'insertText', no, "\n"


  getPosition: ->
    {startContainer, startOffset} = KD.utils.getSelectionRange()
    {parentNode} = startContainer

    position = 0
    for node in @getEditableElement().childNodes
      text = node.innerText or node.textContent

      break  if node is startContainer or node is parentNode
      position += text.length

      # take newline at the end of line into account if line if necessary
      position += 1  if text isnt "\n" and node.nextSibling?.nodeName is 'DIV'

    return position + startOffset


  focus: ->

    super

    {childNodes} = @getEditableElement()
    lastChild    = childNodes[childNodes.length - 1]

    return @utils.selectEnd lastChild  if value = @getValue()

    content = @prefixDefaultTokens()
    return  unless content

    @setContent content

    @utils.selectEnd childNodes[childNodes.length - 1]


  # Webkit has a bug where removing focus from element with
  # `contenteditable` doesn't actually remove focus. This is a workaround
  # from http://stackoverflow.com/questions/12353247/force-contenteditable-div-to-stop-accepting-input-after-it-loses-focus-under-web
  forceBlur: ->

    $('<div class="visuallyhidden" contenteditable style="position: fixed; top: 0"></div>')
      .prependTo 'body'
      .focus()
      .remove()

  blur: ->
    super
    @forceBlur()

  prefixDefaultTokens: ->
    content = ""
    for own type, tokens of @defaultTokens
      switch type
        when "tags"
          prefix = "#"
          constructorName = "JTag"
        else continue

      content += "|#{prefix}:#{constructorName}:#{token.getId()}|&nbsp;" for key, token of tokens

    return  content

  renderTokens: (content, tokens = {}) ->
    content.replace /\|(.*?):(.*?):(.*?):(.*?)\|/g, (match, prefix, constructorName, id) =>
      switch prefix
        when "#"
          itemClass = TagLinkView
          type      = "tag"
          pistachio = "#{prefix}{{#(title)}}"
          data      = tokens.tags[id]

      tokenView = new TokenView {itemClass, prefix, type, pistachio}, data
      tokenKey  = "#{tokenView.getId()}-#{tokenView.getKey()}"
      @tokenViews[tokenKey] = tokenView

      tokenView.setAttributes "data-key": tokenKey
      tokenView.emit "viewAppended"
      return tokenView.getElement().outerHTML

  getTokenFilter: ->-> true

  fillTokenMap = (tokens, map) ->
    tokens.forEach (token) ->
      map[token.getId()] = token
