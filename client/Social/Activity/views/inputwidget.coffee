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
    @input.on "Enter", @bound "submit"

    @input.on "TokenAdded", (type, token) =>
      if token.slug is "bug" and type is "tag"
        @bugNotification.show()
        @setClass "bug-tagged"

    # FIXME we need to hide bug warning in a proper way ~ GG
    @input.on "keyup", =>
      @showPreview() if @preview #Updates preview if it exists

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
      title       : "SEND"
      cssClass    : "solid green small"
      loader      : yes
      callback    : @bound "submit"

    @avatar = new AvatarView
      size      :
        width   : 42
        height  : 42
    , KD.whoami()

    @buttonBar = new KDCustomHTMLView
      cssClass : "widget-button-bar"

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

    return  if @locked
    return @reset yes  unless body = @input.getValue().trim()

    activity = @getData()
    {app}    = @getOptions()

    # fixme for bugs app

    # for token in @input.getTokens()
    #   feedType     = "bug" if token.data?.title?.toLowerCase() is "bug"
    #   {data, type} = token
    #   if type is "tag"
    #     if data instanceof JTag
    #       tags.push id: data.getId()
    #       activity?.tags.push data
    #     else if data.$suggest and data.$suggest not in suggestedTags
    #       suggestedTags.push data.$suggest

    # fixme embedbox

    # data.link_url   = @embedBox.url or ""
    # data.link_embed = @embedBox.getDataForSubmit() or {}

    @lockSubmit()

    fn = @bound if activity then 'update' else 'create'
    fn {body}, @bound 'submissionCallback'

    @emit "ActivitySubmitted"
    # fixme for bugs app

    # if app is 'bug'
    #   queue.unshift =>
    #     KD.remote.api.JTag.one slug : 'bug', (err, tag)=>
    #       if err then KD.showError err
    #       else
    #         feedType = "bug"
    #         value += " #{KD.utils.tokenizeTag tag}"
    #         tags.push id : tag.getId()
    #       queue.next()
    # dockItems = KD.singletons.dock.getItems()
    # dockItem  = dockItems.filter (item) -> item.data.title is 'Bugs'
    # if feedType is "bug" and dockItem.length is 0 then KD.singletons.dock.addItem { title : "Bugs", path : "/Bugs", order : 60 }


  submissionCallback: (err, activity) ->

    return @showError err  if err

    @reset yes
    @embedBox.resetEmbedAndHide()
    @emit "Submit", activity

    KD.mixpanel "Status update create, success", { length: activity?.body?.length }


  create: (data, callback) ->

    {appManager} = KD.singletons
    {body}       = data
    {channel}    = @getOptions()

    if channel.typeConstant is 'topic' and not body.match ///##{channel.name}///
      body += " ##{channel.name} "

    appManager.tell 'Activity', 'post', {body}, (err, activity) =>

      @reset()  unless err

      callback? err, activity

      KD.showError err,
        AccessDenied :
          title      : "You are not allowed to post activities"
          content    : 'This activity will only be visible to you'
          duration   : 5000
        KodingError  : 'Something went wrong while creating activity'

      # fixme for badges

      # KD.getSingleton("badgeController").checkBadge
      #   property   : "statusUpdates"
      #   relType    : "author"
      #   source     : "JNewStatusUpdate"
      #   targetSelf : 1


  update: (data, callback = noop) ->

    {appManager} = KD.singletons
    {channelId}  = @getOptions()
    activity     = @getData()
    {body}       = data

    return  @reset()  unless activity

    appManager.tell 'Activity', 'edit', {
      body
      id: activity.id
    }, (err, message) =>

      return KD.showError err  if err

      @reset()
      callback()

      KD.mixpanel "Status update edit, success"


  reset: (unlock = yes) ->

    @input.setContent ""
    @input.blur()
    @embedBox.resetEmbedAndHide()

    if unlock
    then @unlockSubmit()
    else KD.utils.wait 8000, @bound "unlockSubmit"


  showError: (err) ->

    KD.showError err
    @unlockSubmit()


  lockSubmit: ->

    @locked = yes
    @submitButton.disable()
    @submitButton.showLoader()


  unlockSubmit: ->

    @locked = no
    @submitButton.enable()
    @submitButton.hideLoader()


  showPreview: ->

    return unless value = @input.getValue().trim()

    data            =
      on            : -> return this
      watch         : -> return this
      account       : KD.whoami().bongo_
      body          : value
      typeConstant  : 'post'
      replies       : []
      interactions  :
        like        :
          actorsCount : 0
          actorsPreview : []
      meta          :
        createdAt   : new Date

    @preview?.destroy()
    @addSubView @preview = new ActivityListItemView cssClass: 'preview', data
    @preview.addSubView new KDCustomHTMLView
      cssClass : 'preview-indicator'
      partial  : 'Previewing'
      click    : @bound 'hidePreview'

    @setClass "preview-active"


  hidePreview:->

    @preview.destroy()
    @preview = null
    @unsetClass "preview-active"


  viewAppended: ->

    @addSubView @avatar
    @addSubView @input
    @addSubView @buttonBar
    @addSubView @embedBox
    @addSubView @bugNotification
    @addSubView @helpContainer
    @buttonBar.addSubView @submitButton
    @buttonBar.addSubView @previewIcon
    @hide()  unless KD.isLoggedIn()
