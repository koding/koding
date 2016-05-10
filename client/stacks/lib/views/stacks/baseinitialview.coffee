kd      = require 'kd'
JView   = require 'app/jview'
Tracker = require 'app/util/tracker'

StackTemplateListView = require './stacktemplatelistview'

module.exports = class BaseInitialView extends kd.View

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = 'stacktemplates'

    super options, data

    @button = new kd.ButtonView
      title    : 'Create new Stack'
      cssClass : 'solid compact green action hidden'
      callback : @lazyBound 'emit', 'CreateNewStack'

    listViewOptions           = options.listViewOptions or {}
    listViewOptions.viewType ?= 'public'

    @stackTemplateList = new StackTemplateListView listViewOptions

    @stackTemplateList.listController
      .on 'ItemSelected', (stackTemplate) =>
        @emit 'EditStack', stackTemplate
      .on 'ItemsLoaded', (stackTemplates) =>
        @emit 'NoTemplatesFound'  if stackTemplates.length is 0
        @button?.show()
        @emit 'ready'
      .on 'StackIsNotVerified', =>
        @showWarning '
          This stack template is not verified, please edit and save again
          to verify it. Only a verified stack template can be applied to a Team.
        '
      .on 'FailedToSetTemplate', (err) =>
        @showWarning "Failed to set template: \n#{err.message}"


  reload: ->

    @stackTemplateList.listController.loadItems()


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
        {{> @button }}
      </div>
      {{> @stackTemplateList}}
    """
