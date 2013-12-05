class ActivityInputWidget extends KDView
  {daisy, dash}         = Bongo
  {JStatusUpdate, JTag} = KD.remote.api

  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "input-wrapper", options.cssClass
    super options, data
    @input    = new ActivityInputView
    @embedBox = new EmbedBoxWidget delegate: @input, data

    @submit    = new KDButtonView
      type     : "submit"
      cssClass : "solid green"
      title    : "Post"
      callback : @bound "submit"

  submit: (callback) ->
    activity       = @getData()
    activity?.tags = []
    tags           = []
    suggestedTags  = []
    createdTags    = {}

    unless KD.checkFlag "exempt"
      for token in @input.getTokens()
        {data, type} = token
        if type is "tag"
          if data instanceof JTag
            tags.push id: data.getId()
            activity?.tags.push data
          else if data.$suggest
            suggestedTags.push data.$suggest

    daisy queue = [
      ->
        tagCreateJobs = suggestedTags.map (title) ->
          ->
            JTag.create {title}, (err, tag) ->
              activity?.tags.push tag
              tags.push id: tag.getId()
              createdTags[title] = tag
              tagCreateJobs.fin()

        dash tagCreateJobs, ->
          queue.next()
    , =>
        body = @encodeTagSuggestions @input.getValue(), createdTags
        data =
          group : KD.getSingleton('groupsController').getGroupSlug()
          body  : body
          meta  : {tags}

        data.link_url   = @embedBox.url or ""
        data.link_embed = @embedBox.getDataForSubmit() or {}

        fn = @bound if activity then "update" else "create"
        fn data, callback
    ]

  encodeTagSuggestions: (str, tags) ->
    return  str.replace /\|(.*?):\$suggest:(.*?)\|/g, (match, prefix, title) ->
      tag = tags[title]
      return  "" unless tag
      return  "|#{prefix}:JTag:#{tag.getId()}|"

  create: (data, callback) ->
    JStatusUpdate.create data, (err, activity) =>
      @reset()  unless err

      callback? err, activity
      KD.getSingleton("appManager").tell "Activity", "ownActivityArrived", activity

      KD.showError err,
        AccessDenied :
          title      : 'You are not allowed to #{action} activities'
          content    : 'This activity will only be visible to you'
          duration   : 5000
        KodingError  : 'Something went wrong while creating activity'

  update: (data, callback) ->
    activity = @getData()
    return  @reset() unless activity
    activity.modify data, (err) =>
      @reset()  unless err
      callback? err

  edit: (activity) ->
    @setData activity
    @input.setContent activity.body, activity
    @embedBox.loadEmbed activity.link.link_url
    @submit.setTitle "Update"

  reset: ->
    @input.setContent ""
    @submit.setTitle "Post"
    @embedBox.resetEmbedAndHide()
    @setData null

  viewAppended: ->
    @addSubView @input
    @addSubView @embedBox
    @addSubView @submit
