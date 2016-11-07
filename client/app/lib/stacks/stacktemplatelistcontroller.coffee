kd                          = require 'kd'
async                       = require 'async'
remote                      = require 'app/remote'
whoami                      = require 'app/util/whoami'
Tracker                     = require 'app/util/tracker'
getGroup                    = require 'app/util/getGroup'
showError                   = require 'app/util/showError'
KDNotificationView          = kd.NotificationView
KodingListController        = require 'app/kodinglist/kodinglistcontroller'
StackTemplateListItem       = require './stacktemplatelistitem'
StackTemplateContentModal   = require './stacktemplatecontentmodal'
ContentModal = require 'app/components/contentModal'

module.exports = class StackTemplateListController extends KodingListController


  constructor: (options = {}, data) ->

    { JStackTemplate }        = remote.api
    { computeController }     = kd.singletons

    options.wrapper           = no
    options.scrollView        = no

    options.noItemFoundText  ?= 'You currently have no stack template'
    options.fetcherMethod    ?= (query, options, callback) =>

      queue = [
        (next) ->
          getGroup().canEditGroup (err, success) -> next null, success
        (next) ->
          # TODO Add Pagination here ~ GG
          # TMS-1919: This is TODO needs to be done ~ GG
          JStackTemplate.some query, { limit: 30 }, next
        (next) ->
          kd.singletons.computeController.fetchStacks next
      ]

      async.series queue, (err, results) =>
        callback err, []  if err
        [canEditGroup, stackTemplates, stacks] = results
        data = @prepareData stackTemplates, stacks, canEditGroup
        callback err, data


    super options, data

    @filterStates.query.group = getGroup().slug

    unless options.viewType is 'group'
      @filterStates.query.originId = whoami()._id


  bindEvents: ->

    super

    listView = @getListView()

    listView.on 'ItemAction', ({ action, item, options }) =>
      switch action
        when 'ShowItem'              then @showItem       item
        when 'EditItem'              then @editItem       item
        when 'ItemSelectedAsDefault' then @applyToTeam    item
        when 'GenerateStack'         then @generateStack  item

    @on 'FetchProcessFailed', ({ err }) ->
      showError err, { KodingError : 'Failed to fetch stackTemplates, try again later.' }

    { computeController, groupsController } = kd.singletons

    computeController.on 'RenderStacks', @bound 'handleRenderStacks'
    groupsController.on  'StackTemplateChanged', @bound 'handleStackTemplateChanged'


  updateItem: (stackTemplate) ->

    [target] = @getListItems().filter (i) -> i.getData()._id is stackTemplate._id

    return  unless target

    kd.singletons.computeController.fetchStacks (err, stacks) =>

      return showError  if err

      stackTemplate.inUse = @isTemplateInUse stacks, stackTemplate

      target.setData stackTemplate
      target.handleLabelStates()


  handleRenderStacks: (stacks) ->

    listItems = @getListItems()

    for stack in stacks
      [item] = listItems.filter (i) -> i.getData()._id is stack.baseStackId
      if item
        item.getData().inUse = yes
        item.inUseView.show()


  handleStackTemplateChanged: (params) ->

    stackTemplateId = params.contents
    hasFound        = no

    for item in @getListItems()
      item.isDefaultView.hide()
      item.getData().isDefault = no

      if item.getData()._id is stackTemplateId
        item.getData().isDefault = yes
        item.isDefaultView.show()
        item.updateAccessLevel()
        hasFound = yes

    @addStackTemplateById stackTemplateId  unless hasFound


  addStackTemplateById: (_id, callback = kd.noop) ->

    [item] = @getListItems().filter (i) -> i.getData()._id is _id

    if item
      kd.warn 'Stack template is already added to list!'
      return

    params = { _id }

    if @getOption('viewType') is 'private'
      params.originId = @filterStates.query.originId

    @fetch params, (items) =>
      @addListItems items
      callback items


  applyToTeam: (item) ->

    stackTemplate = item.getData()
    { config }    = stackTemplate

    unless config.verified
      return @emit 'StackIsNotVerified', stackTemplate

    { groupsController, appManager } = kd.singletons

    stackTemplate.makeTeamDefault (err, stackTemplate) =>
      if err
        @emit 'FailedToSetTemplate', err
        appManager.tell 'Stacks', 'reloadStackTemplatesList'


  generateStack: (item) ->

    stackTemplate = item.getData()
    stackTemplate.generateStack (err, stack) ->

      unless showError err
        kd.singletons.computeController.reset yes
        new kd.NotificationView { title: 'Stack generated successfully' }


  editItem: (item) ->

    stackTemplate = item.getData()
    listView      = @getListView()

    Tracker.track Tracker.STACKS_EDIT

    if stackTemplate.isDefault
      listView.askForEdit
        callback  : ({ action, modal }) =>
          switch action

            when 'CloneAndOpen'
              stackTemplate.clone (err, cloneStackTemplate) =>
                @reload()
                @_itemSelected cloneStackTemplate
                Tracker.track Tracker.STACKS_CLONED_TEMPLATE
                modal.destroy()

            when 'OpenEditor'
              @_itemSelected stackTemplate
              modal.destroy()
              Tracker.track Tracker.STACKS_STARTED_EDIT_DEFAULT

    else
      @_itemSelected stackTemplate
      Tracker.track Tracker.STACKS_STARTED_EDIT


  reload: -> @loadItems()


  _itemSelected: (data) ->

    @emit 'ItemSelected', data


  showItem: (item) ->

    new StackTemplateContentModal {}, item.getData()


  removeItem: (item) ->

    { groupsController, computeController, appManager }  = kd.singletons
    currentGroup  = groupsController.getCurrentGroup()
    template      = item.getData()
    listView      = @getListView()

    if template._id in (currentGroup.stackTemplates ? [])
      return showError 'This template currently in use by the Team.'

    if computeController.findStackFromTemplateId template._id
      return showError 'You currently have a stack generated from this template.'

    modal = new ContentModal
      cssClass : 'content-modal'
      width : 400
      overlay : yes
      title : 'Are you sure?'
      content : 'Do you want to delete this stack template?'
      callback : ({ status, modal }) ->
        return  unless status
        template.delete (err) ->

          listView.emit 'ItemAction', { action : 'ItemRemoved', item }

          if template.accessLevel is 'group'
            currentGroup.sendNotification 'GroupStackTemplateRemoved', template._id

          modal.destroy()
          Tracker.track Tracker.STACKS_DELETE_TEMPLATE

    modal.setAttribute 'testpath', 'RemoveStackModal'


  prepareData: (stackTemplates = [], stacks = [], canEditGroup) ->

    currentGroup = getGroup()
    { viewType } = @getOptions()

    stackTemplates.map (template) =>
      template.isDefault       = template._id in (currentGroup.stackTemplates or [])
      template.inUse           = @isTemplateInUse stacks, template
      template.canForcedReinit = canEditGroup and template.accessLevel is 'group'

    if viewType is 'group'
      stackTemplates = stackTemplates.filter (template) -> template.accessLevel is 'group'

    return stackTemplates


  isTemplateInUse: (stacks = [], stackTemplate) -> Boolean stacks.find (stack) -> stack.baseStackId is stackTemplate._id


  destroy: ->

    { computeController, groupsController } = kd.singletons

    computeController.off 'RenderStacks', @bound 'handleRenderStacks'
    groupsController.off  'StackTemplateChanged', @bound 'handleStackTemplateChanged'

    super
