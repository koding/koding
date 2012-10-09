class ChatInputFormView extends KDFormView
  constructor: ->
    super
    @input = new KDAutoComplete
      placeholder: "Click here to reply"
      name: "chatInput"
      label: new KDLabelView
        title: "chatInput"
      cssClass: "fl"
      validate      :
        rules       :
          required  : yes
        messages    :
          required  : "Reply field is empty..."

    @sendButton = new KDButtonView
      title: "Send"
      style: "clean-gray inside-button"
      callback: =>
        input = @mentionController.getView()
        chatMsg = input.getValue()
        @mentionController.clearSelectedItemData()

        input.setValue ""
        input.blur()
        input.$().blur()

        @getDelegate().emit 'ChatMessageSent', chatMsg

    @mentionController = new MentionAutoCompleteController
      view                : @input
      itemClass           : MemberAutoCompleteItemView
      form                : @
      itemDataPath        : "profile.nickname"
      listWrapperCssClass : "users"
      submitValuesAsText  : yes
      dataSource          : (args, callback)=>
        {inputValue} = args
        blacklist = (data.getId() for data in @mentionController.getSelectedItemData())
        @getDelegate().propagateEvent KDEventType : "AutoCompleteNeedsMemberData", {inputValue,blacklist,callback}

    @mentionAutoCompleteView = @mentionController.getView()

  viewAppended: ->
    @setTemplate @pistachio()
    @template.update()

  pistachio: ->
    """
    <div class="formline">
      <div>
        {{> @mentionAutoCompleteView}}
        {{> @sendButton}}
      </div>
    </div>
    """

  appendChat: (content) ->
    input = @mentionController.getView()
    currentValue = input.getValue()
    input.setValue "#{currentValue} #{content} "
    input.focus()