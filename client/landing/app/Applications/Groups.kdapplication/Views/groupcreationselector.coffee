class GroupCreationSelector extends KDInputRadioGroup

  setDomElement:()->
    options = @getOptions()
    @domElement = $ "<fieldset class='#{@utils.curryCssClass 'radiogroup kdinput', options.cssClass}'></fieldset>"

    for radioOptions, i in options.radios
      radioOptions.visible   ?= yes
      radioOptions.callback or= ->

      bg      = $ "<figure/>",
        class : "kd-#{@getType()}-holder #{options.cssClassPrefix}#{@utils.slugify radioOptions.value}"
      div     = $ "<div/>",

      radio   = $ "<input/>",
        type   : @getType()
        name   : options.name
        value  : radioOptions.value
        class  : "no-kdinput hidden"
        id     : "#{@getId()}_#{@getType()}_#{i}"
        change : radioOptions.callback

      label   = $ "<label/>",
        for   : "#{@getId()}_#{@getType()}_#{i}"
        html  : radioOptions.title
        class : options.cssClassPrefix + @utils.slugify radioOptions.value

      icon    = $ "<span/>",
        class : "icon"

      bg.append  div
      div.append radio
      div.append icon
      div.append label
      @domElement.append bg

      if not radioOptions.visible
        div.hide()
    @domElement
