kd                        = require 'kd'
timeago                   = require 'timeago'
showError                 = require 'app/util/showError'

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

    stackTemplate = @getData()

    if stackTemplate.inuse

      modal = new kd.ModalView
        title          : 'Editing in-use stack template ?'
        overlay        : yes
        overlayOptions :
          cssClass     : 'second-overlay'
          overlayClick : yes
        content        : "
          This stack template is currently using by the Team, if you continue
          to edit, all the changes you've made will be applied to all members,
          we highly recommend you to create a clone of this stack template
          first and do your updates on that clone. Once you finish your work
          with the cloned version, you can easily apply the changes to your
          team.
        "
        buttons      :

          "Clone and Open Editor":
            style    : 'solid medium green'
            loader   : yes
            callback : =>
              stackTemplate.clone (err, cloneStackTemplate) =>
                @_itemSelected cloneStackTemplate  unless showError err
                modal.destroy()

          "I know what I'm doing, Open Editor":
            style    : 'solid medium red'
            callback : =>
              @_itemSelected()
              modal.destroy()

    else
      @_itemSelected()


  _itemSelected: (data) ->
    @getDelegate().emit 'ItemSelected', data ? @getData()


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
