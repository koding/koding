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
        allbugs            :
          title            : "Reported Bugs"
          noItemFoundText  : "There is no reported bugs"
          dataSource       : (selector, options, callback) =>
            selector       =
              limit        : 10
              slug         : "bug"
            KD.remote.api.JNewStatusUpdate.fetchTopicFeed selector, (err, activities = []) ->
              activities?.map (activity) ->
                activity.on "TagsUpdated", (tags) ->
                  activity.tags = KD.remote.revive tags
              callback err, activities
      sort                 :
        'meta.modifiedAt'  :
          title            : "Latest Bugs"
          direction        : -1

    KD.getSingleton("appManager").tell 'Feeder', 'createContentFeedController', options, (controller)=>
      view.addSubView controller.getView()
      @feedController = controller
      @emit 'ready'

class BugStatusItemList extends KDListItemView

  constructor:( options={}, data)->
    options.cssClass = "activity-item status"
    super options, data

    bugTags     = ["fixed", "postponed", "not repro","duplicate","by design"]
    @statusItem = new StatusActivityItemView options, data
    @bugstatus  = new KDMultipleChoice
      cssClass     : "clean-gray editor-button control-button"
      labels       : bugTags
      multiple     : no
      defaultValue : "done"
      size         : "tiny"
      callback     : (value)=>
        KD.remote.api.JTag.fetchSystemTags {},limit:50, (err, systemTags)=>
          if err or systemTags.length < 1
            return new KDNotificationView
              title : err or "no system tag found."

          {body}     = data
          statusTags = data.tags
          newTags    = []

          #TODO : IF tag count of status is bigger, that become useless change to for loop
          tagToRemove = tag for tag in statusTags when tag.title in bugTags
          tagToAdd    = tag for tag in systemTags when tag.title is value

          return new KDNotificationView title: "Tag not found!" unless tagToAdd

          # if system tag exist, remove it then add new tag
          if tagToRemove
            index = statusTags.indexOf tagToRemove
            statusTags.splice index, 1
            # remove tag from body
            stringToRemove = "|#:JTag:#{tagToRemove.getId()}|"
            stringToAdd    = "|#:JTag:#{tagToAdd.getId()}|"
            body = body.replace stringToRemove, stringToAdd

            newTags.push id : tagToAdd.getId()
            newTags.push id:tag.getId() for tag in statusTags

            options  =
              body   : body
              meta   :
                tags : newTags

            data.modify options, (err)->
              log err if err

          else
            stringToAdd = "|#:JTag:#{tagToAdd.getId()}|"
            body       += " #{stringToAdd}"
            newTags.push id : tagToAdd.getId()
            newTags.push id:tag.getId() for tag in statusTags

            options  =
              body   : body
              meta   :
                tags : newTags

            data.modify options, (err)->
              log err if err

    @addSubView @statusItem
    @addSubView @bugstatus

  viewAppended: JView::viewAppended

