class KDFormViewWithFields extends KDFormView

  sanitizeOptions = (options)->
    for key,option of options
      option.title or= key
      option.key     = key
      option

  constructor:->

    super

    @setClass "with-fields"

    @inputs  = {}
    @fields  = {}
    @buttons = {}

    {fields,buttons} = @getOptions()

    @createFields sanitizeOptions  fields  if fields
    @createButtons sanitizeOptions buttons if buttons

  createFields:(fields)->
    @addSubView @createField fieldData for fieldData in fields

  createButtons:(buttons)->
    @addSubView @buttonField = new KDView cssClass : "formline button-field clearfix"
    buttons.forEach (buttonOptions)=>
      @buttonField.addSubView button = @createButton buttonOptions
      @buttons[buttonOptions.key] = button

  createField:(fieldData, field)->
    {itemClass, title} = fieldData
    itemClass          or= KDInputView
    fieldData.cssClass or= ""
    fieldData.name     or= title
    field or= new KDView cssClass : "formline #{fieldData.name} #{fieldData.cssClass}"
    field.addSubView label = fieldData.label = @createLabel(fieldData) if fieldData.label
    field.addSubView inputWrapper = new KDCustomHTMLView cssClass : "input-wrapper"
    inputWrapper.addSubView input = @createInput itemClass, fieldData
    if fieldData.hint
      inputWrapper.addSubView hint  = new KDCustomHTMLView
        partial  : fieldData.hint
        tagName  : "cite"
        cssClass : "hint"
    @fields[title] = field
    if fieldData.nextElement
      for key, next of fieldData.nextElement
        next.title or= key
        @createField next, inputWrapper

    if fieldData.nextElementFlat
      for key, next of fieldData.nextElementFlat
        next.title or= key
        @createField next, field


    return field

  createLabel:(data)->
    return new KDLabelView
      title    : data.label
      cssClass : @utils.slugify data.label

  createInput:(itemClass, options)->
    {data} = options
    delete options.data  if data
    @inputs[options.title] = input = new itemClass options, data
    return input

  createButton:(options)->
    options.itemClass or= KDButtonView
    o = $.extend {}, options
    delete o.itemClass
    button = new options.itemClass o


# new KDFormViewWithFields
#   title               : "My Form Title"
#   buttons             :
#     Add               :
#       title           : "Add"
#       style           : "modal-clean-gray"
#       type            : "submit"
#     Delete            :
#       title           : "Delete"
#       style           : "modal-clean-red"
#       callback        : -> log "delete"
#     Reset             :
#       title           : "Reset"
#       style           : "modal-clean-red"
#       type            : "reset"
#   callback            : (formOutput)->
#     log formOutput,"  ::::::"
#   fields              :
#     Title             :
#       label           : "Title:"
#       type            : "text"
#       name            : "title"
#       placeholder     : "give a name to your topic..."
#       validate        :
#         rules         :
#           required    : yes
#         messages      :
#           required    : "topic name is required!"
#     Zikkko            :
#       label           : "Zikkko"
#       type            : "textarea"
#       name            : "zikko"
#       placeholder     : "give something else to your topic..."
#       nextElement     :
#         lulu          :
#           type        : "text"
#           name        : "lulu"
#           placeholder : "lulu..."
