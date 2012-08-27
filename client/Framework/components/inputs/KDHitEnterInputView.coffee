###
todo:

  - on enter should validation fire by default??? Sinan - 6/6/2012

###


class KDHitEnterInputView extends KDInputView
  constructor:(options,data)->
    options = $.extend
      type           : "textarea"
      button         : null
      showButton     : no
      label          : null
      placeholder    : ""
      callback       : null
      togglerPartials: ["quick update disabled","quick update enabled"]
    ,options
    super options,data
    @setClass "hitenterview"

    @button = @getOptions().button ? null
    @enableEnterKey()
    @setToggler() if options.label?
    @disableEnterKey() if @getOptions().showButton

    @on "ValidationPassed", =>
      @blur()
      @getOptions().callback?.call @,@getValue()

  enableEnterKey:->
    @setClass "active"
    @hideButton() if @button
    @inputEnterToggler.$().html(@getOptions().togglerPartials[1]) if @inputEnterToggler?
    @enterKeyEnabled = yes

  disableEnterKey:->
    @unsetClass "active"
    @showButton() if @button
    @inputEnterToggler.$().html(@getOptions().togglerPartials[0]) if @inputEnterToggler?
    @enterKeyEnabled = no

  setToggler:->
    o = @getOptions()
    @inputEnterToggler = new KDCustomHTMLView
      tagName : "a"
      cssClass: "hitenterview-toggle"
      partial : if o.showButton then o.togglerPartials[0] else o.togglerPartials[1]

    @inputLabel.addSubView @inputEnterToggler

    @listenTo
      KDEventTypes : "click"
      listenedToInstance : @inputEnterToggler
      callback : @toggleEnterKey

  # click:-> no

  hideButton:-> @button.hide()

  showButton:-> @button.show()

  toggleEnterKey:->
    if @enterKeyEnabled then @disableEnterKey() else @enableEnterKey()

  keyDown:(event)->
    if event.which is 13 and (event.altKey or event.shiftKey) isnt true and @enterKeyEnabled
      @handleEvent type : "EnterPerformed"
      @validate()
      no