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


    @listController.listView.on 'RemoveButtonClicked', (instance)=>
      @listController.removeItem instance,{}

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
    """

class GroupsFormGeneratorItemView extends KDListItemView
  constructor:(options,data)->
    super options,data

    {title,key,defaultValue} = @getData()

    @title = new KDView
      cssClass : 'title'
      partial : title
    @key = new KDView
      cssClass : 'key'
      partial : key
    @defaultValue = new KDView
      cssClass : 'default'
      partial : defaultValue or '<span>none</span>'
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