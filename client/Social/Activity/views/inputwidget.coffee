class ActivityInputWidget extends KDView
  {daisy, dash}         = Bongo
  {JStatusUpdate, JTag} = KD.remote.api

  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "input-wrapper", options.cssClass
    super options, data

    @input    = new ActivityInputView
    @input.on "Escape", @bound "reset"

    @embedBox = new EmbedBoxWidget delegate: @input, data

    @submit    = new KDButtonView
      type     : "submit"
      cssClass : "solid green"
      title    : "Post"
      callback : @bound "submit"

  submit: (callback) ->
    return  unless value = @input.getValue().trim()

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
        body = @encodeTagSuggestions value, createdTags
        data =
          group : KD.getSingleton('groupsController').getGroupSlug()
          body  : body
          meta  : {tags}

        data.link_url   = @embedBox.url or ""
        data.link_embed = @embedBox.getDataForSubmit() or {}

        @lockSubmit()

        fn = @bound if activity then "update" else "create"
        fn data, (err, activity) =>
          @reset yes
          @embedBox.resetEmbedAndHide()
          @emit "Submit"
          callback? err, activity
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

      # badge
      countOptions   =
        property     : "counts.statusUpdates"
        relType      : "author"
        source       : "JStatusUpdate"
        targetSelf   : 1
      new BadgeAlertView {countOptions}

  update: (data, callback) ->
    activity = @getData()
    return  @reset() unless activity
    activity.modify data, (err) =>
      @reset()  unless err
      callback? err

  edit: (activity) ->
    @setData activity
    content = activity.body.replace /\n/g, "<br>"
    @input.setContent content, activity
    @embedBox.loadEmbed activity.link.link_url  if activity.link
    @submit.setTitle "Update"

  reset: (lock = yes) ->
    @input.setContent ""
    @input.blur()
    @embedBox.resetEmbedAndHide()
    @submit.setTitle "Post"
    @submit.focus()
    setTimeout (@bound "unlockSubmit"), 8000
    @setData null
    @unlockSubmit()  if lock

  lockSubmit: ->
    @submit.disable()
    @submit.setTitle "Wait"

  unlockSubmit: ->
    @submit.enable()
    @submit.setTitle "Post"

  viewAppended: ->
    @addSubView @input
    @addSubView @embedBox
    @input.addSubView @submit
    @hide()  unless KD.isLoggedIn()
