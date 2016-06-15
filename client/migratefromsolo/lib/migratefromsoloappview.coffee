kd = require 'kd'
getGroup = require 'app/util/getGroup'
showError = require 'app/util/showError'
ProvidersView = require 'stacks/views/stacks/providersview'
SoloMachinesListView = require './solomachineslistview'
EnvironmentFlux = require 'app/flux/environment'
MigrationFinishedView = require './migrationfinishedview'


module.exports = class MigrateFromSoloAppView extends kd.ModalView

  ACTIVE_MIGRATION = 'active-migration'

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'BaseModalView MigrateFromSoloAppView', options.cssClass
    options.width = 800
    options.height = 700
    options.overlay ?= yes

    super options, data

    @machines = null
    @credential = null

    @storage = kd.getSingleton('localStorageController').storage 'migrator'

    @mainHeader = new kd.CustomHTMLView
      tagName: 'header'
      partial: '<h1>Import VMs From Koding Solo</h1>'
      cssClass: 'mainHeader'

    @mainSection = new kd.CustomHTMLView
      tagName: 'section'
      cssClass: 'main mainSection inactive'

    @mainSection.addSubView @stepHeader = new kd.CustomHTMLView
      tagName: 'h2'
      cssClass: 'stepHeader'

    @mainSection.addSubView @stepDescription = new kd.CustomHTMLView
      tagName: 'p'
      cssClass: 'stepDescription'
      click: (event) =>
        @handleSupportRequest no  if event.target.className is 'support'
        kd.utils.stopDOMEvent event

    @mainSection.addSubView @stepContainer = new kd.CustomHTMLView
      tagName: 'div'
      cssClass: 'stepContainer'

    @stepContainer.addSubView @providersView = new ProvidersView { provider: 'aws' }
    @stepContainer.addSubView @soloMachinesList = new SoloMachinesListView
    @stepContainer.addSubView @progressBar = new kd.ProgressBarView { initial: 1 }
    @stepContainer.addSubView @statusText = new kd.CustomHTMLView { cssClass: 'status-text' }

    @providersView.on 'ItemSelected', (credentialItem) =>
      @credential = credentialItem.getData()
      @switchToMachinesList()

    @soloMachinesList.on 'MachinesConfirmed', (machines) =>
      @machines = machines
      @switchToMigrationProcess()

    @soloMachinesList.on 'SupportRequested', @bound 'handleSupportRequest'

    @mainFooter = new kd.CustomHTMLView
      tagName: 'footer'
      cssClass: 'mainFooter'

    @mainFooter.addSubView @backLink = new kd.CustomHTMLView
      tagName: 'a'
      partial: 'GO BACK'
      cssClass: 'back-link hidden'
      attributes: { href: '#' }

    @mainFooter.addSubView @nextButton = new kd.ButtonView
      title    : 'Next'
      cssClass : 'GenericButton hidden'

    @addSubView @mainHeader
    @addSubView @mainSection
    @addSubView @mainFooter

    @on 'KDObjectWillBeDestroyed', ->
      kd.singletons.router.handleRoute '/IDE'

    { computeController } = kd.singletons

    initialState = =>
      @mainSection.unsetClass 'inactive'
      @nextButton.show()
      @backLink.show()
      @storage.unsetKey ACTIVE_MIGRATION
      @switchToCredentials()

    if activeMigration = @storage.getValue ACTIVE_MIGRATION

      new kd.NotificationView
        title: 'Checking migration status...'

      { eventName, eventId } = activeMigration

      if not eventName or not eventId
        initialState()

      else
        computeController.getKloud()
          .event [{ type: eventName, eventId }]

          .then (event) =>
            if event.err
              initialState()
            else
              @mainSection.unsetClass 'inactive'
              @switchToMigrationProcess activeMigration

          .catch =>
            initialState()

    else
      initialState()



  setBackLinkCallback: (cb) ->

    @backLink.off 'click'
    @backLink.on 'click', (event) ->
      kd.utils.stopDOMEvent event
      cb()


  switchToCredentials: ->

    @stepHeader.updatePartial 'Select Personal AWS Credentials'
    @stepDescription.updatePartial 'Your personal AWS credentials are required to import your solo account.'

    @setBackLinkCallback kd.noop
    @backLink.hide()
    @nextButton.hide()

    @providersView.show()
    @soloMachinesList.hide()
    @progressBar.hide()
    @statusText.hide()


  switchToMachinesList: ->

    @stepHeader.updatePartial 'Select the VMs You Would Like to Transfer'
    @stepDescription.updatePartial '''
      A new stack will be created for the selected VMs. You can migrate
      following machines anytime before <strong>July 15, 2016</strong>.
      For more information please contact with
      <a href='#' class='support'>support</a>.
    '''

    @setBackLinkCallback @bound 'switchToCredentials'

    @backLink.show()
    @nextButton.hide()

    @providersView.hide()
    @soloMachinesList.show()
    @progressBar.hide()
    @statusText.hide()


  switchToMigrationProcess: (migrateEvent) ->

    { computeController } = kd.singletons
    { slug } = getGroup()
    eventName = "migrate-#{slug}"

    @stepHeader.updatePartial 'A New Stack is Being Created for Your VMs'
    @stepDescription.updatePartial 'Once your VM’s are transferred they will be located under the stacks menu in a new stack called “Migrated Stack Template”.'

    @setBackLinkCallback @bound 'switchToCredentials'

    @statusText.updatePartial 'Migration in progress...'

    @nextButton.hide()
    @backLink.hide()
    @providersView.hide()
    @soloMachinesList.hide()
    @progressBar.show()
    @statusText.show()

    handler = ({ percentage }) =>
      @progressBar.updateBar percentage

      if percentage >= 100
        @storage.unsetKey ACTIVE_MIGRATION
        computeController.off eventName, handler
        EnvironmentFlux.actions.loadPrivateStackTemplates().then =>
          kd.utils.wait 500, @bound 'switchToFinishedView'

    followEvent = ({ eventName, eventId }) =>
      @storage.setValue ACTIVE_MIGRATION, { eventName, eventId }
      computeController.eventListener.addListener eventName, eventId
      computeController.on eventName, handler

    if migrateEvent
      return followEvent migrateEvent

    computeController.getKloud().migrate(
      provider: 'aws'
      groupName: slug
      machines: @machines
      identifier: @credential.identifier
    ).then ({ eventId }) =>

      eventId = (eventId.split '-').last
      followEvent { eventName, eventId }

    .catch (err) =>

      kd.warn err

      @statusText.updatePartial 'Migration failed, please contact with support'

      @nextButton.setTitle 'Contact Support'
      @nextButton.setCallback =>
        @handleSupportRequest()

      @nextButton.show()
      @backLink.hide()

      @progressBar.updateBar 100


  switchToFinishedView: ->

    @mainSection.destroySubViews()

    @mainSection.addSubView view = new MigrationFinishedView

    @backLink.hide()

    @nextButton.setTitle 'Start Koding'
    @nextButton.setCallback =>
      kd.singletons.router.handleRoute '/Home/Stacks'
      @destroy()

    @nextButton.show()


  handleSupportRequest: (destroy = yes) ->

    { mainController } = kd.singletons

    mainController.tellChatlioWidget 'show', { expanded: yes }, (err, result) ->
      showError err  if err

    @destroy()  if destroy
