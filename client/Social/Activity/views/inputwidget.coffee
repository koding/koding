class ActivityInputWidget extends KDView

  {daisy, dash} = Bongo

  helpMap      =
    mysql      :
      niceName : 'MySQL'
      tooltip  :
        title  : 'Open your terminal and type <code>help mysql</code>'
    phpmyadmin :
      niceName : 'phpMyAdmin'
      tooltip  :
        title  : 'Open your terminal and type <code>help phpmyadmin</code>'
    "vm size"  :
      pattern  : 'vm\\ssize|vm\\sconfig'
      niceName : 'VM config'
      tooltip  :
        title  : 'Open your terminal and type <code>help specs</code>'
    "vm down"  :
      pattern  : 'vm\\sdown|vm\\snot\\sworking|vm\\sis\\snot\\sworking'
      niceName : 'non-working VM'
      tooltip  :
        title  : 'You can go to your environments and try to restart your VM'
    help       :
      niceName : 'Help!!!'
      tooltip  :
        title  : "You don't need to type help in your post, just ask your question."
    wordpress  :
      niceName : 'WordPress'
      link     : 'http://learn.koding.com/?s=wordpress'



  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "activity-input-widget", options.cssClass
    super options, data

    options.destroyOnSubmit ?= no

    @input = new ActivityInputView defaultValue: options.defaultValue
    @input.on "Escape", @bound "reset"

    @input.on "TokenAdded", (type, token) =>
      if token.slug is "bug" and type is "tag"
        @bugNotification.show()
        @setClass "bug-tagged"

    # FIXME we need to hide bug warning in a proper way ~ GG
    @input.on "keyup", =>
      val = @input.getValue()
      @checkForCommonQuestions val
      if val.indexOf("5051003840118f872e001b91") is -1
        @unsetClass 'bug-tagged'
        @bugNotification.hide()

    @on "ActivitySubmitted", =>
      @unsetClass "bug-tagged"
      @bugNotification.once 'transitionend', =>
        @bugNotification.hide()

    @embedBox = new EmbedBoxWidget delegate: @input, data

    @submitButton = new KDButtonView
      type        : "submit"
      cssClass    : "solid green"
      iconOnly    : yes
      loader      : yes
      callback    : @bound "submit"

    @avatar = new AvatarView
      size      :
        width   : 35
        height  : 35
    , KD.whoami()

    @bugNotification = new KDCustomHTMLView
      cssClass : 'bug-notification'
      partial  : '<figure></figure>Posts tagged with <strong>#bug</strong>  will be moved to <a href="/Bugs" target="_blank">Bug Tracker</a>.'

    @bugNotification.hide()
    @bugNotification.bindTransitionEnd()

    @previewIcon = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "preview-icon"
      tooltip  :
        title  : "Markdown preview"
      click    : =>
        if not @preview then @showPreview() else @hidePreview()

    @helpContainer = new KDCustomHTMLView
      cssClass : 'help-container hidden'
      partial  : 'Need help with:'

    @currentHelperNames = []

  checkForCommonQuestions: KD.utils.throttle 200, (val)->

    @hideAllHelpers()

    pattern = ///#{(helpMap[item].pattern or item for item in Object.keys(helpMap)).join('|')}///gi
    match   = pattern.exec val
    matches = []
    while match isnt null
      matches.push match[0] if match
      match = pattern.exec val

    @addHelper keyword for keyword in matches


  addHelper:(val)->

    @helpContainer.show()

    unless helpMap[val.toLowerCase()]
      for own key, item of helpMap when item.pattern
        if ///#{item.pattern}///i.test val
          val = key
          break

    return if val in @currentHelperNames

    {niceName, link, tooltip} = helpMap[val.toLowerCase()]

    Klass     = KDCustomHTMLView
    options   =
      tagName : 'span'
      partial : niceName

    if tooltip
      options.tooltip           = _.extend {}, tooltip
      options.tooltip.cssClass  = 'activity-helper'
      options.tooltip.placement = 'bottom'

    if link
      Klass           = CustomLinkView
      options.tagName = 'a'
      options.title   = niceName
      options.href    = link or '#'
      options.target  = if link?[0] isnt '/' then '_blank' else ''

    @helpContainer.addSubView new Klass options
    @currentHelperNames.push val

  hideAllHelpers:->

    @helpContainer.hide()
    @helpContainer.destroySubViews()
    @currentHelperNames = []

  submit: (callback) ->
    return  unless value = @input.getValue().trim()

    {JTag} = KD.remote.api

    activity       = @getData()
    activity?.tags = []
    tags           = []
    suggestedTags  = []
    createdTags    = {}
    feedType       = ""
    { app }        = @getOptions()

    for token in @input.getTokens()
      feedType     = "bug" if token.data?.title?.toLowerCase() is "bug"
      {data, type} = token
      if type is "tag"
        if data instanceof JTag
          tags.push id: data.getId()
          activity?.tags.push data
        else if data.$suggest and data.$suggest not in suggestedTags
          suggestedTags.push data.$suggest

    queue = [
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
          group    : KD.getSingleton('groupsController').getGroupSlug()
          body     : body
          meta     : {tags}
          feedType : feedType

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

    if app is 'bug'
      queue.unshift =>
        KD.remote.api.JTag.one slug : 'bug', (err, tag)=>
          if err then KD.showError err
          else
            feedType = "bug"
            value += " #{KD.utils.tokenizeTag tag}"
            tags.push id : tag.getId()
          queue.next()

    daisy queue

    if feedType is "bug" then KD.singletons.dock.addItem { title : "Bugs", path : "/Bugs", order : 60 }

    @emit "ActivitySubmitted"


  encodeTagSuggestions: (str, tags) ->
    return  str.replace /\|(.*?):\$suggest:(.*?)\|/g, (match, prefix, title) ->
      tag = tags[title]
      return  "" unless tag
      return  "|#{prefix}:JTag:#{tag.getId()}:#{title}|"

  create: (data, callback) ->
    KD.remote.api.JNewStatusUpdate.create data, (err, activity) =>
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
      KD.showError err
      @reset()  unless err
      callback? err

      KD.mixpanel "Status update edit, success"

  reset: (lock = yes) ->
    @input.setContent ""
    @input.blur()
    @embedBox.resetEmbedAndHide()

    if lock
    then @unlockSubmit()
    else KD.utils.wait 8000, @bound "unlockSubmit"

  lockSubmit: ->
    @submitButton.disable()
    @submitButton.showLoader()

  unlockSubmit: ->
    @submitButton.enable()
    @submitButton.hideLoader()

  showPreview: ->
    return unless value = @input.getValue().trim()
    markedValue = KD.utils.applyMarkdown value
    return  if markedValue.trim() is "<p>#{value}</p>"
    tags = @input.getTokens().map (token) -> token.data if token.type is "tag"
    tagsExpanded = @utils.expandTokens markedValue, {tags}
    if not @preview
      @preview = new KDCustomHTMLView
        cssClass : "update-preview"
        partial  : tagsExpanded
        click    : => @hidePreview()
      @input.addSubView @preview
    else
      @preview.updatePartial tagsExpanded

    @setClass "preview-active"

  hidePreview:->
    @preview.destroy()
    @preview = null

    @unsetClass "preview-active"

  viewAppended: ->
    @addSubView @avatar
    @addSubView @input
    @addSubView @embedBox
    @addSubView @bugNotification
    @addSubView @helpContainer
    @input.addSubView @submitButton
    @input.addSubView @previewIcon
    @hide()  unless KD.isLoggedIn()

class ActivityEditWidget extends ActivityInputWidget
  constructor : (options = {}, data) ->
    options.cssClass = KD.utils.curry "edit-widget", options.cssClass
    options.destroyOnSubmit = yes

    super options, data

    @submitButton = new KDButtonView
      type        : "submit"
      cssClass    : "solid green"
      iconOnly    : no
      title       : "Done editing"
      callback    : @bound "submit"

    @cancelButton = new KDButtonView
      cssClass : "solid gray"
      title    : "Cancel"
      callback : => @emit "Cancel"

  viewAppended: ->
    data         = @getData()
    {body, link} = data

    content = ""
    content += "<div>#{Encoder.htmlEncode(line)}&nbsp;</div>" for line in body.split "\n"
    @input.setContent content, data
    @embedBox.loadEmbed link.link_url  if link

    @addSubView @input
    @addSubView @embedBox
    @input.addSubView @submitButton
    @input.addSubView @cancelButton
