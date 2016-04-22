kd                        = require 'kd'
timeago                   = require 'timeago'
showError                 = require 'app/util/showError'

BaseStackTemplateListItem = require './basestacktemplatelistitem'
ForceToReinitModal        = require './forcetoreinitmodal'


module.exports = class StackTemplateListItem extends BaseStackTemplateListItem

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'stacktemplate-item clearfix', options.cssClass

    super options, data

    stackTemplate         = @getData()
    { accessLevel, _id }  = stackTemplate

    @setAttribute 'testpath', "#{accessLevel}StackListItem"

    @buildLabels()

    kd.singletons.groupsController.on 'StackTemplateChanged', (params) =>
      if params.contents is _id
        stackTemplate.isDefault = yes
        @isDefaultView?.show()
      else
        stackTemplate.isDefault = no
        @isDefaultView?.hide()

      @setData stackTemplate


  buildLabels: ->

    { isDefault, inUse, accessLevel, config } = @getData()

    @isDefaultView = new kd.CustomHTMLView
      cssClass   : 'custom-tag'
      partial    : 'DEFAULT'
      attributes :
        testpath : 'StackDefaultTag'
      tooltip    :
        title    : 'This group currently using this template'

    @inUseView   = new kd.CustomHTMLView
      cssClass   : 'custom-tag'
      partial    : 'IN USE'
      attributes :
        testpath : 'StackInUseTag'
      tooltip    :
        title    : 'This template is in use'

    @notReadyView = new kd.CustomHTMLView
      cssClass   : 'custom-tag not-ready'
      partial    : 'NOT READY'
      attributes :
        testpath : 'StackNotReadyTag'
      tooltip    :
        title    : 'Template is not verified or credential data is missing'

    @accessLevelView = new kd.CustomHTMLView
      cssClass   : "custom-tag #{accessLevel}"
      partial    : accessLevel.toUpperCase()
      attributes :
        testpath : 'StackAccessLevelTag'
      tooltip    :
        title    : switch accessLevel
          when 'public'
            'This group currently using this template'
          when 'group'
            'This template can be used in group'
          when 'private'
            'Only you can use this template'

    @isDefaultView.hide() unless isDefault
    @inUseView.hide()     unless inUse
    @notReadyView.hide()  if config.verified


  updateLabels: ->

    @isDefaultView?.destroy()
    @inUseView?.destroy()
    @notReadyView?.destroy()
    @accessLevelView?.destroy()
    @buildLabels()


  _itemSelected: (data) ->
    @getDelegate().emit 'ItemSelected', data ? @getData()


  settingsMenu: ->

    listView      = @getDelegate()
    stackTemplate = @getData()
    @menu         = {}

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
