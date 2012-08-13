class AvatarStaticView extends AvatarView

  constructor:(options = {}, data)->

    options.tagName or= 'span'

    super

  click:-> yes