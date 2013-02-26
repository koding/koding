
class FormGeneratorView extends JView
  constructor:(options,data)->
    super options,data

    @setClass 'form-generator'

    @listController = new KDListViewController
      itemClass     : FormGeneratorItemView

    @listWrapper    = @listController.getView()
    @listWrapper.setClass 'form-builder'

    @loader         = new KDLoaderView
      cssClass      : 'loader'
    @loaderText     = new KDView
      partial       : 'Loading Form Generator…'
      cssClass      : ' loader-text'

    @inputTitle = new KDInputView
      name : 'title'
      placeholder : 'Field title, e.g. "Student ID"'
      keyup : (event)=>
        @inputKey.setValue @utils.slugify(@inputTitle.getValue()).replace(/-/g,'_')
      validate      :
        rules       :
          required  : yes
        messages    :
          required  : "A title is required!"

    @inputKey = new KDInputView
      name : 'key'
      placeholder : 'Field key, e.g. "student_id"'

    @inputDefault = new KDInputView
      name : 'defaultValue'
      placeholder : 'Default value'

    @inputDefaultSelect = new KDSelectBox
      name : 'defaultValueSelect'

    @inputDefaultSelect.hide()

    @inputType      = new KDSelectBox
      name          : 'type'
      cssClass      : 'type-select'
      selectOptions : [
        {title:'Add Text Field',value :'text'},
        {title:'Add large Text Field',value :'textarea'},
        {title:'Add Dropdown',value:'select'},
        {title:'Add Checkbox',value:'checkbox'},
        {title:'Add Multiple-Choice Field',value:'radio'}

      ]
      change:=>

        switch @inputType.getValue()
          when 'select'
            @inputSelectFields.show()
            @inputDefaultSelect.show()
            @inputDefault.hide()
          else
            @inputSelectFields.hide()
            @inputDefaultSelect.hide()
            @inputDefault.show()

    @inputSelectFields = new FormGeneratorSelectView
      cssClass : 'select-fields'

    @inputSelectFields.hide()

    @inputSelectFields.on 'SelectChanged', (selectData)=>
      @inputDefaultSelect.removeSelectOptions()
      @inputDefaultSelect.setSelectOptions selectData
      @inputDefaultSelect.setValue selectData[0]

    @addButton      = new CustomLinkView
      tagName       : 'span'
      title         : 'Add field'
      style         : 'clean-gray'
      cssClass      : 'add-button'
      click         : =>

        key = @inputKey.getValue()
        newItem = key isnt ''
        for item in @listController.listView.items
          if item.getData().key is key
            newItem = false

        if newItem
          @listController.addItem
            title       : Encoder.XSSEncode @inputTitle.getValue()
            key         : Encoder.XSSEncode @inputKey.getValue()
            defaultValue: switch @inputType.getValue()
              when 'text' then Encoder.XSSEncode @inputDefault.getValue()
              when 'select' then @inputDefaultSelect.getValue()
              else Encoder.XSSEncode @inputDefault.getValue()
            type        : @inputType.getValue()
            options     : @inputSelectFields.getValue()

          @inputTitle.setValue ''
          @inputKey.setValue ''
          @inputDefault.setValue ''

          @inputSelectFields.listController.removeAllItems()
          @inputDefaultSelect.removeSelectOptions()
          @inputDefaultSelect.setValue null

        else
          new KDNotificationView
            title : if key is '' then 'Please enter a key' else 'Duplicate key'

    @saveButton = new KDButtonView
      title     : 'Save fields'
      cssClass  : 'clean-gray'
      loader    :
        diameter: 12
        color   : '#444'
      callback  :=>

          newFields = []
          for item in @listController.listView.items

            {type,title,key,defaultValue,options} = item.getData()

            newFields.push
              key           : Encoder.XSSEncode key
              type          : type
              title         : Encoder.XSSEncode title
              defaultValue  : Encoder.XSSEncode defaultValue
              options       : options if options


          @getDelegate().emit 'MembershipPolicyChanged', {fields : newFields}
          @getDelegate().once 'MembershipPolicyChangeSaved', =>
            @saveButton.hideLoader()

    @listController.listView.on 'RemoveButtonClicked', (instance)=>
      @listController.removeItem instance,{}

    policy = @getData()
    if policy.fields
      for field in policy.fields
        @listController.addItem
          title        : field.title or ''
          defaultValue : field.defaultValue or ''
          key          : field.key
          type         : field.type or 'text'
          options      : field.options

  pistachio:->
    """
    <div class="wrapper">
      <div class="add-header">
        <div class="add-type">Field type</div>
        <div class="add-title">Title</div>
        <div class="add-key">Key</div>
        <div class="add-default">Default value</div>
      </div>

      {{> @listWrapper}}

      <div class="add-inputs">
        <div class='add-input'>{{> @inputType}}</div>
        <div class='add-input'>{{> @inputTitle}}</div>
        <div class='add-input'>{{> @inputKey}}</div>
        <div class='add-input'>{{> @inputDefault}}{{> @inputDefaultSelect}}</div>
        <div class='add-input button'>{{> @addButton}}</div>
        <div class='add-input select'>{{> @inputSelectFields}}</div>
      </div>
    </div>
    {{> @saveButton}}
    """

