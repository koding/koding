kd = require 'kd'

module.exports = class SlackUserItem extends kd.ListItemView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'slack-user-item', options.cssClass

    super options, data


  emitItemValueChanged: ->

    list = @getDelegate()
    list.emit 'ItemValueChanged'


  viewAppended: ->

    { real_name, name, profile, status } = @getData()

    status = switch status
      when 'pending'  then 'already invited'
      when 'accepted' then 'already member'
      else null

    @addSubView @checkBox = new kd.CustomCheckBox
      defaultValue : on
      click        : => @emitItemValueChanged()

    if status
      @checkBox.input.makeDisabled()
      partial = "<img src='#{profile.image_24}'/> @#{name} <cite>#{real_name}</cite> <span >#{status}</span>"
    else
      partial = "<img src='#{profile.image_24}'/> @#{name} <cite>#{real_name}</cite>"

    @addSubView new kd.CustomHTMLView
      tagName  : 'a'
      href     : '#'
      cssClass : 'name'
      partial  : partial
      click    : =>
        return  if status
        @checkBox.setValue not @checkBox.getValue()
        @emitItemValueChanged()
