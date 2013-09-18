class KDFormViewWithFields extends KDFormView

  sanitizeOptions = (options)->
    for own key,option of options
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
    @addSubView @createField fieldOptions for fieldOptions in fields

  createButtons:(buttons)->
    @addSubView @buttonField = new KDView cssClass : "formline button-field clearfix"
    buttons.forEach (buttonOptions)=>
      @buttonField.addSubView button = @createButton buttonOptions
      @buttons[buttonOptions.key] = button

  createField:(fieldOptions, field, isNextElement = no)->
    {itemClass, title, itemData} = fieldOptions
    itemClass             or= KDInputView
    fieldOptions.cssClass or= ""
    fieldOptions.name     or= title
    field or= new KDView cssClass : "formline #{KD.utils.slugify fieldOptions.name} #{fieldOptions.cssClass}"
    field.addSubView label = fieldOptions.label = @createLabel(fieldOptions) if fieldOptions.label

    unless isNextElement
      field.addSubView inputWrapper = new KDCustomHTMLView cssClass : "input-wrapper"
      inputWrapper.addSubView input = @createInput itemClass, fieldOptions
    else
      field.addSubView input = @createInput itemClass, fieldOptions

    if fieldOptions.hint
      inputWrapper.addSubView hint  = new KDCustomHTMLView
        partial  : fieldOptions.hint
        tagName  : "cite"
        cssClass : "hint"
    @fields[title] = field
    if fieldOptions.nextElement
      for own key, next of fieldOptions.nextElement
        next.title or= key
        @createField next, (inputWrapper or field), yes

    if fieldOptions.nextElementFlat
      for own key, next of fieldOptions.nextElementFlat
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
