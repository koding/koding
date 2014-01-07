class ActivityInputWidget extends KDView
  {daisy, dash}         = Bongo
  {JNewStatusUpdate, JTag} = KD.remote.api

  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "activity-input-widget", options.cssClass
    super options, data

    options.destroyOnSubmit ?= no

    @input    = new ActivityInputView defaultValue: options.defaultValue
    @input.on "Escape", @bound "reset"

    @embedBox = new EmbedBoxWidget delegate: @input, data

    @submit    = new KDButtonView
      type     : "submit"
      cssClass : "solid green"
      iconOnly : yes
      callback : @bound "submit"

    @avatar = new AvatarView
      size      :
        width   : 35
        height  : 35
    , KD.whoami()

  submit: (callback) ->
    return  unless value = @input.getValue().trim()

    activity       = @getData()
    activity?.tags = []
    tags           = []
    suggestedTags  = []
    createdTags    = {}

    for token in @input.getTokens()
      {data, type} = token
      if type is "tag"
        if data instanceof JTag
          tags.push id: data.getId()
          activity?.tags.push data
        else if data.$suggest and data.$suggest not in suggestedTags
          suggestedTags.push data.$suggest

    daisy queue = [
      ->
        tagCreateJobs = suggestedTags.map (title) ->
          ->
            JTag.create {title}, (err, tag) ->
              return KD.showError err if err
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
          @emit "Submit", err, activity
          callback? err, activity

          KD.mixpanel "Status update create, success", {length:activity?.body?.length}
    ]

    @emit "ActivitySubmitted"

  encodeTagSuggestions: (str, tags) ->
    return  str.replace /\|(.*?):\$suggest:(.*?)\|/g, (match, prefix, title) ->
      tag = tags[title]
      return  "" unless tag
      return  "|#{prefix}:JTag:#{tag.getId()}|"

  create: (data, callback) ->
    JNewStatusUpdate.create data, (err, activity) =>
      if err
        KD.mixpanel "Status update create, fail"

      @reset()  unless err

      callback? err, activity

      KD.showError err,
        AccessDenied :
          title      : "You are not allowed to post activities"
          content    : 'This activity will only be visible to you'
          duration   : 5000
        KodingError  : 'Something went wrong while creating activity'

      KD.getSingleton("badgeController").checkBadge
        property : "statusUpdates", relType : "author", source : "JNewStatusUpdate", targetSelf : 1

  update: (data, callback) ->
    activity = @getData()
    return  @reset() unless activity
    activity.modify data, (err) =>
      if err
        KD.mixpanel "Status update update, fail"

      KD.showError err
      @reset()  unless err
      callback? err

      KD.mixpanel "Status update update, success"

  reset: (lock = yes) ->
    @input.setContent ""
    @input.blur()
    @embedBox.resetEmbedAndHide()
    # @submit.setTitle "Post"
    @submit.focus()
    setTimeout (@bound "unlockSubmit"), 8000
    @setData null
    @unlockSubmit()  if lock

  lockSubmit: ->
    @submit.disable()
    # @submit.setTitle "Wait"

  unlockSubmit: ->
    @submit.enable()
    # @submit.setTitle "Post"

  viewAppended: ->
    @addSubView @avatar
    @addSubView @input
    @addSubView @embedBox
    @input.addSubView @submit
    @hide()  unless KD.isLoggedIn()


class ActivityEditWidget extends ActivityInputWidget
  constructor : (options = {}, data) ->
    options.cssClass = KD.utils.curry "edit-widget", options.cssClass
    options.destroyOnSubmit = yes

    super options, data

    @submit    = new KDButtonView
      type     : "submit"
      cssClass : "solid green"
      iconOnly : no
      title    : "Done editing"
      callback : @bound "submit"

    @cancel = new KDButtonView
      cssClass : "solid gray"
      title    : "Cancel"
      callback : => @emit "Cancel"

  viewAppended: ->
    data         = @getData()
    {body, link} = data

    content = ""
    content += "<div>#{line}</div>" for line in body.split "\n"
    @input.setContent content, data
    @embedBox.loadEmbed link.link_url  if link

    @addSubView @input
    @addSubView @embedBox
    @input.addSubView @submit
    @input.addSubView @cancel
