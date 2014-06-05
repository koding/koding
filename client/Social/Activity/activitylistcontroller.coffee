class ActivityListController extends KDListViewController

  {dash} = Bongo

  constructor:(options={}, data)->

    options.startWithLazyLoader  ?= yes
    options.lazyLoaderOptions    ?=
      spinnerOptions              : size : width : 24
      partial                     : ''
    options.showHeader           ?= yes
    options.scrollView           ?= no
    options.wrapper              ?= no
    options.boxed                ?= yes
    options.itemClass           or= ActivityListItemView

    options.viewOptions         or= {}
    {viewOptions}                 = options
    viewOptions.cssClass          = KD.utils.curry 'activity-related', viewOptions.cssClass
    viewOptions.comments         ?= yes
    viewOptions.dataPath          = 'id'

    options.noItemFoundWidget    ?= new KDCustomHTMLView
      cssClass : 'lazy-loader hidden'
      partial  : 'There is no activity.'

    super options, data

    @hiddenItems = []

    @messageEventHelper = new MessageEventHelper


  instantiateListItems: (messages) ->

    messages = messages.filter (message) => not @itemForId message.getId()
    messages.forEach @messageEventHelper.bound 'bindListeners'

    super messages


  # LEGACY

  postIsCreated: (post) =>
    bugTag   = tag for tag in post.subject.tags when tag.slug is 'bug'
    subject  = @prepareSubject post
    instance = @addItem subject, 0

    return  unless instance

    if bugTag and not @isMine subject
      instance.hide()
      @hiddenItems.push instance

    liveUpdate = @activityHeader?.liveUpdateToggle.getState().title is 'live'
    if not liveUpdate and not @isMine subject
      instance.hide()
      @hiddenItems.push instance
      @activityHeader.newActivityArrived() unless bugTag

  prepareSubject:(post)->
    {subject} = post
    subject = KD.remote.revive subject
    @bindItemEvents subject
    return subject

  isMine:(activity)->
    id = KD.whoami().getId()
    id? and id in [activity.originId, activity.anchor?.id]

  unhideNewHiddenItems: ->

    @hiddenItems.forEach (item)-> item.show()

    @hiddenItems = []

    unless KD.getSingleton("router").getCurrentPath() is "/Activity"
      KD.getSingleton("activityController").clearNewItemsCount()
