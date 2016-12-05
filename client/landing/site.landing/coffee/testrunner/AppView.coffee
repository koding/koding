kd = require 'kd'
filenames = require './tests/filenames'
preparedependencies = require './util/preparedependencies'
Encoder = require 'htmlencode'


module.exports = class AppView extends kd.View


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'appview', options.cssClass

    super options, data

    @addSubView new kd.CustomHTMLView
      domId: 'mocha'
      cssClass: 'mocha-class'

    @addSubView @mainView = new kd.CustomHTMLView
      cssClass: 'testrunner-view'

    @addMochaTestListView()


  addMochaTestListView: ->

    @modal = new kd.ModalView
      overlay : yes
      title : 'WELCOME TO TEST CENTER'
      cssClass : 'test-modal'
      buttons :
        Run :
          title : 'Run Tests'
          cssClass : 'kd solid medium run-tests'
          callback : =>
            @modal.destroy()

    scrollContent = new kd.CustomScrollView
      cssClass: 'scroll-content'

    filenames = @getData()

    Object.keys(filenames).forEach (filename) =>
      tests = preparedependencies filename

      test = tests[filename]
      dependencies = Object.keys(tests).filter (t) -> t isnt filename

      scrollContent.addSubView @getFileWrapperView(filename)
      .addSubView @getTestInfoView test
      .addSubView @getDependenciesView dependencies

    @modal.addSubView scrollContent


  getFileWrapperView: (filename) ->

    testFileWrapper = new kd.CustomHTMLView
      cssClass : 'test-file'

    testFileWrapper.addSubView new kd.CustomHTMLView
      tagName : 'a'
      cssClass : 'file-name'
      partial : filename
      click : @onClickTestFile.bind this, filename

    testFileWrapper


  getTestInfoView: (test) ->

    testCount = test.testCount
    tag = test.tag
    tagCssClass = kd.utils.curry 'test-tag', tag

    testInfoWrapper = new kd.CustomHTMLView
      cssClass : 'test-info-wrapper'

    testInfoWrapper.addSubView new kd.CustomHTMLView
      cssClass : 'test-count'
      partial : "<span>#Tests: #{testCount}</span>"

    testInfoWrapper.addSubView new kd.CustomHTMLView
      cssClass : tagCssClass
      partial : tag

    testInfoWrapper


  getDependenciesView: (dependencies) ->

    testDependenciesWrapper = new kd.CustomHTMLView
      cssClass : 'test-dependencies'

    dependencies.forEach (dep) =>
      testDependenciesWrapper.addSubView new kd.CustomHTMLView
        tagName : 'a'
        cssClass : 'test-dependency'
        partial : dep
        click : @onClickTestFile.bind this, dep
        attributes:
          title : dep

    testDependenciesWrapper


  renderStepsView: ( steps ) ->
    stepsWrapper = new kd.CustomHTMLView
      cssClass: 'steps-wrapper'

    steps.forEach (step) ->
      { description, asserts } = step

      desc = new kd.CustomHTMLView
        cssClass: 'steps-wrapper description'
        partial: "<span>#{description}</span>"
        attributes :
          testPath : Encoder.htmlEncode description

      assertsWrapper = new kd.CustomHTMLView
        cssClass: 'steps-wrapper assertsWrapper'

      asserts.forEach (it) ->
        assertsWrapper.addSubView new kd.CustomHTMLView
          cssClass: 'steps-wrapper it'
          partial: "<span>#{it}</span>"
          attributes :
            testPath : Encoder.htmlEncode it

      stepsWrapper.addSubView desc
      stepsWrapper.addSubView assertsWrapper

    stepsWrapper


  onClickTestFile: (name) ->

    @modal?.destroy()
    tests = preparedependencies name

    runningTests = new kd.CustomHTMLView
      cssClass: 'runningTests'

    Object.keys(tests).forEach (name) =>
      testSuites = new kd.CustomHTMLView
        cssClass: 'runningTests test-file'
        partial: "<span>#{name}</span>"
        attributes :
          testPath : Encoder.htmlEncode name

      { steps } = tests[name]
      @renderStepsView steps
      runningTests.addSubView(testSuites).addSubView @renderStepsView steps

    @mainView.addSubView runningTests

    href = "http://dev.koding.com:8090/Teams?test=#{name}"
    window.open href, '_blank'
