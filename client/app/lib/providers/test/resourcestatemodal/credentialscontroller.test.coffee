kd = require 'kd'
expect  = require 'expect'
CredentialsController = require 'app/providers/resourcestatemodal/controllers/credentialscontroller'
PageContainer = require 'app/providers/resourcestatemodal/views/pagecontainer'
CredentialsPageView = require 'app/providers/resourcestatemodal/views/stackflow/credentialspageview'
CredentialsErrorPageView = require 'app/providers/resourcestatemodal/views/stackflow/credentialserrorpageview'

describe 'CredentialsController', ->

  container     = null
  stack         =
    title       : 'Test stack'
    status      : { state : 'NotInitialized' }
    credentials : { custom : [ '123' ] }
  credentials   = { provider : 'aws', items : [] }
  requirements  = { provider : 'userInput', items : [] }

  beforeEach ->

    container = new PageContainer()


  describe 'constructor', ->

    it 'should show credentials page if error page requests it', ->

      controller = new CredentialsController { container }, stack
      controller.setup credentials, requirements

      controller.errorPage.emit 'CredentialsRequested'

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof CredentialsPageView).toBeTruthy()

    it 'requests instructions page from parent controller if credentials page asks for that', ->

      controller = new CredentialsController { container }, stack
      controller.setup credentials, requirements

      listener = { callback: kd.noop }
      spy = expect.spyOn listener, 'callback'
      controller.on 'InstructionsRequested', -> listener.callback()

      controller.credentialsPage.emit 'InstructionsRequested'
      expect(spy).toHaveBeenCalled()


  describe '::show', ->

    it 'should show credentials page by default', ->

      controller = new CredentialsController { container }, stack
      controller.setup credentials, requirements
      controller.show()

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof CredentialsPageView).toBeTruthy()


  describe '::showError', ->

    it 'should show error page', ->

      controller = new CredentialsController { container }, stack
      controller.setup credentials, requirements
      controller.show()
      controller.showError 'Error!'

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof CredentialsErrorPageView).toBeTruthy()


  describe '::checkVerificationResult', ->

    identifier = '123'

    it 'should return error if response is empty', ->

      controller = new CredentialsController { container }, stack

      response = null
      { err } = controller.checkVerificationResult identifier, response

      expect(err).toExist()

    it 'should return error if response doesn\'t contain data for credential identifier', ->

      controller = new CredentialsController { container }, stack

      response = { '456': { verified : yes } }
      { err } = controller.checkVerificationResult identifier, response

      expect(err).toExist()

    it 'should return error if response contains error message for credential identifier', ->

      controller = new CredentialsController { container }, stack

      response = {}
      response[identifier] = { message : 'Error!\n\n' }
      { err } = controller.checkVerificationResult identifier, response

      expect(err).toEqual 'Error!'

    it 'should return verified = true if response has verified flag', ->

      controller = new CredentialsController { container }, stack

      response = {}
      response[identifier] = { verified : yes }
      { err, verified } = controller.checkVerificationResult identifier, response

      expect(err).toNotExist()
      expect(verified).toBeTruthy()


  describe '::handleSubmitResult', ->

    it 'should show error page if error is passed', ->

      controller = new CredentialsController { container }, stack
      controller.setup credentials, requirements

      controller.handleSubmitResult 'Error!'

      activePane = container.getActivePane()
      expect(activePane).toExist()
      expect(activePane.mainView instanceof CredentialsErrorPageView).toBeTruthy()

    it 'should emit StartBuild event with passed identifiers', (done) ->

      identifiers = [ { aws : [ '456' ] } ]

      controller = new CredentialsController { container }, stack
      controller.setup credentials, requirements

      controller.on 'StartBuild', (_identifiers) ->
        expect(_identifiers['aws']).toEqual [ '456' ]
        expect(_identifiers['custom']).toEqual [ '123' ]
        done()

      controller.handleSubmitResult null, identifiers
