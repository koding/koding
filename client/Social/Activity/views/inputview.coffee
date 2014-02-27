class ActivityInputView extends KDTokenizedInput

  TOKEN_LIMIT = 5

  constructor: (options = {}, data) ->
    options.cssClass         = KD.utils.curry "input-view", options.cssClass
    options.type           or= "html"
    options.multiline       ?= yes
    options.placeholder    or= "What's new #{KD.whoami().profile.firstName}?"
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

  sanitizeInput: ->
    {prefix} = @activeRule
    value = @tokenInput.textContent.substring prefix.length
    words = value.split /\W/, 3
    if words.join("") isnt ""
      newval = prefix + words.join "-"
      @tokenInput.textContent = newval
      @utils.selectText @tokenInput, 1

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
    super
    return  if event.isPropagationStopped()
    switch event.which
      when 27 # Escape
        @emit "Escape"

    if /\s/.test String.fromCharCode event.which
      if @tokenInput and /^\W+$/.test @tokenInput.textContent then @cancel()
      else if @selectToken() then KD.utils.stopDOMEvent event

  keyUp: ->
    return  if @getTokens().length >= TOKEN_LIMIT
    super

  focus: ->
    return  if @focused
    super
    value = @getValue()
    unless value
      content = @prefixDefaultTokens()
      return  unless content
      @setContent content
      {childNodes} = @getEditableElement()
      @utils.selectEnd childNodes[childNodes.length - 1]

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

  getTokenFilter: ->
    switch @activeRule.prefix
      when "#" then (token) -> token instanceof KD.remote.api.JTag
      else noop

  fillTokenMap = (tokens, map) ->
    tokens.forEach (token) ->
      map[token.getId()] = token
