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

    @setTestPath()
    @buildViews()

    kd.singletons.groupsController.on 'StackTemplateChanged', (params) =>
      if params.contents._id is _id
        stackTemplate = params.contents
      else
        stackTemplate.isDefault = no

      @setData stackTemplate
      @setTestPath()
      @updateLabels()


  setTestPath: ->

    { accessLevel } = @getData()
    @setAttribute 'testpath', "#{accessLevel}StackListItem"


  buildViews: ->

    { meta, isDefault, inUse, accessLevel, config, title } = @getData()

    @addSubView @info = new kd.CustomHTMLView
      cssClass  : 'stacktemplate-info clearfix'

    @info.addSubView @title = new kd.CustomHTMLView
      cssClass  : 'title'
      partial   : title

    @info.addSubView @labels  = new kd.CustomHTMLView
      cssClass  : 'labels'

    @info.addSubView @lastUpdatedView = new kd.CustomHTMLView
      tagName    : 'cite'
      partial    : "Last updated #{timeago meta.modifiedAt}"

    @addSubView @buttons  = new kd.CustomHTMLView
      cssClass   : 'buttons'

    @buttons.addSubView @settings
    @buildLabels()


  buildLabels: ->

    { isDefault, inUse, accessLevel, config } = @getData()

    @labels.addSubView @isDefaultView = new kd.CustomHTMLView
      cssClass   : 'custom-tag'
      partial    : 'DEFAULT'
      attributes :
        testpath : 'StackDefaultTag'
      tooltip    :
        title    : 'This group currently using this template'

    @labels.addSubView @inUseView     = new kd.CustomHTMLView
      cssClass   : 'custom-tag'
      partial    : 'IN USE'
      attributes :
        testpath : 'StackInUseTag'
      tooltip    :
        title    : 'This template is in use'

    @labels.addSubView @notReadyView  = new kd.CustomHTMLView
      cssClass   : 'custom-tag not-ready'
      partial    : 'NOT READY'
      attributes :
        testpath : 'StackNotReadyTag'
      tooltip    :
        title    : 'Template is not verified or credential data is missing'

    @labels.addSubView @accessLevelView = new kd.CustomHTMLView
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
