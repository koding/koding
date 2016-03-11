kd = require 'kd'

module.exports = class SlackUserItem extends kd.ListItemView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'slack-user-item', options.cssClass

    super options, data


  emitItemValueChanged: ->

    list = @getDelegate()
    list.emit 'ItemValueChanged'


  viewAppended: ->

    { real_name, name, profile } = @getData()

    @addSubView @checkBox = new kd.CustomCheckBox
      defaultValue : on
      click        : => @emitItemValueChanged()

    @addSubView new kd.CustomHTMLView
      tagName  : 'a'
      href     : '#'
      cssClass : 'name'
      partial  : "<img src='#{profile.image_24}'/> @#{name} <cite>#{real_name}</cite>"
      click    : =>
        @checkBox.setValue not @checkBox.getValue()
        @emitItemValueChanged()