class KDFormViewWithFields extends KDFormView
  constructor:->
    super
    @setClass "with-fields"
    @inputs  = {}
    @fields  = {}
    @buttons = {}
    {fields,buttons} = @getOptions()
    @createFields @sanitizeOptions fields
    @createButtons @sanitizeOptions buttons
    # log "@inputs:",@inputs,"@fields:",@fields

  sanitizeOptions:(options)->
    for key,option of options
      option.title = key unless option.title
      option
  
  createFields:(fields)->
    @addSubView @createField fieldData for fieldData in fields

  createButtons:(buttons)->
    @addSubView @buttonField = new KDView cssClass : "formline button-field clearfix"
    # for buttonOptions in buttons
    buttons.forEach (buttonOptions)=>
      {callback} = buttonOptions
      oldCallback = callback or noop
      @buttonField.addSubView button = @createButton buttonOptions
      @buttons[buttonOptions.title] = button
      newCallback = =>
        @addCustomData '__clickedButton',buttonOptions.title
        oldCallback.call button, button, @getData()
      button.setCallback newCallback

      
  createField:(data,field)->
    {itemClass,title} = data
    itemClass or= KDInputView
    field or= new KDView cssClass : "formline #{data.name}"
    field.addSubView label = data.label = @createLabel(data) if data.label
    field.addSubView input = @createInput itemClass,data
    @fields[title] = field
    if data.nextElement
      for key,next of data.nextElement
        next.title = key
        @createField next,field
    
    return field
  
  createLabel:(data)->
    return new KDLabelView(title : data.label)
  
  createInput:(itemClass,options)->
    @inputs[options.title] = input = new itemClass options
    return input

  createButton:(options)->
    return button = new KDButtonView options


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
#       callback        : ()-> log "delete"
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
    