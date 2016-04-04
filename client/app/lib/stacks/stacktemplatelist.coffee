kd                        = require 'kd'
KDModalView               = kd.ModalView
KDOverlayView             = kd.OverlayView
showError                 = require 'app/util/showError'
KodingListView            = require 'app/kodinglist/kodinglistview'
StackTemplateListItem     = require './stacktemplatelistitem'
StackTemplateContentModal = require './stacktemplatecontentmodal'


module.exports = class StackTemplateList extends KodingListView


  constructor: (options = {}, data) ->

    options.cssClass   = kd.utils.curry 'stack-template-list', options.cssClass
    options.itemClass ?= StackTemplateListItem

    super options, data


  askForEdit: (options) ->

    { callback } = options

    modal = new KDModalView
      title          : 'Editing default stack template ?'
      overlay        : yes
      overlayOptions :
        cssClass     : 'second-overlay'
        overlayClick : yes
      content        : '
        This stack template is currently used by your team. If you continue
        to edit, all of your changes will be applied to all team members directly.
        We highly recommend you to clone this stack template
        first and work on the cloned version. Once you finish your work,
        you can easily apply your changes for all team members.
      '
      buttons      :
        'Clone and Open Editor':
          style    : 'solid medium green'
          loader   : yes
          callback : -> callback { action : 'CloseAndOpen', modal }
        "I know what I'm doing, Open Editor":
          style    : 'solid medium red'
          callback : -> callback { action : 'OpenEditor', modal }
