# avatar popup box Status Update Form
class AvatarPopupShareStatus extends AvatarPopup

  viewAppended:->
    super()

    @loader = new KDLoaderView
      cssClass      : "avatar-popup-status-loader"
      size          :
        width       : 30
      loaderOptions :
        color       : "#ff9200"
        shape       : "spiral"
        diameter    : 30
        density     : 30
        range       : 0.4
        speed       : 1
        FPS         : 24

    @avatarPopupContent.addSubView @loader

    name = KD.utils.getFullnameFromAccount KD.whoami(), yes
    @avatarPopupContent.addSubView @statusField = new KDHitEnterInputView
      type          : "textarea"
      validate      :
        rules       :
          required  : yes
      placeholder   : "What's new, #{name}?"
      callback      : (status)=> @updateStatus status

  updateStatus:(status)->

    @loader.show()
    console.error "not impplemented feature"
    # KD.remote.api.JNewStatusUpdate.create body : status, (err,reply)=>
    #   unless err
    #     new KDNotificationView
    #       type     : 'growl'
    #       cssClass : 'mini'
    #       title    : 'Message posted!'
    #       duration : 2000
    #     @statusField.setValue ""

    #     @loader.hide()
    #     # @statusField.setPlaceholder reply.body
    #     @hide()

    #   else
    #     new KDNotificationView type : "mini", title : "There was an error, try again later!"
    #     @loader.hide()
    #     @hide()
