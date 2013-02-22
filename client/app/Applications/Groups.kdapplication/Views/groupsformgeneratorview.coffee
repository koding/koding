class GroupsFormGeneratorView extends JView
  constructor:(options,data)->
    super options,data

    @setClass 'form-generator'

    @listController = new KDListViewController
      itemClass     : GroupsFormGeneratorItemView
    @listWrapper    = @listController.getView()

    @loader         = new KDLoaderView
      cssClass      : 'loader'
    @loaderText     = new KDView
      partial       : 'Loading Form Generator…'
      cssClass      : ' loader-text'

    @inputTitle = new KDInputView
      name : 'title'

    @inputKey = new KDInputView
      name : 'key'
    @inputDefault = new KDInputView
      name : 'defaultValue'


    @addButton      = new KDButtonView
      title         : 'Add field'
      # icon          : yes
      # iconClass     : 'plus'
      style         : 'clean-gray'
      callback      : =>
        @listController.addItem
          title     : @inputTitle.getValue()
          key       : @inputKey.getValue()
          defaultValue : @inputDefault.getValue()
  pistachio:->
    """
      <h3>Additional information</h3>
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
      partial : defaultValue

  viewAppended:->
    @setClass "form-item"

    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{> @title}}
    {{> @key}}
    {{> @defaultValue}}
    """