class FormGeneratorSelectView extends JView
  constructor:(options,data)->
    super options,data
    @listController   = new KDListViewController
      itemClass       : FormGeneratorSelectItemView
      showDefaultItem : yes
      defaultItem     :
        options       :
          cssClass    : 'default-item'
          partial     : 'Please add Dropdown options'

    @listWrapper      = @listController.getView()
    @listWrapper.setClass 'form-builder-select'

    @inputTitle = new KDInputView
      cssClass  : 'title'

    @addButton  = new CustomLinkView
      cssClass  : 'add-button'
      tagName   : 'span'
      title     : 'Add option'
      click     : =>
        @listController.addItem
          title : Encoder.XSSEncode @inputTitle.getValue()
          value : @utils.slugify(@inputTitle.getValue()).replace(/-/g,'_')

        @emit 'SelectChanged', @getValue()
        @inputTitle.setValue ''

    @listController.listView.on 'RemoveButtonClicked', (instance)=>
      @listController.removeItem instance,{}
      @emit 'SelectChanged', @getValue()

  getValue:->
    data = []
    for item in @listController.listView.items
      data.push
        title : item.getData().title
        value : @utils.slugify(item.getData().title).replace(/-/g,'_')
    data

  pistachio:->
    """
    <h3>Dropdown items</h3>
    {{> @listWrapper}}
    {{> @inputTitle}}
    {{> @addButton}}
    """

class FormGeneratorSelectItemView extends KDListItemView
  constructor:(options,data)->
    super options,data

    @setClass 'select-item'

    @optionTitle  = new KDView
      cssClass    : 'title'
      partial     : @getData().title+" <span class='value'>(#{@getData().value})</span>"

    @removeButton = new CustomLinkView
      tagName     : 'span'
      cssClass    : 'clean-gray remove-button'
      title       : 'Remove'
      click       :=>
        @getDelegate().emit 'RemoveButtonClicked', @

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{> @optionTitle}}
    {{> @removeButton}}
    """



class FormGeneratorItemView extends KDListItemView
  constructor:(options,data)->
    super options,data

    {type,title,key,defaultValue,options} = @getData()

    @type = new KDView
      cssClass    : 'type'
      partial     : switch type
        when 'text' then 'Text'
        when 'select' then 'Dropdown'
        else 'Other'
      tooltip     :
        title     : type
        placement : 'top'
        direction : 'center'
        showOnlyWhenOverflowing : yes

    @title = new KDView
      cssClass    : 'title'
      partial     : title
      tooltip     :
        title     : title
        placement : 'top'
        direction : 'center'
        showOnlyWhenOverflowing : yes

    @key = new KDView
      cssClass    : 'key'
      partial     : key
      tooltip     :
        title     : key
        placement : 'top'
        direction : 'center'
        showOnlyWhenOverflowing : yes

    switch type
      when 'text'
        @defaultValue = new KDView
          cssClass    : 'default'
          partial     : defaultValue or '<span>none</span>'
          tooltip     :
            title     : defaultValue
            placement : 'top'
            direction : 'center'
            showOnlyWhenOverflowing : yes

      when 'select'
        @defaultValue   = new KDSelectBox
          cssClass      : 'default'
          selectOptions : options or []
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


class GroupsFormGeneratorView extends FormGeneratorView
