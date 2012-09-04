class ActivityUpdateWidgetController extends KDViewController

  # WIP: stop submission if user wants to submit stuff too often

  submissionStopped = no

  notifySubmissionStopped = ->

    # new KDNotificationView type : "mini", title : "Please take a little break!"

  stopSubmission = ->
    # submissionStopped = yes
    # __utils.wait 20000, -> submissionStopped = no

  loadView:(mainView)->

    mainView.addWidgetPane
      paneName    : "update"
      mainContent : updateWidget = new ActivityStatusUpdateWidget
        cssClass  : "status-widget"
        callback  : (formData)=>
          if submissionStopped
            return notifySubmissionStopped()
          else
            @updateWidgetSubmit formData, stopSubmission
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
          if submissionStopped
            return notifySubmissionStopped()
          else
            @codeSnippetWidgetSubmit data, stopSubmission
            mainView.resetWidgets()

    codeBinPane = mainView.addWidgetPane
      paneName    : "codebin"
      mainContent : codeBinWidget = new ActivityCodeBinWidget
        delegate  : mainView
        callback  : (data)=>
          if submissionStopped
            return notifySubmissionStopped()
          else
            @codeBinWidgetSubmit data, stopSubmission
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
        delegate  : mainView
        callback  : (data)=>
          msg = new KDNotificationView
            title : "You started a discussion!"
          if submissionStopped
            return notifySubmissionStopped()
          else
            @discussionWidgetSubmit data, stopSubmission
            mainView.resetWidgets()

    mainView.showPane "update"

    codeSnippetPane.registerListener
      KDEventTypes : 'PaneDidShow'
      listener     : @
      callback     : -> codeWidget.widgetShown()

    codeBinPane.registerListener
      KDEventTypes : 'PaneDidShow'
      listener     : @
      callback     : -> codeBinWidget.widgetShown()

    @getSingleton('mainController').on "ActivityItemEditLinkClicked", (activity)=>
      mainView.setClass "edit-mode"

      switch activity.bongo_.constructorName
        when "JStatusUpdate"
          mainView.showPane "update"
          updateWidget.switchToEditView activity
        when "JCodeSnip"
          mainView.showPane "codesnip"
          codeWidget.switchToEditView activity
        when "JDiscussion"
          mainView.showPane "discussion"
          codeWidget.switchToEditView activity
        when "JCodeBin"
          mainView.showPane "codebin"
          codeBinWidget.switchToEditView activity

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
      bongo.api.JStatusUpdate.create data, (err, activity)=>
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
      if submissionStopped
        return notifySubmissionStopped()
      bongo.api.JCodeSnip.create data, (err, codesnip) =>
        callback? err, codesnip
        stopSubmission()
        if err
          new KDNotificationView type : "mini", title : "There was an error, try again later!"
        else
          @propagateEvent (KDEventType:"OwnActivityHasArrived"), codesnip

  codeBinWidgetSubmit:(data, callback)->
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
      if submissionStopped
        return notifySubmissionStopped()
      bongo.api.JCodeBin.create data, (err, codebin) =>
        callback? err, codebin
        stopSubmission()
        if err
          new KDNotificationView type : "mini", title : "There was an error, try again later!"
        else
          @propagateEvent (KDEventType:"OwnActivityHasArrived"), codebin


  questionWidgetSubmit:(data)->
    log 'creating question', data
    bongo.api.JActivity.create {type: 'qa', activity: data}, (error) ->
      warn 'couldnt ask question', error if error

  linkWidgetSubmit:(data)->
    log 'sharing link', data
    bongo.api.JActivity.create {type: 'link', activity: data}, (error) ->
      warn 'couldnt save link', error if error

  tutorialWidgetSubmit:(data)->
    log 'sharing tutorial', data
    bongo.api.JActivity.create {type: 'tutorial', activity: data}, (error) ->
      warn 'couldnt save tutorial', error if error

  discussionWidgetSubmit:(data, callback)->

    if data.activity

      {activity} = data
      delete data.activity
      activity.modify data, (err, res)=>
        callback? err, res
        unless err
          new KDNotificationView type : "mini", title : "Updated the discussion successfully"
        else
          new KDNotificationView type : "mini", title : err.message
    else
      if submissionStopped
        return notifySubmissionStopped()
      bongo.api.JDiscussion.create data, (err, discussion) =>
        callback? err, discussion
        stopSubmission()
        if err
          new KDNotificationView type : "mini", title : "There was an error, try again later!"
        else
          @propagateEvent (KDEventType:"OwnActivityHasArrived"), discussion
    # log 'starting discussion', data
    # bongo.api.JActivity.create {type: 'discussion', activity: data}, (error) ->
    #   warn 'couldnt save discussion', error if error

