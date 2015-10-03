kd                        = require 'kd'
timeago                   = require 'timeago'
KDButtonViewWithMenu      = kd.ButtonViewWithMenu

ActivityItemMenuItem      = require 'activity/views/activityitemmenuitem'
BaseStackTemplateListItem = require './basestacktemplatelistitem'


module.exports = class StackTemplateListItem extends BaseStackTemplateListItem

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry "stacktemplate-item clearfix", options.cssClass
    super options, data

    { inuse, accessLevel } = @getData()

    @inuseView = new kd.CustomHTMLView
      cssClass : 'inuse-tag'
      partial  : 'IN USE'
      tooltip  :
        title  : 'This group currently using this template'

    @accessLevelView = new kd.CustomHTMLView
      cssClass : "accesslevel-tag #{accessLevel}"
      partial  : accessLevel.toUpperCase()
      tooltip  :
        title  : switch accessLevel
          when 'public'
            'This group currently using this template'
          when 'group'
            'This template can be used in group'
          when 'private'
            'Only you can use this template'

    @inuseView.hide()  unless inuse


  updateStackTemplate: ->
    @getDelegate().emit 'ItemSelected', @getData()


  pistachio: ->

    { meta } = @getData()

    """
    <div class='stacktemplate-info clearfix'>
      {div.title{#(title)}} {{> @inuseView}} {{> @accessLevelView}}
      <cite>#{timeago meta.createdAt}</cite>
    </div>
    <div class='buttons'>{{> @settings}}</div>
    """
