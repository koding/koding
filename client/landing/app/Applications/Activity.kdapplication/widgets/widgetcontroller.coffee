class ActivityUpdateWidgetController extends KDViewController

  # WIP: stop submission if user wants to submit stuff too often

  submissionStopped = no

  notifySubmissionStopped = ->

    # new KDNotificationView type : "mini", title : "Please take a little break!"

  stopSubmission = ->
    # submissionStopped = yes
    # __utils.wait 20000, -> submissionStopped = no

  loadView:(mainView)->
    activityController = @getSingleton('activityController')

    paneMap = [
        name            : 'statusUpdatePane'
        paneName        : 'update'
        cssClass        : 'status-widget'
        constructorName : 'JStatusUpdate'
        widgetName      : 'updateWidget'
        widgetType      : ActivityStatusUpdateWidget
      ,
        name            : 'codeSnippetPane'
        paneName        : 'codesnip'
        constructorName : 'JCodeSnip'
        widgetName      : 'codeWidget'
        widgetType      : ActivityCodeSnippetWidget
      ,
      #   name            : 'codeSharePane'
      #   paneName        : 'codeshare'
      #   constructorName : 'JCodeShare'
      #   widgetName      : 'codeShareWidget'
      #   widgetType      : ActivityCodeShareWidget
      # ,
      #   name            : 'linkPane'
      #   paneName        : 'link'
      #   constructorName : 'JLink'
      #   widgetName      : 'linkWidget'
      #   widgetType      : ActivityLinkWidget
      # ,
        name            : 'tutorialPane'
        paneName        : 'tutorial'
        constructorName : 'JTutorial'
        widgetName      : 'tutorialWidget'
        widgetType      : ActivityTutorialWidget
      ,
        name            : 'discussionPane'
        paneName        : 'discussion'
        constructorName : 'JDiscussion'
        widgetName      : 'discussionWidget'
        widgetType      : ActivityDiscussionWidget
      ]


    widgetController = @
    paneMap.forEach (pane)=>
      @[pane.name] = mainView.addWidgetPane
        paneName : pane.paneName
        mainContent : @[pane.widgetName] = new pane.widgetType
          pane      : pane
          cssClass  : pane.cssClass or "#{pane.paneName}-widget"
          callback  : (formData)->
            if submissionStopped
              return notifySubmissionStopped()
            else
              widgetController.widgetSubmit formData, @getOptions().pane.constructorName, stopSubmission
              if @getOptions().pane.constructorName in ['JStatusUpdate']
                widgetController[@getOptions().pane.widgetName].switchToSmallView()
              mainView.resetWidgets()

    mainView.showPane "update"

    @codeSnippetPane.on 'PaneDidShow', => @codeWidget.widgetShown()

    switchForEditView = (type,data,fake=no)=>
      switch type
        when "JStatusUpdate"
          mainView.showPane "update"
          @updateWidget.switchToEditView data, fake
        when "JCodeSnip"
          mainView.showPane "codesnip"
          @codeWidget.switchToEditView data, fake
        when "JTutorial"
          mainView.showPane "tutorial"
          @tutorialWidget.switchToEditView data, fake
        when "JDiscussion"
          mainView.showPane "discussion"
          @discussionWidget.switchToEditView data, fake
        when "JCodeShare"
          mainView.showPane "codeshare"
          @codeShareWidget.switchToEditView data, fake
        when "JLink"
          mainView.showPane "link"
          @linkWidget.switchToEditView data, fake

    @on 'editFromFakeData', (fakeData)=>
      switchForEditView fakeData.fakeType, fakeData, yes

    @getSingleton('mainController').on "ActivityItemEditLinkClicked", (activity)=>
      # Remove this if can fix the ActivityStatusUpdateWidget's bug
      KD.getSingleton("appManager").openApplication "Activity"
      mainView.setClass "edit-mode"
      switchForEditView activity.bongo_.constructorName, activity

  emitFakeData:(type, data)->

    fakeData = $.extend {fakeType : type}, data
    @emit 'FakeActivityHasArrived', createFakeDataStructureForOwner fakeData


  widgetSubmit:(data,constructorName,callback)->
    # if troll clear the tag input
    data.meta?.tags = [] if KD.checkFlag 'exempt'
    if data.activity
      {activity} = data
      delete data.activity
      activity.modify data, (err, res)=>
        callback? err, res
        unless err
          new KDNotificationView type : "mini", title : "Updated successfully"
        else
          new KDNotificationView type : "mini", title : err.message
    else
      @emitFakeData constructorName, data
      updateTimeout = @utils.wait 20000, =>
        @emit 'OwnActivityHasFailed', data

      KD.getSingleton("appManager").tell 'Activity', 'fetchCurrentGroup', (currentGroup)=>
        data.group = currentGroup
        KD.remote.api[constructorName].create data, (err, activity)=>
          callback? err, activity
          unless err
            @utils.killWait updateTimeout
            @emit 'OwnActivityHasArrived', activity
          else
            @emit 'OwnActivityHasFailed', data
            new KDNotificationView
              title : "There was an error, try again later!"

  createFakeTags = (originalTags)->

    # prepare fake tags
    tags = []
    for tag in originalTags
      fakeTag       = new KD.remote.api.JTag {}, tag
      fakeTag       = $.extend {},fakeTag,
        title       : tag.title or tag.$suggest
        body        : tag.title or tag.$suggest
        counts      :
          followers : 0
          following : 0
          tagged    : 0
        slug        : KD.utils.slugify (tag.title or tag.$suggest)
      tags.push fakeTag
    tags

  createFakeDataStructureForOwner = (activity)->

    oldActivity = activity
    constructorName = activity.fakeType
    # prepare fake post
    fakePost      = new KD.remote.api[constructorName] {}, activity
    fakePost      = $.extend yes,{},fakePost,
      fake        : yes
      slug        : 'fakeActivity'
      title       : activity.title or activity.body
      body        : activity.body
      counts      :
        followers : 0
        following : 0
      meta        :
        createdAt : (new Date (Date.now())).toISOString()
        likes     : 0
        modifiedAt: (new Date (Date.now())).toISOString()
      origin      : KD.whoami()
      link        : oldActivity.link or oldActivity
      repliesCount: 0
      opinionCount: 0
      originId    : KD.whoami()._id
      originType  : 'JAccount'
      _id         : 'fakeIdfakeId' # 12bytes, as expected

    if oldActivity?.meta?.tags
      fakePost        = $.extend fakePost,
        tags          : createFakeTags oldActivity?.meta?.tags

    if activity?.code
      fakePost        = $.extend fakePost,
        attachments   : [
          description : activity.body
          content     : activity.code
          syntax      : activity.syntax
        ]
    fakePost