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
    KD.showNewKodingModal()