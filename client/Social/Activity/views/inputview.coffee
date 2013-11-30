class ActivityInputView extends KDTokenizedInput
  {daisy, dash}         = Bongo
  {JStatusUpdate, JTag} = KD.remote.api

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

  submit: (callback) ->
    tags          = []
    suggestedTags = []
    createdTags   = {}

    unless KD.checkFlag "exempt"
      for token in @getTokens()
        {data, type} = token
        if type is "tag"
          if data instanceof JTag
          then tags.push id: data.getId()
          else if data.$suggest?
          then suggestedTags.push data

    daisy queue = [
      =>
        tagCreateJobs = suggestedTags.map (data) ->
          ->
            JTag.create title: data.$suggest, (err, tag) ->
              tags.push tag
              createdTags[tag.title] = tag
              tagCreateJobs.fin()

        dash tagCreateJobs, ->
          queue.next()
      =>
        body = @getValue()
        body = body.replace /\|(.*):\$suggest:(.*)\|/g, (match, prefix, title) ->
          tag = createdTags[title]
          return  "" unless tag
          return "|#{prefix}:JTag:#{tag.getId()}|"

        log {body, tags}

        data     =
          group  : KD.getSingleton('groupsController').getGroupSlug()
          body   : body
          meta   :
            tags : tags

        JStatusUpdate.create data, (err, activity) =>
          log {err, activity}
          @setContent ""  unless err

          callback? err, activity

          KD.showError err,
            AccessDenied :
              title      : 'You are not allowed to create activities'
              content    : 'This activity will only be visible to you'
              duration   : 5000
            KodingError  : 'Something went wrong while creating activity'
    ]
