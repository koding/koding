kd = require 'kd'
HomeWelcome = require './'
LocalStorage = require 'app/localstorage'


module.exports = class WelcomeModal extends kd.ModalView

  constructor: (options = {}, data) ->

    storage = new LocalStorage 'Koding', '1.0'
    landedOnWelcome = storage.getValue 'landedOnWelcome'

    options.cssClass = "HomeWelcomeModal#{if landedOnWelcome then ' hidden' else ''}"
    options.width    = 710
    options.overlay  = yes

    super options, data

    { router, mainController } = kd.singletons

    router.once 'RouteInfoHandled', => @destroy no

    mainController.once 'AllWelcomeStepsDone', @bound 'showCongratulationModal'
    mainController.once 'AllWelcomeStepsDone', @bound 'destroy'
    mainController.once 'AllWelcomeStepsNotDoneYet', @bound 'initialShow'

    storage.setValue 'landedOnWelcome', ''


  showCongratulationModal: ->

    modal = new kd.ModalView
      title : 'Success!'
      width : 530
      cssClass : 'Congratulation-modal'
      content : "<p class='description'>Congratulations. You have completed all items on your onboarding list.</p>"


    kd.View::addSubView.call modal, new kd.CustomHTMLView
      cssClass : 'alien'


    modal.addSubView new kd.CustomHTMLView
      cssClass : 'image-wrapper'

    modal.addSubView new kd.ButtonView
      title : 'KEEP ROCKING!'
      cssClass: 'GenericButton'


  initialShow: ->
    @show()
    @_windowDidResize()
    { width } = @getOptions()
    height = @getHeight()
    leftOrigin = "#{-((window.innerWidth - width) / 2 - 240)}px"
    topOrigin  = "#{-((window.innerHeight - height) / 2 - 22)}px"
    @getElement().style.transformOrigin = "#{leftOrigin} #{topOrigin}"


  viewAppended: ->

    super

    @addSubView new HomeWelcome


  destroy: (selfInitiated = yes) ->

    @setClass 'out'

    kd.singletons.router.handleRoute '/IDE'  if selfInitiated

    # fat arrow is not unnecessary - sy
    kd.utils.wait 400, => super

