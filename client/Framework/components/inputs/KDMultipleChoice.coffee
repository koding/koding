
#####
# KDMultipleChoice ~ GG
#####

class KDMultipleChoice extends KDInputView

  # Usage:

  # @multipleChoice = new KDMultipleChoice
  #   title        : "Choose one:"
  #   labels       : ['yes', 'no', 'one more', 'fourth one']
  #   defaultValue : ['one more', 'yes', 'no']
  #   multiple     : yes
  #   callback     : (state)=>
  #     state

  constructor:(options = {}, data)->

    options.size         or= "small"             # a String tiny/small/big
    options.labels       or= ["ON", "OFF"]       # supports multiple labels as string
    options.multiple     ?= no
    options.defaultValue or= if options.multiple then options.labels[0]

    if not options.multiple and Array.isArray options.defaultValue
      options.defaultValue = options.defaultValue[0]

    super options, data

    @setClass options.size
    @setPartial "<input class='hidden no-kdinput' name='#{@getName()}'/>"

    @oldValue     = null
    @currentValue = [] if options.multiple

  setDomElement:(cssClass)->
    {labels, name} = @getOptions()
    @inputName = name

    labelItems = ""
    for label in labels
      clsName     = "multiple-choice-#{label}"
      labelItems += "<a href='#' name='#{label}' class='#{clsName}' title='Select #{label}'>#{label}</a>"

    @domElement = $ """
      <div class='kdinput on-off multiple-choice #{cssClass}'>
        #{labelItems}
      </div> """

  getDefaultValue:-> @getOptions().defaultValue

  getValue:-> @currentValue

  setCurrent = (view, label)=>
    if label in view.currentValue
      view.$("a[name$='#{label}']").removeClass('active')
      view.currentValue.splice(view.currentValue.indexOf(label), 1)
    else
      view.$("a[name$='#{label}']").addClass('active')
      view.currentValue.push label

  setValue:(label, wCallback = yes)->
    {multiple} = do @getOptions

    if multiple
      # FIXME later with .first
      @oldValue = [obj for obj in @currentValue]?.first

      if Array.isArray label
        [setCurrent(@, val) for val in label]
      else
        setCurrent @, label

      do @switchStateChanged if wCallback
    else
      @$("a").removeClass('active')
      @$("a[name$='#{label}']").addClass('active')

      @oldValue     = @currentValue
      @currentValue = label

      if @currentValue isnt @oldValue and wCallback
        do @switchStateChanged

  switchStateChanged:->
    @getCallback().call @, @getValue() if @getCallback()?

  fallBackToOldState:->
    {multiple} = do @getOptions

    if multiple
      @currentValue = []
      @$("a").removeClass('active')

    @setValue @oldValue, no

  mouseDown:(event)->
    if $(event.target).is('a')
      @setValue event.target.name
