class GroupsFormGeneratorView extends JView
  constructor:(options,data)->
    super options,data

    @setClass 'form-generator'

    @listController = new KDListViewController
      itemClass     : GroupsFormGeneratorItemView

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

    @addButton      = new CustomLinkView
      tagName : 'span'
      title         : 'Add field'
      # icon          : yes
      # iconClass     : 'plus'
      style         : 'clean-gray'
      click      : =>
        key = @inputKey.getValue()
        newItem = key isnt ''
        for item in @listController.listView.items
          if item.getData().key is key
            newItem = false

        if newItem
          @listController.addItem
            title     : Encoder.XSSEncode @inputTitle.getValue()
            key       : Encoder.XSSEncode @inputKey.getValue()
            defaultValue : Encoder.XSSEncode @inputDefault.getValue()
          @inputTitle.setValue ''
          @inputKey.setValue ''
          @inputDefault.setValue ''
        else
          new KDNotificationView
            title : if key is '' then 'Please enter a key' else 'Duplicate key'

    @saveButton = new KDButtonView
      title : 'Save fields'
      cssClass : 'clean-gray'
      loader :
        diameter : 12
        color : '#444'
      callback :=>
        unless @listController.listView.items.length is 0
          newFields = {}
          for item in @listController.listView.items
            {title,key,defaultValue} = item.getData()
            key = Encoder.XSSEncode key
            newFields[key]={}
            newFields[key].title = Encoder.XSSEncode title
            newFields[key].defaultValue = Encoder.XSSEncode defaultValue

          @getDelegate().emit 'MembershipPolicyChanged', {fields : newFields}
          @getDelegate().once 'MembershipPolicyChangeSaved', =>
            @saveButton.hideLoader()
        else
          new KDNotificationView
            title : 'Your fields are empty. There is nothing to be saved.'
          @saveButton.hideLoader()

    @listController.listView.on 'RemoveButtonClicked', (instance)=>
      @listController.removeItem instance,{}

    policy = @getData()
    if policy.fields
      for field of policy.fields
        @listController.addItem
          title        : policy.fields[field].title
          defaultValue : policy.fields[field].defaultValue
          key          : field


  pistachio:->
    """
      <div class="add-header">
        <div class="add-title">Title</div>
        <div class="add-key">Key</div>
        <div class="add-default">Default value</div>
      </div>
      {{> @listWrapper}}
    <div class="add-inputs">
      {{> @inputTitle}}
      {{> @inputKey}}
      {{> @inputDefault}}
      {{> @addButton}}
    </div>
    {{> @saveButton}}
    """

class GroupsFormGeneratorItemView extends KDListItemView
  constructor:(options,data)->
    super options,data

    {title,key,defaultValue} = @getData()

    @title = new KDView
      cssClass : 'title'
      partial : title
      tooltip :
        title : title
        placement : 'top'
        direction : 'center'
        showOnlyWhenOverflowing : yes
    @key = new KDView
      cssClass : 'key'
      partial : key
      tooltip :
        title : key
        placement : 'top'
        direction : 'center'
        showOnlyWhenOverflowing : yes
    @defaultValue = new KDView
      cssClass : 'default'
      partial : defaultValue or '<span>none</span>'
      tooltip :
        title : defaultValue
        placement : 'top'
        direction : 'center'
        showOnlyWhenOverflowing : yes
    @removeButton = new CustomLinkView
      tagName : 'span'
      cssClass : 'clean-gray remove-button'
      title : 'Remove'
      click :=>
        @getDelegate().emit 'RemoveButtonClicked', @

  viewAppended:->
    @setClass "form-item"

    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{> @title}}
    {{> @key}}
    {{> @defaultValue}}
    {{> @removeButton}}
    """