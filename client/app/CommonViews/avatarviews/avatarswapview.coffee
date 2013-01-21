class AvatarSwapView extends AvatarView

  constructor:(options = {},data)->
    
    options.cssClass or= "profile-avatar"

    super

  click:-> yes

  setFileUpload:->
    
    if @swapAvatarView and @swapAvatarView.isInDom()
      @swapAvatarView.destroy()
    else
      @swapAvatarView = swapAvatarView = new KDFileUploadView
        limit        : 1
        preview      : "thumbs"
        extensions   : ["png","jpg","jpeg","gif"]
        fileMaxSize  : 500
        totalMaxSize : 700
        title        : "Drop a picture here!"
      @addSubView @swapAvatarView
