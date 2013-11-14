class AutoCompleteAvatarView extends AvatarView

  constructor:(options = {},data)->
    
    options.size   or=
      width          : 20
      height         : 20
    options.cssClass = "avatarview #{options.cssClass}"
    
    super
