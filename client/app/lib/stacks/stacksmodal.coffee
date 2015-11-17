kd                          = require 'kd'
StackTemplateList           = require 'app/stacks/stacktemplatelist'
StackTemplateListController = require 'app/stacks/stacktemplatelistcontroller'


module.exports = class StacksModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'stacks-modal your-stacks', options.cssClass
    options.width    = 742
    options.title    = 'Your Stacks'
    options.overlay  = yes

    super options, data


  viewAppended: ->

    super

    listView   = new StackTemplateList
    controller = new StackTemplateListController
      view       : listView
      wrapper    : no
      scrollView : no

    createButton = new kd.ButtonView
      title      : 'Create New Stack'
      cssClass   : 'solid compact green create-stack'
      callback   : ->
        new kd.NotificationView title: 'Coming soon.'

    # Hack to add button outside of modal container
    @addSubView createButton, '.kdmodal-inner'

    @addSubView controller.getView()
