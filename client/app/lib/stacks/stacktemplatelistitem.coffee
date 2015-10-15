kd                        = require 'kd'
timeago                   = require 'timeago'

BaseStackTemplateListItem = require './basestacktemplatelistitem'


module.exports = class StackTemplateListItem extends BaseStackTemplateListItem

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry "stacktemplate-item clearfix", options.cssClass
    super options, data

    { inuse, accessLevel, config } = @getData()

    @inuseView = new kd.CustomHTMLView
      cssClass : 'custom-tag'
      partial  : 'IN USE'
      tooltip  :
        title  : 'This group currently using this template'

    @notReadyView = new kd.CustomHTMLView
      cssClass : 'custom-tag not-ready'
      partial  : 'NOT READY'
      tooltip  :
        title  : 'Template is not verified or credential data is missing'

    @accessLevelView = new kd.CustomHTMLView
      cssClass : "custom-tag #{accessLevel}"
      partial  : accessLevel.toUpperCase()
      tooltip  :
        title  : switch accessLevel
          when 'public'
            'This group currently using this template'
          when 'group'
            'This template can be used in group'
          when 'private'
            'Only you can use this template'

    @inuseView.hide()     unless inuse
    @notReadyView.hide()  if config.verified


  editStackTemplate: ->
    @getDelegate().emit 'ItemSelected', @getData()


  settingsMenu: ->

    listView      = @getDelegate()
    stackTemplate = @getData()

    if not stackTemplate.inuse and stackTemplate.config.verified
      @addMenuItem 'Apply to Team', ->
        listView.emit 'ItemSelectedAsDefault', stackTemplate

    super


  pistachio: ->

    { meta } = @getData()

    """
    <div class='stacktemplate-info clearfix'>
      {div.title{#(title)}} {{> @inuseView}} {{> @notReadyView}} {{> @accessLevelView}}
      <cite>#{timeago meta.createdAt}</cite>
    </div>
    <div class='buttons'>{{> @settings}}</div>
    """
