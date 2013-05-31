class MemberMailLink extends KDCustomHTMLView
  constructor:(options, data)->
    options = $.extend
      tagName     : 'a'
      attributes  :
        href        : '#'
    , options
    super options, data

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    "<cite/><span>Contact</span>{{#(profile.firstName)}}"

  click:(event)->

    event.preventDefault()

    {profile} = member = @getData()
    modal = new KDModalViewWithForms
      title                   : "Compose a message"
      content                 : ""
      cssClass                : "compose-message-modal"
      height                  : "auto"
      width                   : 500
      # position                :
      #   top                     : 300
      overlay                 : yes
      tabs                    :
        navigable             : yes
        callback              : (formOutput)=>
          callback = modal.destroy.bind modal
          @emit "MessageShouldBeSent", {formOutput, callback}
        forms                 :
          sendForm            :
            fields            :
              to              :
                label         : "Send To:"
                type          : "hidden"
                name          : "recipient"
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
      name                : "recipients"
      itemClass           : MemberAutoCompleteItemView
      selectedItemClass   : MemberAutoCompletedItemView
      outputWrapper       : recipientsWrapper
      form                : modal.modalTabs.forms.sendForm
      itemDataPath        : "profile.nickname"
      listWrapperCssClass : "users"
      submitValuesAsText  : yes
      # defaultValue        : [member]
      dataSource          : (args, callback)=>
        {inputValue} = args
        blacklist = (data.getId() for data in recipient.getSelectedItemData())
        @emit "AutoCompleteNeedsMemberData", {inputValue,blacklist,callback}

    toField.addSubView recipient.getView()
    toField.addSubView recipientsWrapper

    recipient.setDefaultValue [member]
