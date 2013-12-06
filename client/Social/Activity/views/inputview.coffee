class ActivityInputView extends KDTokenizedInput
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
    KD.getSingleton("appManager").tell "Topics", "fetchTopics", {inputValue}, (tags = []) =>
      matches = []
      if inputValue.length > 1
        matches = tags.filter (tag) -> tag.title is inputValue
        tags = [$suggest: inputValue].concat tags  unless matches.length

      @showMenu
        suggest         : if matches.length is 0 then inputValue else ""
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
    return  content.replace /\|(.*?):(.*?):(.*?)\|/g, (match, prefix, constructorName, id) =>
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

  fillTokenMap = (tokens, map) ->
    tokens.forEach (token) ->
      map[token.getId()] = token
