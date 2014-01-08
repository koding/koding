class KeyboardHelperView extends KDListView
  constructor:(options,data)->
    options = $.extend
      title        : ""
      itemClass : KeySetView
    ,options
    super options,data

  viewAppended:->
    @setPartial "<li class='title'>#{@getOptions().title}</li>" if @getOptions().title
    super

  setDomElement:(cssClass)->
    @domElement = $ "<ul class='kdview keyboard-helper #{cssClass}'></ul>"


class KeySetView extends KDListItemView
  constructor:->
    super

  setDomElement:(cssClass)->
    @domElement = $ "<li class='kdview keyset clearfix #{cssClass}'></li>"

  viewAppended:->
    {keySet,title} = @getData()
    keyGroups = @getKeyGroups keySet

    for keyGroup,i in keyGroups
      @createKeyGroup keyGroup
      @setPartial "<cite>+</cite>" if i isnt keyGroups.length - 1

    @setPartial "<h6>#{title}</h6>"

  getKeyGroups:(keySet)->
    keyGroups = keySet.split("+")
    groups = for group,i in keyGroups
      group = if /,/.test group then group.split(",") else [group]

  createKeyGroup:(keyGroup)->
    for key in keyGroup
      @addSubView new KeyView null,key

class KeyView extends KDCustomHTMLView
  sanitizePrinting = (text) ->
    if /Macintosh/.test navigator.userAgent
      metaKey   = "⌘"
      optionKey = "option"
    else
      metaKey   = "ctrl"
      optionKey = "alt"

    switch text
      when "cmd"    then metaKey
      when "option" then optionKey
      when "up"     then "↑"
      when "down"   then "↓"
      when "left"   then "←"
      when "right"  then "→"
      else
        text

  constructor:(options,data)->
    options = $.extend
      tagName  : "span"
      cssClass : "keyview"
    ,options
    super options,data

  viewAppended:->
    text     = @getData()
    printing = sanitizePrinting text
    @setPartial printing
    @setClass "key-#{text}"
    @setClass "large" if printing.length > 1




class KeyboardHelperModalView extends KDModalView
  constructor:(options,data)->
    options = $.extend
      overlay   : no            # a Boolean
      height    : 300           # a Number for pixel value or a String e.g. "100px" or "20%"
      width     : 400           # a Number for pixel value or a String e.g. "100px" or "20%"
      title     : null          # a String of text or HTML
      content   : null          # a String of text or HTML
      cssClass  : ""            # a String
      buttons   : null          # an Object of button options
      fx        : no            # a Boolean
      view      : null          # a KDView instance
      draggable : null
      # TO BE IMPLEMENTED
      resizable : no            # a Boolean
    ,options

    @putOverlay options.overlay if options.overlay

    super options,data

    @setClass "fx"                                if options.fx
    @setContent options.content                   if options.content

    @appendToDomBody()

    @setModalWidth options.width
    @setModalHeight options.height                if options.height

    # TODO: it is now displayed with setPositions method fix that and make .display work
    @display()
    @setPositions()

    # KD.getSingleton("windowController").setKeyView @ ---------> disabled because KDEnterinputView was not working in KDmodal
    $(window).on "keydown.modal",(e)=>
      @destroy() if e.which is 27

  setDomElement:(cssClass)->
    @domElement = $ """
                    <div class='kdmodal keyboard-helper #{cssClass}'>
                      <span class='close-icon'></span>
                    </div>
                    """

  click:(e)->
    @destroy() if $(e.target).is(".close-icon")

  setTitle:(title)->
    @getDomElement().find(".kdmodal-title").append("<span class='title'>#{title}</span>")
    @modalTitle = title
