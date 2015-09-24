kd                        = require 'kd'
isKoding                  = require 'app/util/isKoding'
showError                 = require 'app/util/showError'
checkFlag                 = require 'app/util/checkFlag'
StacksModal               = require 'app/stacks/stacksmodal'
EnvironmentList           = require './environmentlist'
EnvironmentListController = require './environmentlistcontroller'


module.exports = class EnvironmentsModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'environments-modal', options.cssClass
    options.width    = if isKoding() then 742 else 772
    options.overlay  = yes

    options.title = "Your #{if isKoding() then 'Machines' else 'Stacks'}"


    super options, data

    listView     = new EnvironmentList
    controller   = new EnvironmentListController
      view       : listView
      wrapper    : no
      scrollView : no
      selected   : options.selected


    if checkFlag 'super-admin'

      advancedButton = new kd.ButtonView
        title    : 'ADVANCED'
        cssClass : 'compact solid green advanced'
        callback : -> new StacksModal

      # Hack to add button outside of modal container
      @addSubView advancedButton, '.kdmodal-inner'


    @addSubView controller.getView()

    listView.on 'ModalDestroyRequested', @bound 'destroy'
    listView.on 'StackReinitRequested', (stack) =>

      stack.delete (err) =>
        return showError err  if err

        { computeController, appManager } = kd.singletons

        computeController
          .reset()

          .once 'RenderStacks', (stacks) =>

            new kd.NotificationView
              title : 'Stack reinitialized'

            # We need to quit here to be able to re-load
            # IDE with new machine stack, there might be better solution ~ GG
            frontApp = appManager.getFrontApp()
            frontApp.quit()  if frontApp?.options.name is 'IDE'

            @destroy()

          .createDefaultStack()
