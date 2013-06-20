class InboxNewMessageBar extends KDView
  viewAppended:->
    inboxMessageView = @

    @addSubView newMessageButton = new KDButtonView
      title     : "New Message"
      style     : "clean-gray left"
      callback  : => @createNewMessageModal()

    @addSubView @refreshButton = new KDButtonView
      style       : "clean-gray"
      icon        : yes
      iconOnly    : yes
      iconClass   : "refresh"
      loader      :
        color     : "#777777"
        diameter  : 24
      tooltip     :
        title     : "Refresh"
        placement : "left"
      callback    : =>
        @emit 'RefreshButtonClicked'

    @addSubView @markMessageAsReadButton = new KDButtonView
      style       : "clean-gray"
      icon        : yes
      iconOnly    : yes
      iconClass   : "mark-unread"
      tooltip     :
        title     : "Mark as Unread"
        placement : "left"
      callback    : =>
        @emit 'MessageShouldBeMarkedAsUnread'

    @addSubView @deleteMessageButton = new KDButtonView
      style       : "clean-gray"
      icon        : yes
      iconOnly    : yes
      iconClass   : "delete"
      tooltip     :
        title     : "Delete message"
        placement : "left"
      callback    : => @createDeleteMessageModal()

  createDeleteMessageModal:->
    modal = new KDModalView
      title          : "Delete thread"
      content        : "<div class='modalformline'>Are you sure you want to delete this thread?</div>"
      height         : "auto"
      overlay        : yes
      buttons        :
        Delete       :
          loader     :
            color    : "#ffffff"
            diameter : 16
          style      : "modal-clean-red"
          callback   : =>
            @emit 'MessageShouldBeDisowned', modal

  createNewMessageModal:->
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
              Message         :
                label         : "Message:"
                type          : "textarea"
                name          : "body"
                placeholder   : 'Enter your message'
            buttons           :
              Send            :
                title         : "Send"
                style         : "modal-clean-gray"
                type          : "submit"
              Cancel          :
                title         : "cancel"
                style         : "modal-cancel"
                callback      : -> modal.destroy()

    toField = modal.modalTabs.forms.sendForm.fields.to

    recipientsWrapper = new KDView
      cssClass      : "completed-items"

    recipient = new KDAutoCompleteController
      name                : "recipient"
      itemClass           : MemberAutoCompleteItemView
      selectedItemClass   : MemberAutoCompletedItemView
      outputWrapper       : recipientsWrapper
      form                : modal.modalTabs.forms.sendForm
      itemDataPath        : "profile.nickname"
      listWrapperCssClass : "users"
      submitValuesAsText  : yes
      dataSource          : (args, callback)=>
        {inputValue} = args
        blacklist = (data.getId() for data in recipient.getSelectedItemData())
        @emit "AutoCompleteNeedsMemberData", {inputValue, blacklist, callback}

    toField.addSubView recipient.getView()
    toField.addSubView recipientsWrapper

  disableMessageActionButtons:->
    @deleteMessageButton.getTooltip().hide()
    @deleteMessageButton.disable()
    @markMessageAsReadButton.getTooltip().hide()
    @markMessageAsReadButton.disable()

  enableMessageActionButtons:->
    @deleteMessageButton.enable()
    @markMessageAsReadButton.enable()
