kd    = require 'kd'
JView = require 'app/jview'

StackTemplateListView = require './stacktemplatelistview'

module.exports = class InitialView extends kd.View

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = 'stacktemplates'

    super options, data

    @_stackTemplatesLength = 0

    @createStackButton = new kd.ButtonView
      title    : 'Create new Stack'
      cssClass : 'solid compact green action hidden'
      callback : (event) =>
        if @_stackTemplatesLength >= 1 and not event?.shiftKey
          @showWarning "Multiple Stack Template support will be
                        provided soon. You still can modify your
                        existing stack templates."
        else
          @emit 'CreateNewStack', skipOnboarding: yes

    @stackTemplateList = new StackTemplateListView

    @stackTemplateList.listView
      .on 'ItemSelected', (stackTemplate) =>
        @emit 'EditStack', stackTemplate

      .on 'ItemDeleted', =>
        @_stackTemplatesLength = @stackTemplateList.listView.items.length - 1

      .on 'ItemCloned', @bound 'reload'

      .on 'ItemSelectedAsDefault', @bound 'setDefaultTemplate'

    @stackTemplateList.listController.on 'ItemsLoaded', (stackTemplates) =>
      @emit 'NoTemplatesFound'  if stackTemplates.length is 0
      @_stackTemplatesLength = stackTemplates.length
      @createStackButton.show()


  reload: ->
    @stackTemplateList.listController.loadItems()


  setDefaultTemplate: (stackTemplate) ->

    { config } = stackTemplate

    unless config.verified
      return @showWarning "
        This stack template is not verified, please edit and save again
        to verify it. Only a verified stack template can be applied to a Team.
      "

    { groupsController } = kd.singletons

    groupsController.setDefaultTemplate stackTemplate, (err) =>
      if err
        @showWarning "An error occured:", err.message ? err
        console.warn err
      else
        @reload()


  showWarning: (content) ->
    modal = new kd.ModalView
      title          : ''
      content        : content
      overlay        : yes
      overlayOptions :
        cssClass     : 'second-overlay'
        overlayClick : yes
      buttons        :
        close        :
          title      : 'Close'
          cssClass   : 'solid medium gray'
          callback   : -> modal.destroy()


  pistachio: ->
    """
      <div class='text header'>Compute Stack Templates</div>
      <div class=top>
        <div class='text intro'>
          Stack Templates are awesome because when a user
          joins your group you can preconfigure their work
          environment by defining stacks.
          Learn more about stacks
        </div>
        {{> @createStackButton}}
      </div>
      {{> @stackTemplateList}}
    """
