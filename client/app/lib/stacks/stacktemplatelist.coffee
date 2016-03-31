kd                        = require 'kd'
KDListView                = kd.ListView
KDModalView               = kd.ModalView
KDOverlayView             = kd.OverlayView
showError                 = require 'app/util/showError'
StackTemplateListItem     = require './stacktemplatelistitem'
StackTemplateContentModal = require './stacktemplatecontentmodal'
Tracker                   = require 'app/util/tracker'


module.exports = class StackTemplateList extends KDListView

  constructor: (options = {}, data) ->

    options.cssClass   = kd.utils.curry 'stack-template-list', options.cssClass
    options.itemClass ?= StackTemplateListItem

    super options, data


  deleteItem: (item) ->

    template = item.getData()

    currentGroup = kd.singletons.groupsController.getCurrentGroup()
    if template._id in (currentGroup.stackTemplates ? [])
      return showError 'This template currently in use by the Team'

    if kd.singletons.computeController.findStackFromTemplateId template._id
      return showError 'You currently have a stack generated from this template'

    # Since KDModalView.confirm not passing overlay options
    # to the base class (KDModalView) I had to do this hack
    # Remove this when issue fixed in Framework ~ GG
    overlay = new KDOverlayView { cssClass: 'second-overlay' }

    modal   = KDModalView.confirm
      title       : 'Remove stack template ?'
      description : 'Do you want to remove this stack template ?'
      ok          :
        title     : 'Yes'
        callback  :  => template.delete (err) =>
          modal.destroy()
          @emit 'ItemDeleted', item  unless showError err
          Tracker.track Tracker.STACKS_DELETE_TEMPLATE

    modal.once   'KDObjectWillBeDestroyed', overlay.bound 'destroy'
    overlay.once 'click',                   modal.bound   'destroy'

    return modal


  showItemContent: (item) ->

    new StackTemplateContentModal {}, item.getData()
