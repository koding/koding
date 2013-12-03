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

