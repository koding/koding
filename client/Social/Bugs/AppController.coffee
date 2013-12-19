class BugReportController extends AppController

  KD.registerAppClass this,
    name         : "Bugs"
    route        : "/Bugs"
    behaviour    : 'application'
    version      : "1.0"
    navItem      :
      title      : "Bug Reports"
      path       : "/Bugs"
      order      : 60

  constructor:(options = {}, data)->
    options.view    = new BugReportMainView
      cssClass      : "content-page bugreports"
    options.appInfo =
      name          : 'Bugs'
    super options, data

  loadView:(mainView)->
    @createFeed mainView

  createFeed: (view)->
    options =
      feedId               : 'apps.bugreport'
      itemClass            : BugStatusItemList
      limitPerPage         : 10
      useHeaderNav         : yes
      filter               :
        all                :
          title            : "Reported Bugs"
          noItemFoundText  : "There is no reported bugs"
          dataSource       : (selector, options, callback) =>
            options = tag : "bug", tagType : "user-tag"
            @createFilter options, callback
        fixed              :
          title            : "Fixed Bugs"
          noItemFoundText  : "There is no fixed bugs"
          dataSource       : (selector, options, callback) =>
            options = tag : "fixed", tagType : "system-tag"
            @createFilter options, callback
      sort                 :
        'meta.modifiedAt'  :
          title            : "Latest Bugs"
          direction        : -1

    KD.getSingleton("appManager").tell 'Feeder', 'createContentFeedController', options, (controller)=>
      view.addSubView controller.getView()
      @feedController = controller
      @getOptions().view.setOptions controller
      @emit 'ready'

  createFilter:(options, callback)->
    {JNewStatusUpdate, JTag} = KD.remote.api
    JTag.one title : options.tag, category : options.tagType, (err, sysTag)->
      return err if err
      selector       =
        limit        : 10
        slug         : sysTag.slug

      JNewStatusUpdate.fetchTopicFeed selector, (err, activities = []) ->
        activities?.map (activity) ->
          activity.on "TagsUpdated", (tags) ->
            activity.tags = KD.remote.revive tags
        callback err, activities
