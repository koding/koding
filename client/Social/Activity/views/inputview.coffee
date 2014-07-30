class ActivityInputView extends KDTokenizedInput

  TOKEN_LIMIT = 5

  constructor: (options = {}, data) ->
    options.cssClass         = KD.utils.curry "input-view", options.cssClass
    options.type           or= "html"
    options.multiline       ?= yes
    options.placeholder    or= "What's new #{KD.whoami().profile.firstName}?"
    options.tokenViewClass or= TokenView
    # options.rules  or=
    #   tag            :
    #     type         : "tag"
    #     prefix       : "#"
    #     pistachio    : "\#{{#(title)}}"
    #     dataSource   : @bound "fetchTopics"

    super options, data
    @defaultTokens = initializeDefaultTokens()

  fetchTopics: (inputValue, callback) ->
    KD.getSingleton("appManager").tell "Topics", "fetchTopics", {inputValue}, (tags = [], deletedTags = []) =>
      matches = []
      if inputValue.length > 1 and not /^\W+$/.test inputValue
        matches = tags.filter (tag) -> tag.title is inputValue or inputValue in tag.children
        deletedMatches = deletedTags.filter (title) -> title is inputValue

        unless matches.length
          infoItem = if deletedMatches.length then $deleted: inputValue
          else $suggest: inputValue
          tags = [infoItem].concat tags

      @showMenu
        itemChildClass  : TagContextMenuItem
      , tags

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

  keyDown: (event) ->
    super event
    return  if event.isPropagationStopped()
    switch event.which
      when 13 # Enter
        KD.utils.stopDOMEvent event
        @handleEnter event
      when 27 # Escape
        @emit "Escape"

    if /\W/.test String.fromCharCode event.which
      if @tokenInput and /^\W+$/.test @tokenInput.textContent then @cancel()
      else if @selectToken() then KD.utils.stopDOMEvent event

    return yes

  keyUp: ->
    return  if @getTokens().length >= TOKEN_LIMIT
    super

  handleEnter: (event) ->
    return @insertNewline()  if event.shiftKey

    position = @getPosition() + 1
    value    = @getValue()
    read     = 0

    for part, index in value.split '```'
      blockquote = index %% 2 is 1
      read += part.length + (if blockquote then 0 else 3)
      break  if read > position

    if blockquote
    then @insertNewline()
    else @emit 'Enter'

  insertNewline: ->
    document.execCommand 'insertText', no, "\n"

  getPosition: ->
    {startContainer, startOffset} = KD.utils.getSelectionRange()
    {parentNode} = startContainer

    position = 0
    for node in @getEditableElement().childNodes
      break  if node is startContainer or node is parentNode
      position += node.textContent.length

    return position + startOffset


  focus: ->

    super

    return @utils.selectEnd()  if value = @getValue()

    content = @prefixDefaultTokens()
    return  unless content

    @setContent content
    {childNodes} = @getEditableElement()
    @utils.selectEnd childNodes[childNodes.length - 1]


  # contentEditable elements cannot be
  # triggered to be blurred. This method
  # handles that problem.
  forceBlur: ->
    @getEditableDomElement()
      .removeAttr('contenteditable')
      .blur()

    KD.utils.wait 100, =>
      @getEditableDomElement()
        .prop('contenteditable', yes)


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

  getTokenFilter: -> noop

  fillTokenMap = (tokens, map) ->
    tokens.forEach (token) ->
      map[token.getId()] = token
