kd                     = require 'kd'
KDCustomHTMLView       = kd.CustomHTMLView
KDTabView              = kd.TabView
KDTabPaneView          = kd.TabPaneView
KDView                 = kd.View
ActivityPane           = require './views/activitypane'
AnnouncementPane       = require './views/announcementpane'
MoreChannelsModal      = require './sidebar/morechannelsmodal'
PrivateMessagePane     = require './views/privatemessage/privatemessagepane'
PrivateMessageForm     = require './views/privatemessage/privatemessageform'
SingleActivityPane     = require './views/singleactivitypane'
TopicMessagePane       = require './views/topicmessagepane'
TopicSearchModal       = require './sidebar/topicsearchmodal'
globals                = require 'globals'
isChannelCollaborative = require 'app/util/isChannelCollaborative'
isKoding               = require 'app/util/isKoding'
isGroup                = require 'app/util/isGroup'
ChatSearchModal        = require 'app/activity/sidebar/chatsearchmodal'
OnboardingEvent        = require 'app/onboarding/onboardingevent'


module.exports = class ActivityAppView extends KDView

  {permissions} = globals.config

  canListMembers = -> 'list members' in permissions
  isPrivateGroup = -> not isKoding() and isGroup()

  constructor:(options = {}, data)->

    options.cssClass   = 'content-page activity clearfix'
    options.domId      = 'content-page-activity'

    super options, data

    {
      appStorageController
      windowController
      mainView
    }            = kd.singletons
    {entryPoint} = globals.config
    # this is also assigned in viewAppended
    # when you land on a privateMessage directly
    # sidebar here becomes undefined
    # and once view is appended we make sure
    # that the sidebar property is set.
    # a terrible hack, should be addressed later. - SY
    @sidebar     = mainView.activitySidebar
    @appStorage  = appStorageController.storage 'Activity', '2.0'
    @panePathMap = {}

    @tabs = new KDTabView
      tagName             : 'main'
      hideHandleContainer : yes
    @tabs.unsetClass 'kdscrollview'

    @tabs.on 'PaneDidShow', (pane) =>
      if type = pane.getData()?.typeConstant
        @tabs.setAttribute 'class', kd.utils.curry 'kdview kdtabview', type

    { router } = kd.singletons

    router.on 'AlreadyHere', (path, options) =>

      [slug] = options.frags

      return  if slug isnt 'Activity'

      path = helper.sanitizePath path
      pane = @panePathMap[path]

      pane?.refreshContent? path


  viewAppended: ->

    # see above for the terrible hack note - SY
    @sidebar ?= kd.singletons.mainView.activitySidebar
    @addSubView @tabs

    @parent.on 'KDTabPaneActive', =>

      return  unless pane = @tabs.getActivePane()

      kd.utils.defer -> pane.applyScrollTops()
      kd.utils.wait 50, -> pane.scrollView.wrapper.emit 'MutationHappened'

    @parent.on 'KDTabPaneInactive', =>

      return  unless pane = @tabs.getActivePane()

      pane.setScrollTops()


  # type: [topic|post|message|chat|null]
  # slug: [slug|id|name]
  open: (type, slug) ->

    {socialapi, router, notificationController} = kd.singletons

    # if type is 'topic' then @widgetsBar.show() else @widgetsBar.hide()

    kallback = (data) =>
      name = if slug then "#{type}-#{slug}" else type
      pane = @tabs.getPaneByName name

      unless @sidebar.selectedItem
        @sidebar.selectItemByRouteOptions type, slug

      if pane
      then @tabs.showPane pane
      else @createTab name, data

      @runOnboarding type, slug

    @sidebar.selectItemByRouteOptions type, slug
    item = @sidebar.selectedItem

    if not item
      type_ = switch type
        when 'message' then 'privatemessage'
        when 'post'    then 'activity'
        else type
      socialapi.cacheable type_, slug, (err, data) =>
        if err
          # if channel is redirected to another
          # handle here
          if err.error is "moved_permanently"
            res = try JSON.parse err.description
            location = "/Activity/Public"

            if res.typeConstant isnt "group"
              location = "/Activity/Topic/#{res.rootName}"

            global.location.href = location
            return

          router.handleNotFound router.getCurrentPath()
        else
          { typeConstant } = data
          index = if typeConstant is 'topic' then 2 else 0 # 2 because we put topics after #koding #changelog
          return  if isChannelCollaborative data
          # we don't put posts in the sidebar anymore - sy
          @sidebar.addItem data, index  if typeConstant isnt 'post'
          kallback data

    else
      kallback item.getData()


  runOnboarding: (type, slug) ->

    switch type
      when 'topic'
        onboardingEvent = if slug is 'public' then OnboardingEvent.PublicChannelViewed else OnboardingEvent.OtherChannelViewed
      when 'announcement'
        onboardingEvent = OnboardingEvent.ChangelogChannelViewed  if slug is 'changelog'
      when 'message'
        onboardingEvent = if slug is 'new' then OnboardingEvent.NewPrivateMessageOpened else OnboardingEvent.PrivateMessagesViewed

    kd.singletons.onboardingController.runOnboarding onboardingEvent  if onboardingEvent


  openNext: ->

    items    = @sidebar.getItems()
    selected = @sidebar.selectedItem

    index = items.indexOf selected
    next  = index + 1
    next  = Math.min next, items.length - 1
    item  = items[next]

    {route, href} = item.getOptions()

    kd.singletons.router.handleRoute route or href


  openPrev: ->

    items    = @sidebar.getItems()
    selected = @sidebar.selectedItem

    index = items.indexOf selected
    prev  = Math.min Math.max(0, index - 1), items.length - 1
    item  = items[prev]

    {route, href} = item.getOptions()

    kd.singletons.router.handleRoute route or href


  createTab: (name, data) ->

    channelId = data.id
    type      = data.typeConstant

    paneClass = switch type
      when 'topic'          then TopicMessagePane
      when 'privatemessage' then PrivateMessagePane
      when 'post'           then SingleActivityPane
      else
        if name is 'announcement-changelog'
        then AnnouncementPane
        else ActivityPane

    @tabs.addPane pane = new paneClass {name, type, channelId}, data

    path = helper.sanitizePath kd.singletons.router.getCurrentPath()

    @panePathMap[path] = pane

    pane.on 'LeftChannel', => @tabs.removePane pane

    return pane


  showNewMessageForm: ->

    # @widgetsBar.hide()
    @tabs.addPane pane = (new KDTabPaneView cssClass : 'privatemessage' ), yes
    pane.addSubView form = new PrivateMessageForm
    form.once 'KDObjectWillBeDestroyed', @tabs.lazyBound 'removePane', pane

    @runOnboarding 'message', 'new'


  showAllTopicsModal: ->

    @open 'topic', 'public'  unless @tabs.getActivePane()

    return new TopicSearchModal delegate : this

  showFollowingTopicsModal: ->

    @open 'topic', 'public'  unless @tabs.getActivePane()

    modalClass = MoreChannelsModal
    {moreLink} = @sidebar.sections.channels

    kd.utils.defer @lazyBound 'showMoreModal', {modalClass, moreLink}


  showAllChatsModal: ->

    @open 'topic', 'public'  unless @tabs.getActivePane()

    modalClass = ChatSearchModal
    {moreLink} = @sidebar.sections.messages

    kd.utils.defer @lazyBound 'showMoreModal', {modalClass, moreLink}


  showMoreModal: ({modalClass, moreLink}) ->

    modal = new modalClass { delegate : this }

    modal.addSubView new KDCustomHTMLView
      cssClass : 'arrow'
      position :
        top    : moreLink.getY()
        left   : moreLink.getX() + moreLink.getWidth()


  helper =

    sanitizePath: (path) ->

      if /\/Activity\/Public/.test path
      then '/Activity/Public'
      else path



