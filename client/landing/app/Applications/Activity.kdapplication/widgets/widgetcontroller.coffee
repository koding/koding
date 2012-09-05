class ActivityUpdateWidgetController extends KDViewController

  loadView:(mainView)->

    mainView.addWidgetPane
      paneName    : "update"
      mainContent : updateWidget = new ActivityStatusUpdateWidget
        cssClass  : "status-widget"
        callback  : (formData)=>
          @updateWidgetSubmit formData
          updateWidget.switchToSmallView()
          mainView.resetWidgets()

    mainView.addWidgetPane
      paneName    : "question"
      mainContent : questionWidget = new ActivityQuestionWidget
        callback  : @questionWidgetSubmit

    codeSnippetPane = mainView.addWidgetPane
      paneName    : "codesnip"
      mainContent : codeWidget = new ActivityCodeSnippetWidget
        delegate  : mainView
        callback  : (data)=>
          @codeSnippetWidgetSubmit data
          mainView.resetWidgets()

    mainView.addWidgetPane
      paneName    : "link"
      mainContent : linkWidget = new ActivityLinkWidget
        callback  : @linkWidgetSubmit

    mainView.addWidgetPane
      paneName    : "tutorial"
      mainContent : tutorialWidget = new ActivityTutorialWidget
        callback  : @tutorialWidgetSubmit

    mainView.addWidgetPane
      paneName    : "discussion"
      mainContent : discussionWidget = new ActivityDiscussionWidget
        callback  : @discussionWidgetSubmit

    mainView.showPane "update"

    codeSnippetPane.registerListener
      KDEventTypes : 'PaneDidShow'
      listener     : @
      callback     : -> codeWidget.widgetShown()

    @getSingleton('mainController').on "ActivityItemEditLinkClicked", (activity)=>
      mainView.setClass "edit-mode"
      switch activity.bongo_.constructorName
        when "JStatusUpdate"
          mainView.showPane "update"
          updateWidget.switchToEditView activity
        when "JCodeSnip"
          mainView.showPane "codesnip"
          codeWidget.switchToEditView activity

  updateWidgetSubmit:(data, callback)->

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
      KD.remote.api.JStatusUpdate.create data, (err, activity)=>
        callback? err, activity
        unless err
          @propagateEvent (KDEventType:"OwnActivityHasArrived"), activity
        else
          new KDNotificationView type : "mini", title : "There was an error, try again later!"

  codeSnippetWidgetSubmit:(data, callback)->

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
      KD.remote.api.JCodeSnip.create data, (err, codesnip) =>
        callback? err, codesnip
        if err
          new KDNotificationView type : "mini", title : "There was an error, try again later!"
        else
          @propagateEvent (KDEventType:"OwnActivityHasArrived"), codesnip

  questionWidgetSubmit:(data)->
    log 'creating question', data
    KD.remote.api.JActivity.create {type: 'qa', activity: data}, (error) ->
      warn 'couldnt ask question', error if error

  linkWidgetSubmit:(data)->
    log 'sharing link', data
    KD.remote.api.JActivity.create {type: 'link', activity: data}, (error) ->
      warn 'couldnt save link', error if error

  tutorialWidgetSubmit:(data)->
    log 'sharing tutorial', data
    KD.remote.api.JActivity.create {type: 'tutorial', activity: data}, (error) ->
      warn 'couldnt save tutorial', error if error

  discussionWidgetSubmit:(data)->
    log 'starting discussion', data
    KD.remote.api.JActivity.create {type: 'discussion', activity: data}, (error) ->
      warn 'couldnt save discussion', error if error

