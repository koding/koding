class InboxAppController extends AppController

  {race} = Bongo

  constructor:(options, data)->
    view = new InboxView cssClass : "inbox-application"
    options = $.extend {view},options
    super options,data
    @selection = {}

  bringToFront:()->
    @propagateEvent (KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes),
      options :
        name : 'Inbox'
      data : @mainView

  fetchMessages:(options, callback)->
    KD.whoami().fetchMail? options, callback

  fetchAutoCompleteForToField:(inputValue,blacklist,callback)->
    KD.remote.api.JAccount.byRelevance inputValue,{blacklist},(err,accounts)->
      callback accounts

  loadView:(mainView)->
    mainView.createCommons()
    mainView.createTabs()

    mainView.registerListener
      KDEventTypes : "ToFieldHasNewInput"
      listener     : @
      callback     : (pubInst, data)->
        return if data.disabledForBeta
        {type,action} = data
        mainView.showTab type
        if action is "change-tab"
          mainView.showTab data.type
        else
          mainView.sort data.type

    mainView.on 'NotificationIsSelected', ({notification, event, location})=>
      # nothing yet, coming soon

    {newMessageBar} = mainView

    mainView.on 'MessageIsSelected', ({item, event})=>
      data = item.getData()
      data.mark 'read', (err)->
        item.unsetClass 'unread' unless err
      # unless event.shiftKey
      #   @deselectMessages()
      @deselectMessages()
      if item.paneView?
        {paneView} = item
        mainView.inboxMessagesContainer.showPane item.paneView
      else
        paneView = new KDTabPaneView
          name: data.subject
          hiddenHandle: yes
        mainView.inboxMessagesContainer.addPane paneView
        detail = new InboxMessageDetail cssClass : "message-detail", data

        detail.on 'viewAppended', ->
          data.restComments 0, (err, comments)-> # log arguments, data

        paneView.addSubView detail
        paneView.detail = detail
        item.paneView = paneView

      mainView.messagesSplit.resizePanel "33%", 0
      # this is to change resize behavior of the split
      # initially it has full width first panel
      # after a message opens we change the defaults
      mainView.messagesSplit.getOptions().sizes = ["33%", null]

      newMessageBar.enableMessageActionButtons()
      @selectMessage data, item, paneView

    newMessageBar.on "AutoCompleteNeedsMemberData", (event)=>
      {callback,inputValue,blacklist} = event
      @fetchAutoCompleteForToField inputValue,blacklist,callback

    newMessageBar.on 'MessageShouldBeSent', ({formOutput,callback})=>
      @prepareMessage formOutput, callback, newMessageBar

    newMessageBar.on 'MessageShouldBeDisowned', do =>
        if not @selection
          newMessageBar.disableMessageActionButtons()
          modal.destroy()
          return
        disownAll = (items, callback)->
          disownItem = race (i, item, fin)->
            item.data.disown (err)->
              if err
                fin err
              else
                fin()
          , callback
          disownItem item for own id, item of items
        (modal) =>
          disownAll @selection, =>
            for own id, {item, paneView} of @selection
              item.destroy()
              paneView.destroy()
              @deselectMessages()
            modal.destroy()
            newMessageBar.disableMessageActionButtons()

    newMessageBar.on 'MessageShouldBeMarkedAsUnread', =>
      for own id, {item, data} of @selection
        data.unmark 'read', (err)=>
          log err if err
          item.setClass 'unread' unless err
          item.paneView?.hide()
          newMessageBar.disableMessageActionButtons()

  goToNotifications:(notification)->
    @getView().showTab "notifications"
    @mainView.emit 'NotificationIsSelected', {item: notification, event} if notification?

  goToMessages:(message)->
    @getView().showTab "messages"
    @mainView.emit 'MessageSelectedFromOutside', message

  selectMessage:(data, item, paneView)->
    @selection[data.getId()] = {
      data
      item
      paneView
    }

  deselectMessages:->
    @selection = {}

  sendMessage:(messageDetails, callback)->
    # log "I just send a new message: ", messageDetails
    KD.remote.api.JPrivateMessage.create messageDetails, callback

  prepareMessage:(formOutput, callback, newMessageBar)=>
    {body, subject, recipients} = formOutput

    to = recipients.join ' '

    @sendMessage {to, body, subject}, (err, message)=>
      new KDNotificationView
        title     : if err then "There was an error sending your message - try again" else "Message Sent!"
        duration  : 1000
      message.mark 'read'
      newMessageBar.emit 'RefreshButtonClicked'
      callback? err, message
