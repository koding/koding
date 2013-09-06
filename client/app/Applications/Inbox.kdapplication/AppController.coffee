class InboxAppController extends AppController

  KD.registerAppClass this,
    name         : "Inbox"
    route        : "/:name?/Inbox"
    hiddenHandle : yes
    navItem      :
      title      : "Inbox"
      path       : "/Inbox"

  {race} = Bongo

  constructor:(options = {}, data)->

    options.view    = new InboxView
      cssClass      : "inbox-application"
    options.appInfo =
      name          : "Inbox"

    super options, data

    @selection = {}

    @on 'MessageShouldBeSent', ({formOutput,callback})=>
      @prepareMessage formOutput, callback

    nc = KD.getSingleton 'notificationController'
    nc.on 'PrivateMessageSent', =>
      @emit 'PrivateMessageReceived'
    nc.on 'ReplyIsAdded', ({subject:{constructorName}})=>
      @emit 'PrivateMessageReceived'  if constructorName is 'JPrivateMessage'

  fetchMessages:(options, callback)->
    KD.whoami().fetchMail? options, callback

  fetchAutoCompleteForToField:(inputValue,blacklist,callback)->
    KD.remote.api.JAccount.byRelevance inputValue,{blacklist},(err,accounts)->
      callback accounts

  createNewMessageModal:(users)->
    modal = new KDModalViewWithForms
      title                   : "Compose a message"
      content                 : ""
      cssClass                : "compose-message-modal"
      height                  : "auto"
      width                   : 500
      overlay                 : yes
      tabs                    :
        navigable             : yes
        callback              : (formOutput)=>
          callback = modal.destroy.bind modal
          @emit "MessageShouldBeSent", {formOutput,callback}
        forms                 :
          sendForm            :
            fields            :
              to              :
                label         : "Send To:"
                type          : "hidden"
                name          : "dummy"
              subject         :
                label         : "Subject:"
                placeholder   : 'Enter a subject'
                name          : "subject"
                testPath      : "inbox-new-message-subject"
                validate      :
                  rules       :
                    required  : yes
                  messages    :
                    required  : "Subject field is required!"
              message         :
                label         : "Message:"
                type          : "textarea"
                name          : "body"
                testPath      : "inbox-new-message-body"
                placeholder   : 'Enter your message'
                validate      :
                  rules       :
                    required  : yes
                  messages    :
                    required  : "Message field is required!"
            buttons           :
              Send            :
                title         : "Send"
                style         : "modal-clean-gray"
                type          : "submit"
                testPath      : "inbox-new-message-submit"
              Cancel          :
                title         : "cancel"
                style         : "modal-cancel"
                callback      : -> modal.destroy()

    {subject, message} = modal.modalTabs.forms.sendForm.inputs
    toField            = modal.modalTabs.forms.sendForm.fields.to
    subjectField       = modal.modalTabs.forms.sendForm.fields.subject

    recipientsWrapper = new KDView
      cssClass      : "completed-items"

    recipient = new KDAutoCompleteController
      name                : "recipient"
      itemClass           : MemberAutoCompleteItemView
      selectedItemClass   : MemberAutoCompletedItemView
      outputWrapper       : recipientsWrapper
      form                : modal.modalTabs.forms.sendForm
      itemDataPath        : "profile.nickname"
      testPath            : "inbox-new-message-to"
      listWrapperCssClass : "users"
      submitValuesAsText  : yes
      dataSource          : (args, callback)=>
        {inputValue} = args
        blacklist = (data.getId() for data in recipient.getSelectedItemData())
        @fetchAutoCompleteForToField inputValue, blacklist, callback

    toField.addSubView recipient.getView()
    toField.addSubView recipientsWrapper
    if users
      recipient.setDefaultValue users

      if users.length is 1
        toField.hide()

        toName = KD.utils.getFullnameFromAccount users.first
        myName = KD.utils.getFullnameFromAccount()

        subject.setValue "Private message from #{myName}"
        subjectField.hide()

        modal.setTitle "#{modal.getOption('title')} to <b>#{toName}</b>"

      message.$().focus()
    else
      recipient.getView().$input().focus()

  loadView:(mainView)->
    mainView.createCommons()
    mainView.createTabs()

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

    # in constructor we already add another listener to use without views
    # we have to remove all the listeners and bind a new one to send
    # after view is loaded.
    @off 'MessageShouldBeSent'
    @on 'MessageShouldBeSent', ({formOutput,callback})=>
      @prepareMessage formOutput, callback, newMessageBar

    @on 'PrivateMessageReceived', -> newMessageBar?.emit 'RefreshButtonClicked'

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
    if KD.isGuest()
      return new KDNotificationView
        title : "Sending private message for guests not allowed."

    KD.remote.api.JPrivateMessage.create messageDetails, callback

  prepareMessage:(formOutput, callback, newMessageBar)->
    {body, subject, recipients} = formOutput

    to = recipients.join ' '

    @sendMessage {to, body, subject}, (err, message)=>
      new KDNotificationView
        title     : if err then "There was an error sending your message - try again" else "Message Sent!"
        duration  : 1000
      message.mark 'read'
      newMessageBar?.emit 'RefreshButtonClicked'
      callback? err, message
