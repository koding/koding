kd              = require 'kd'
JView           = require 'app/jview'
KDListItemView  = kd.ListItemView
KDCheckBox      = kd.CheckBox
KDLabelView     = kd.LabelView

module.exports = class SelectableItemView extends KDListItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = 'similar-item'
    super options, data

    { name } = @data

    @label = new KDLabelView
      title : name
    @switcher = new KDCheckBox
      defaultValue : false
      disabled     : false
      label        : @label


  pistachio: ->
    """
      {{> @switcher }}
      {{> @label }}
    """
