class ProfileTextGroup extends LinkGroup

  constructor:(options = {}, data)->

    options.tagName       or= 'span'
    options.cssClass      or= 'link-group'
    options.itemClass  or= ProfileTextView

    super options

  click: -> yes
