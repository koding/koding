class ActivityInputWidget extends KDView
  {daisy, dash}         = Bongo
  {JNewStatusUpdate, JTag} = KD.remote.api

  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "input-wrapper", options.cssClass
    super options, data

    @input    = new ActivityInputView
    @input.on "Escape", @bound "reset"

    @notification = new KDView
      cssClass : "notification hidden"
      partial  : """
This is a sneak peek beta for testing purposes only. If you find any bugs, please post them here on the activity feed with the tag #bug. Beware that your activities could be discarded.<br><br>

With love from the Koding team.<br>
      """

    @notification.addSubView new KDCustomHTMLView
      tagName : "span"
      cssClass: "close-tab"
      click   : => @notification.destroy()

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
          @notification.show()
          callback? err, activity
    ]

  encodeTagSuggestions: (str, tags) ->
    return  str.replace /\|(.*?):\$suggest:(.*?)\|/g, (match, prefix, title) ->
      tag = tags[title]
      return  "" unless tag
      return  "|#{prefix}:JTag:#{tag.getId()}|"

  create: (data, callback) ->
    JNewStatusUpdate.create data, (err, activity) =>
      @reset()  unless err

      callback? err, activity

      KD.showError err,
        AccessDenied :
          title      : 'You are not allowed to #{action} activities'
          content    : 'This activity will only be visible to you'
          duration   : 5000
        KodingError  : 'Something went wrong while creating activity'

      KD.getSingleton("badgeController").checkBadge
        property:"statusUpdates", relType:"author",source:"JNewStatusUpdate" ,targetSelf:1

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
    # @submit.setTitle "Update"

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
    @addSubView @notification
    @addSubView @embedBox
    @input.addSubView @submit
    @hide()  unless KD.isLoggedIn()
