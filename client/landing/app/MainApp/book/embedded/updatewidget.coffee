class BookUpdateWidget extends KDView

  viewAppended:->

    @setPartial "<span class='button'></span>"
    @addSubView @statusField = new KDHitEnterInputView
      type          : "text"
      defaultValue  : "Hello World!"
      focus         : => @statusField.setKeyView()
      click         : (pubInst, event)=>
        event.stopPropagation()
        no
      validate      :
        rules       :
          required  : yes
      callback      : (status)=> @updateStatus status

    @statusField.$().trigger "focus"


  updateStatus:(status)->

    @getDelegate().$().css left : -1349

    bongo.api.JStatusUpdate.create body : status, (err,reply)=>
      @utils.wait 2000, =>
        @getDelegate().$().css left : -700
      unless err
        appManager.tell 'Activity', 'ownActivityArrived', reply
        new KDNotificationView
          type     : 'growl'
          cssClass : 'mini'
          title    : 'Message posted!'
          duration : 2000
        @statusField.setValue ""
        @statusField.setPlaceHolder reply.body
      else
        new KDNotificationView type : "mini", title : "There was an error, try again later!"
