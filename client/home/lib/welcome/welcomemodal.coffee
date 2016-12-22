kd = require 'kd'
HomeWelcome = require './'
LocalStorage = require 'app/localstorage'
globals = require 'globals'

module.exports = class WelcomeModal extends kd.ModalView

  constructor: (options = {}, data) ->

    storage = new LocalStorage 'Koding', '1.0'
    landedOnWelcome = storage.getValue 'landedOnWelcome'

    options.cssClass = "HomeWelcomeModal#{if landedOnWelcome then ' hidden' else ''}"
    options.width    = 710
    options.overlay  = yes
    options.overlayOptions = { cssClass: if landedOnWelcome then 'hidden' else '' }

    super options, data

    { router, mainController } = kd.singletons

    router.once 'RouteInfoHandled', => @destroy no

    mainController.once 'AllWelcomeStepsDone', @bound 'destroy'
    mainController.once 'AllWelcomeStepsDone', @bound 'showCongratulationModal'
    mainController.once 'AllWelcomeStepsNotDoneYet', @bound 'initialShow'

    storage.setValue 'landedOnWelcome', ''


  showCongratulationModal: ->

    { appStorageController } = kd.singletons

    appStorage  = appStorageController.storage "WelcomeSteps-#{globals.currentGroup.slug}"
    shownBefore = appStorage.getValue 'OnboardingSuccessModalShown'

    return  if shownBefore

    appStorage.setValue 'OnboardingSuccessModalShown', yes

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
      callback : -> modal.destroy()


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

    { router, computeController } = kd.singletons

    previousRoutes = router.visitedRoutes.filter (route) ->
      not (/^\/(?:Home).*/.test(route) or \
           /^\/(?:Welcome).*/.test(route) or \
           /\//.test(route))
    route = previousRoutes.last ? '/IDE'
    router.handleRoute route  if selfInitiated

    # fat arrow is not unnecessary - sy
    kd.utils.wait 400, => super
