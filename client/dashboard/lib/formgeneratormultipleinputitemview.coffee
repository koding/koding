kd = require 'kd'
KDListItemView = kd.ListItemView
KDView = kd.View
CustomLinkView = require 'app/customlinkview'


module.exports = class FormGeneratorMultipleInputItemView extends KDListItemView
  constructor:(options,data)->
    super options,data

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

