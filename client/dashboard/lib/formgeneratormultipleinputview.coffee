kd = require 'kd'
KDInputView = kd.InputView
KDListItemView = kd.ListItemView
KDListViewController = kd.ListViewController
FormGeneratorMultipleInputItemView = require './formgeneratormultipleinputitemview'
JView = require 'app/jview'
CustomLinkView = require 'app/customlinkview'
Encoder = require 'htmlencode'


module.exports = class FormGeneratorMultipleInputView extends JView
  constructor:(options,data)->
    super options,data

    {type,title} = @getOptions()

    @listController = new KDListViewController
      itemClass     : FormGeneratorMultipleInputItemView
      noItemView    : new KDListItemView
        cssClass    : 'default-item'
        partial     : "Please add #{title} options"

    @listWrapper      = @listController.getView()
    @listWrapper.setClass "form-builder-#{type}"

    @inputTitle = new KDInputView
      cssClass  : 'title'

    @addButton  = new CustomLinkView
      cssClass  : 'add-button'
      tagName   : 'span'
      title     : 'Add option'
      click     : =>
        @listController.addItem
          title : Encoder.XSSEncode @inputTitle.getValue()
          value : kd.utils.slugify(@inputTitle.getValue()).replace(/-/g,'_')

        @emit 'InputChanged', {
          type
          value:@getValue()
        }

        @inputTitle.setValue ''

    @listController.listView.on 'RemoveButtonClicked', (instance)=>
      @listController.removeItem instance,{}
      @emit 'InputChanged', {
        type
        value:@getValue()
      }

  getValue:->
    data = []
    for item in @listController.listView.items
      data.push
        title : item.getData().title
        value : kd.utils.slugify(item.getData().title).replace(/-/g,'_')
    data

  pistachio:->
    """
    <h3>#{@getOptions().title} items</h3>
    {{> @listWrapper}}
    {{> @inputTitle}}
    {{> @addButton}}
    """



