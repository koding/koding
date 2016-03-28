kd                          = require 'kd'
remote                      = require('app/remote').getInstance()
whoami                      = require 'app/util/whoami'
Tracker                     = require 'app/util/tracker'
getGroup                    = require 'app/util/getGroup'
showError                   = require 'app/util/showError'
async                       = require 'async'
KDNotificationView          = kd.NotificationView
KodingListController        = require 'app/kodinglist/kodinglistcontroller'
StackTemplateListItem       = require './stacktemplatelistitem'
StackTemplateContentModal   = require './stacktemplatecontentmodal'


module.exports = class StackTemplateListController extends KodingListController


  constructor: (options = {}, data) ->

    { JStackTemplate }        = remote.api
    { computeController }     = kd.singletons

    options.wrapper           = no
    options.scrollView        = no

    options.noItemFoundText  ?= 'You currently have no stack template'
    options.fetcherMethod     = (query, options, callback) =>

      queue = [
        (next) ->
          currentGroup.canEditGroup (err, success) -> next null, success
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

    listView = @getListView()

    listView.on 'ItemAction', ({action, item, options}) =>
      switch action
        when 'RemoveItem'            then @removeItem     item
        when 'ShowItem'              then @showItem       item
        when 'EditItem'              then @editItem       item
        when 'ItemSelectedAsDefault' then @applyToTeam    item
        when 'GenerateStack'         then @generateStack  item

    @on 'FetchProcessFailed', ({ err }) =>
      showError err, { KodingError : 'Failed to fetch stackTemplates, try again later.' }


  generateStack: (item) ->

    stackTemplate = item.getData()
    stackTemplate.generateStack (err, stack) =>

      unless showError err
        kd.singletons.computeController.reset yes, @bound 'reload'
        new kd.NotificationView { title: 'Stack generated successfully' }


  editItem: (item) ->

    stackTemplate = item.getData()
    listView      = @getListView()

    Tracker.track Tracker.STACKS_EDIT

    if stackTemplate.isDefault
      listView.askForEdit
        callback  : ({ action, modal }) =>
          switch action

            when 'CloseAndOpen'
              stackTemplate.clone (err, cloneStackTemplate) =>
                @reload()
                @_itemSelected stackTemplate
                modal.destroy()

            when 'OpenEditor'
              @_itemSelected stackTemplate
              modal.destroy()

    else
      @_itemSelected stackTemplate


  reload: -> @loadItems()


  _itemSelected: (data) ->

    @getListView().emit 'ItemSelected', data


  showItem: (item) ->

    new StackTemplateContentModal {}, item.getData()


  removeItem: (item, options) ->

    { groupsController, computeController, appManager }  = kd.singletons
    currentGroup  = groupsController.getCurrentGroup()
    template      = item.getData()
    listView      = @getListView()

    if template._id in (currentGroup.stackTemplates ? [])
      return showError 'This template currently in use by the Team'

    if computeController.findStackFromTemplateId template._id
      return showError 'You currently have a stack generated from this template'

    listView.askForConfirm
      title       : 'Remove stack template ?'
      description : 'Do you want to remove this stack template ?'
      callback    : ({ status, modal }) ->
        return  unless status
        template.delete (err) ->
          listView.removeItem item
          modal.destroy()
          appManager.tell 'Stacks', 'reloadStackTemplatesList'


  prepareData: (stackTemplates = [], stacks = [], canEditGroup) ->

    currentGroup = getGroup()
    { viewType } = @getOptions()

    stackTemplates.map (template) ->
      template.isDefault       = template._id in (currentGroup.stackTemplates or [])
      template.inUse           = Boolean stacks.find (stack) -> stack.baseStackId is template._id
      template.canForcedReinit = canEditGroup and template.accessLevel is 'group'

    if viewType is 'group'
      stackTemplates = stackTemplates.filter (template) -> template.accessLevel is 'group'

    return stackTemplates
