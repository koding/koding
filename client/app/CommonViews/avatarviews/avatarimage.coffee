class AvatarImage extends AvatarView

  constructor:(options = {},data)->

    options.tagName  or= "img"
    options.cssClass or= ""
    options.size     or=
      width            : 50
      height           : 50
    options.cssClass   = KD.utils.curry "avatarimage", options.cssClass

    super options, data

  setAvatar:(uri)->
    if @bgImg isnt uri
      {width, height} = @getOptions().size
      @setAttribute "src", uri
      @setAttribute "width", width
      @setAttribute "height", height
      @bgImg = uri

  pistachio:-> ''
