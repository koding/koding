kd                        = require 'kd'
timeago                   = require 'timeago'
showError                 = require 'app/util/showError'

BaseStackTemplateListItem = require './basestacktemplatelistitem'
ForceToReinitModal        = require './forcetoreinitmodal'


module.exports = class StackTemplateListItem extends BaseStackTemplateListItem

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'stacktemplate-item clearfix', options.cssClass
    super options, data

    { isDefault, inUse, accessLevel, config } = @getData()

    @isDefaultView = new kd.CustomHTMLView
      cssClass : 'custom-tag'
      partial  : 'DEFAULT'
      tooltip  :
        title  : 'This group currently using this template'

    @inUseView = new kd.CustomHTMLView
      cssClass : 'custom-tag'
      partial  : 'IN USE'
      tooltip  :
        title  : 'This template is in use'

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

    @isDefaultView.hide() unless isDefault
    @inUseView.hide()     unless inUse
    @notReadyView.hide()  if config.verified


  generateStackFromTemplate: ->

    stackTemplate = @getData()
    stackTemplate.generateStack (err, stack) =>

      unless showError err
        kd.singletons.computeController.reset yes, => @getDelegate().emit 'StackGenerated'
        new kd.NotificationView { title: 'Stack generated successfully' }


  _itemSelected: (data) ->
    @getDelegate().emit 'ItemSelected', data ? @getData()


  settingsMenu: ->

    listView      = @getDelegate()
    stackTemplate = @getData()

    if not stackTemplate.isDefault and stackTemplate.config.verified
      @addMenuItem 'Apply to Team', =>
        listView.emit 'ItemAction', { action : 'ItemSelectedAsDefault', item : this }

    # temporary comment until stack admin message design is ready
    # if stackTemplate.canForcedReinit
    #   @addMenuItem 'Force Stacks to Re-init', ->
    #     new ForceToReinitModal {}, stackTemplate

    super


  pistachio: ->

    { meta } = @getData()

    """
    <div class='stacktemplate-info clearfix'>
      {div.title{#(title)}} {{> @isDefaultView}} {{> @inUseView}} {{> @notReadyView}} {{> @accessLevelView}}
      <cite>Last updated #{timeago meta.modifiedAt}</cite>
    </div>
    <div class='buttons'>{{> @settings}}</div>
    """
