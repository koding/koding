class BookUpdateWidget extends KDView

  @updateSent = no

  viewAppended:->

    @setPartial "<span class='button'></span>"
    @addSubView @statusField = new KDHitEnterInputView
      type          : "text"
      defaultValue  : "Hello World!"
      focus         : =>
        @statusField.setKeyView()
      validate      :
        rules       :
          required  : yes
      callback      : (status)=> @updateStatus status

    @statusField.$().trigger "focus"
    @statusField.on "click", (event) => event.stopPropagation()


  updateStatus:(status)->
    KD.showNewKodingModal()
