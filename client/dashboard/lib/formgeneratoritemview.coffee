kd = require 'kd'
KDInputRadioGroup = kd.InputRadioGroup
KDListItemView = kd.ListItemView
KDOnOffSwitch = kd.OnOffSwitch
KDSelectBox = kd.SelectBox
KDView = kd.View
CustomLinkView = require 'app/customlinkview'


module.exports = class FormGeneratorItemView extends KDListItemView
  constructor:(options,data)->
    super options,data

    {type,title,key,defaultValue,options} = @getData()

    @type = new KDView
      cssClass    : 'type'
      partial     : switch type
        when 'text'     then 'Text Field'
        when 'select'   then 'Select Box'
        when 'checkbox' then 'On-Off Switch'
        when 'radio'    then 'Radio Buttons'
        when 'textarea' then 'Textarea'
        else 'Other'
      tooltip     :
        title     : type
        placement : 'top'
        direction : 'center'

    @title = new KDView
      cssClass    : 'title'
      partial     : title
      tooltip     :
        title     : title
        placement : 'top'
        direction : 'center'

    @key = new KDView
      cssClass    : 'key'
      partial     : key
      tooltip     :
        title     : key
        placement : 'top'
        direction : 'center'

    switch type
      when 'text', 'textarea'
        @defaultValue = new KDView
          cssClass    : "default #{type}"
          partial     : defaultValue or '<span>none</span>'
          tooltip     :
            title     : defaultValue
            placement : 'top'
            direction : 'center'

      when 'select'
        @defaultValue   = new KDSelectBox
          cssClass      : 'default'
          selectOptions : options or []
          defaultValue  : defaultValue

      when 'radio'
        @defaultValue   = new KDInputRadioGroup
          radios        : options
          name          : 'radios_' + kd.utils.getRandomNumber()
          cssClass      : 'default'
        @defaultValue.setDefaultValue defaultValue

      when 'checkbox'
        @defaultValue   = new KDOnOffSwitch
          size         : "tiny"
          cssClass      : 'default'
          defaultValue  : defaultValue

    @removeButton = new CustomLinkView
      tagName     : 'span'
      cssClass    : 'clean-gray remove-button'
      title       : 'Remove'
      click       :=>
        @getDelegate().emit 'RemoveButtonClicked', @

  viewAppended:->
    @setClass "form-item"

    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{> @type}}
    {{> @title}}
    {{> @key}}
    <div class="default">{{> @defaultValue}}</div>
    {{> @removeButton}}
    """



