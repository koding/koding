class HomeAppView extends KDView

  constructor:(options = {}, data)->

    super options, data

  _windowDidResize:->
    @unsetClass "extra-wide wide medium narrow extra-narrow"
    w = @getWidth()
    @setClass if w > 1500    then ""
    else if 1000 < w < 1500  then "extra-wide"
    else if 800  < w < 1000  then "wide"
    else if 600  < w < 800   then "medium"
    else if 480  < w < 600   then "narrow"
    else "extra-narrow"

  viewAppended:->

    account = KD.whoami()

    @addSubView @counterBar = new CounterGroupView
      domId    : "home-counter-bar"
      tagName  : "section"
    ,
      "MEMBERS"          : count : 0
      "RUNNING VMS"      : count : 0
      # "Lines of Code"    : count : 0
      "GROUPS"           : count : 0
      "TOPICS"           : count : 0
      "Thoughts shared"  : count : 0

    @bindCounters()

    @addSubView @homeLoginBar = new HomeLoginBar
      domId    : "home-login-bar"

    @addSubView @featuredActivities = new FeaturedActivitiesContainer
    # @addSubView @footer = new KDCustomHTMLView tagName : 'footer'

    @emit 'ready'

    @utils.wait 500, => @_windowDidResize()
    KD.getSingleton("contentPanel").on "transitionend", (event)=>
      event.stopPropagation()
      @_windowDidResize()  if $(event.target).is "#content-panel"

  bindCounters:->
    vms          = @counterBar.counters["RUNNING VMS"]
    # loc          = @counterBar.counters["Lines of Code"]
    members      = @counterBar.counters.MEMBERS
    groups       = @counterBar.counters.GROUPS
    topics       = @counterBar.counters.TOPICS
    activities   = @counterBar.counters["Thoughts shared"]
    vmController = KD.getSingleton("vmController")
    {JAccount, JTag, JGroup, CActivity} = KD.remote.api

    members.ready    => JAccount.count                 (err, count)=> members.update count    or 0
    vms.ready        => vmController.fetchTotalVMCount (err, count)=> vms.update count        or 0
    groups.ready     => JGroup.count                   (err, count)=> groups.update count     or 0
    topics.ready     => JTag.fetchCount                (err, count)=> topics.update count     or 0
    activities.ready => CActivity.fetchCount           (err, count)=> activities.update count or 0
    # loc.ready        => vmController.fetchTotalLoC     (err, count)=> loc.update count        or 0

    KD.getSingleton("activityController").on "ActivitiesArrived", (newActivities=[])->
      activities.increment newActivities.length
