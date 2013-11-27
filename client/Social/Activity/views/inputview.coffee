class ActivityInputView extends KDTokenizedInput
  {JStatusUpdate, JTag} = KD.remote.api

  constructor: (options = {}, data) ->
    options.cssClass      = KD.utils.curry "input-view", options.cssClass
    options.type        or= "html"
    options.multiline    ?= yes
    options.placeholder or= "What's new #{KD.whoami().profile.firstName}?"
    options.rules       or=
      tag                :
        type             : "tag"
        prefix           : "#"
        pistachio        : "\#{{#(title)}}"
        dataSource       : @bound "fetchTopics"

    super options, data

  fetchTopics: (inputValue, callback) ->
    KD.getSingleton("appManager").tell "Topics", "fetchTopics", {inputValue}, (tags) =>
      return  if tags.length is 0
      @showMenu
        itemChildOptions:
          pistachio     : "{{#(title)}}"
      , tags

  submit: (callback) ->
    tags = []

    unless KD.checkFlag "exempt"
      for token in @getTokens()
        {data, type} = token
        if type is "tag"
          if data instanceof JTag
          then tags.push id: data.getId()
          else if data.$suggest?
          then tags.push data

    data     =
      group  : KD.getSingleton('groupsController').getGroupSlug()
      body   : @getValue()
      meta   :
        tags : tags

    JStatusUpdate.create data, (err, activity) =>
      @setContent ""  unless err

      callback? err, activity

      KD.showError err,
        AccessDenied :
          title      : 'You are not allowed to create activities'
          content    : 'This activity will only be visible to you'
          duration   : 5000
        KodingError  : 'Something went wrong while creating activity'
