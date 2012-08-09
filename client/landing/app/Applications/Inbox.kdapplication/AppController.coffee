class Inbox12345 extends AppController

  {race} = bongo

  constructor:(options, data)->
    view = new (KD.getPageClass 'Inbox') cssClass : "inbox-application"
    options = $.extend {view},options
    super options,data
    @selection = {}

  bringToFront:()->
    @propagateEvent (KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes),
      options :
        name : 'Inbox'
      data : @mainView

  initAndBringToFront:(options,callback)->
    initApplication options, ->
      @bringToFront()
      callback()

  initApplication:(options, callback)->
    callback()

  fetchMessages:(options, callback)->
    # log "FETCH MESSAGES INTERNAL"
    {currentDelegate} = KD.getSingleton('mainController').getVisitor()
    currentDelegate.fetchMail? options, callback

  fetchAutoCompleteForToField:(inputValue,blacklist,callback)->
    bongo.api.JAccount.byRelevance inputValue,{blacklist},(err,accounts)->
      callback accounts

  loadView:(mainView)->
    mainView.createCommons()
    mainView.createTabs()

    {currentDelegate} = KD.getSingleton('mainController').getVisitor()

    # currentDelegate.fetchPrivateChannel (err, channel)->
    #   console.log channel

    # mainView.inboxMessagesList.on 'ReceivedClickElsewhere', =>
    #   @deselectMessages()

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

    # @listenTo
    #   KDEventTypes: 'ReplyShouldBeSent'
    #   listenedToInstance: view
    #   callback: (pubInst, options)->
    #     {reply, message} = options
    #     message.reply reply, (err)->
    #       console.log err

    mainView.registerListener
      KDEventTypes      : 'NotificationIsSelected'
      listener          : @
      callback          :(pubInst, {notification, event, location})=>
        # nothing yet, coming soon

    {newMessageBar, inboxMessagesList} = mainView

    mainView.registerListener
      KDEventTypes: 'MessageIsSelected'
      listener    : @
      callback    :(pubInst,{item, event})=>
        # log arguments,"::::"
        data = item.getData()
        data.mark 'read', (err)->
          item.unsetClass 'unread' unless err
        # unless event.shiftKey
        #   @deselectMessages()
        @deselectMessages()
        mainView.messageInputElement.setData data
        if item.paneView?
          {paneView} = item
          mainView.inboxMessagesContainer.showPane item.paneView
        else
          paneView = new KDTabPaneView
            name: data.subject
            hiddenHandle: yes
          mainView.inboxMessagesContainer.addPane paneView
          detail = new InboxMessageDetail cssClass : "message-detail", data

          detail.registerListener
            KDEventTypes: 'viewAppended'
            listener: @
            callback: =>
              data.restComments 0, (err, comments)-> # log arguments, data

          paneView.addSubView detail
          paneView.detail = detail
          item.paneView = paneView

        @selectMessage data, item, paneView

    newMessageBar.registerListener
      KDEventTypes  : "AutoCompleteNeedsMemberData"
      listener      : @
      callback      : (pubInst,event)=>
        {callback,inputValue,blacklist} = event
        @fetchAutoCompleteForToField inputValue,blacklist,callback

    newMessageBar.registerListener
      KDEventTypes  : 'MessageShouldBeSent'
      listener      : @
      callback      : (pubInst,{formOutput,callback})->
        @prepareMessage formOutput,callback

    newMessageBar.registerListener
      KDEventTypes: 'MessageShouldBeDisowned'
      listener    : @
      callback    : do=>
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
        (pubInst, modal) =>
          # log modal
          disownAll @selection, =>
            # log "2", modal
            for own id, {item, paneView} of @selection
              item.destroy()
              paneView.destroy()
              @deselectMessages()
            modal.destroy()
            newMessageBar.disableMessageActionButtons()

    newMessageBar.registerListener
      KDEventTypes: 'MessageShouldBeMarkedAsUnread'
      listener    : @
      callback    : =>
        for own id, {item, data} of @selection
          # log 'marking unread'
          data.unmark 'read', (err)=>
            log err if err
            item.setClass 'unread' unless err
            item.paneView?.hide()
            newMessageBar.disableMessageActionButtons()

  goToNotifications:(notification)->
    @getView().showTab "notifications"
    @mainView.propagateEvent KDEventType : 'NotificationIsSelected', {item: notification, event} if notification?

  goToMessages:(message)->
    @getView().showTab "messages"
    @mainView.propagateEvent KDEventType : 'MessageSelectedFromOutside', {item: message, event}

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
    bongo.api.JPrivateMessage.create messageDetails, callback

  prepareMessage:(formOutput, callback)=>
    {body, subject, recipients} = formOutput

    to = recipients.join ' '

    @sendMessage {to, body, subject}, (err, message)->
      new KDNotificationView
        title     : if err then "There was an error sending your message - try again" else "Message Sent!"
        duration  : 1000
      message.mark 'read'
      callback? err, message
