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

    codeSharePane = mainView.addWidgetPane
      paneName    : "codeshare"
      mainContent : codeShareWidget = new ActivityCodeShareWidget
        delegate  : mainView
        callback  : (data)=>
          if submissionStopped
            return notifySubmissionStopped()
          else

            # # this forces the iframe to load the code and execute it
            # codeShareWidget.codeShareResultView.hide()
            # codeShareWidget.codeShareResultView.emit "CodeShareSourceHasChanges", data

            # reset widget tab as if it was submitted
            mainView.resetWidgets()

            # notify the user
            notifiy = new KDNotificationView
              title: "Submitting your Code Share"
              content: "This may take up to ten seconds. Thank you for your patience!"
              duration: 5

            # then wait x seconds
            window.setTimeout =>
              #only if the browser/tab did not lock up due to script execution, this will run
              @codeShareWidgetSubmit data, stopSubmission
            , 5

    mainView.addWidgetPane
      paneName    : "link"
      mainContent : linkWidget = new ActivityLinkWidget
        cssClass  : "link-widget"
        callback  : (formData)=>
          if submissionStopped
            return notifySubmissionStopped()
          else
            @linkWidgetSubmit formData, stopSubmission
            # updateWidget.switchToSmallView()
            mainView.resetWidgets()

    # mainView.addWidgetPane
    #   paneName    : "tutorial"
    #   mainContent : tutorialWidget = new ActivityTutorialWidget
    #     callback  : @tutorialWidgetSubmit

    mainView.addWidgetPane
      paneName    : "tutorial"
      mainContent : tutorialWidget = new ActivityTutorialWidget
        delegate  : mainView
        callback  : (data)=>
          if submissionStopped
            return notifySubmissionStopped()
          else
            @tutorialWidgetSubmit data, stopSubmission, ->
              log arguments

            mainView.resetWidgets()

    mainView.addWidgetPane
      paneName    : "discussion"
      mainContent : discussionWidget = new ActivityDiscussionWidget
        delegate  : mainView
        callback  : (data)=>
          if submissionStopped
            return notifySubmissionStopped()
          else
            @discussionWidgetSubmit data, stopSubmission
            mainView.resetWidgets()

    mainView.showPane "update"

    codeSnippetPane.on 'PaneDidShow', -> codeWidget.widgetShown()

    # THIS WILL DISABLE CODE SHARES
    codeSharePane.on 'PaneDidShow', -> codeShareWidget.widgetShown()

    @getSingleton('mainController').on "CreateNewActivityRequested", (type, data)=>
      appManager.openApplication "Activity"
      switch type
        # THIS WILL DISABLE CODE SHARES
        when "JCodeShare"
          mainView.showPane "codeshare"
          # log "Will add this data:", data
          codeShareWidget.setCodeShareData data

    @getSingleton('mainController').on "ActivityItemEditLinkClicked", (activity)=>
      # Remove this if can fix the ActivityStatusUpdateWidget's bug
      appManager.openApplication "Activity"
      mainView.setClass "edit-mode"

      switch activity.bongo_.constructorName
        when "JStatusUpdate"
          mainView.showPane "update"
          updateWidget.switchToEditView activity
        when "JCodeSnip"
          mainView.showPane "codesnip"
          codeWidget.switchToEditView activity
        when "JTutorial"
          mainView.showPane "tutorial"
          tutorialWidget.switchToEditView activity
        when "JDiscussion"
          mainView.showPane "discussion"
          discussionWidget.switchToEditView activity
        # THIS WILL DISABLE CODE SHARES
        when "JCodeShare"
          mainView.showPane "codeshare"
          codeShareWidget.switchToEditView activity
        when "JLink"
          mainView.showPane "link"
          linkWidget.switchToEditView activity

    @getSingleton('mainController').on "ContentDisplayItemForkLinkClicked", (activity)=>
      mainView.setClass "edit-mode"

      switch activity.bongo_.constructorName
        when "JCodeShare"
          mainView.showPane "codeshare"
          codeShareWidget.switchToForkView activity

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
      if submissionStopped
        return notifySubmissionStopped()
      KD.remote.api.JCodeSnip.create data, (err, codesnip) =>
        callback? err, codesnip
        stopSubmission()
        if err
          new KDNotificationView type : "mini", title : "There was an error, try again later!"
        else
          @propagateEvent (KDEventType:"OwnActivityHasArrived"), codesnip

  # THIS WILL DISABLE CODE SHARES

  codeShareWidgetSubmit:(data, callback)->
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

      KD.remote.api.JCodeShare.create data, (err, codeshare) =>
        callback? err, codeshare
        stopSubmission()
        if err
          new KDNotificationView type : "mini", title : "There was an error, try again later!"
        else
          @propagateEvent (KDEventType:"OwnActivityHasArrived"), codeshare



  questionWidgetSubmit:(data)->
    log 'creating question', data
    KD.remote.api.JActivity.create {type: 'qa', activity: data}, (error) ->
      warn 'couldnt ask question', error if error


  linkWidgetSubmit:(data, callback)->
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

      log "Link data is", data

      KD.remote.api.JLink.create data, (err, link) =>
        callback? err, link
        stopSubmission()
        if err
          log err
          new KDNotificationView type : "mini", title : "There was an error, try again later!"
        else
          @propagateEvent (KDEventType:"OwnActivityHasArrived"), link

  # linkWidgetSubmit:(data)->
  #   log 'sharing link', data
  #   KD.remote.api.JActivity.create {type: 'link', activity: data}, (error) ->
  #     warn 'couldnt save link', error if error

  # tutorialWidgetSubmit:(data)->
  #   log 'sharing tutorial', data
  #   KD.remote.api.JActivity.create {type: 'tutorial', activity: data}, (error) ->
  #     warn 'couldnt save tutorial', error if error

  tutorialWidgetSubmit:(data, callback)->
    if data.activity
      {activity} = data
      delete data.activity
      activity.modify data, (err, res)=>
        callback? err, res
        unless err
          new KDNotificationView type : "mini", title : "Updated the tutorial successfully"
        else
          new KDNotificationView type : "mini", title : err.message
    else
      if submissionStopped
        return notifySubmissionStopped()
      KD.remote.api.JTutorial.create data, (err, tutorial) =>

        if data.appendToList?
          KD.remote.api.JTutorialList.fetchForTutorialId data.appendToList._id,(existingList)=>

              unless existingList
                KD.remote.api.JTutorialList.create
                  title : "New List"
                  body  : ""
                , (err, list)=>
                  if err then callback err
                  else
                    list.addItemById data.appendToList._id, (err)=>
                      if err then log err
                      list.addItemById tutorial._id, (err)=>
                        if err then log err
                        callback? err, tutorial, list
              else
                existingList.addItemById tutorial._id, (err,tutlist)=>
                  if err then log err
                  else callback? err, tutorial, tutlist

        else
            callback? err, tutorial
        stopSubmission()

        if err
          new KDNotificationView type : "mini", title : "There was an error, try again later!"
        else
          @propagateEvent (KDEventType:"OwnActivityHasArrived"), tutorial

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
      KD.remote.api.JDiscussion.create data, (err, discussion) =>
        callback? err, discussion
        stopSubmission()
        if err
          new KDNotificationView type : "mini", title : "There was an error, try again later!"
        else
          @propagateEvent (KDEventType:"OwnActivityHasArrived"), discussion

