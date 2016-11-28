kd = require 'kd'

module.exports = class FailuresOutput extends kd.CustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass       = 'failures-output'
    options.width          = 900
    options.height         = 740
    options.overlay       ?= yes

    super options, data

    @files = Object.keys(data)

    @isOpen = {}
    for file in @files
      @isOpen[file] = no

    @stateControl = {}
    for file in @files
      @stateControl[file] = null

    @mustGotoRainforest = []
    for file in @files
      suites = data[file].filter (suite) -> suite.status is 'Cannot be Automated'
      @mustGotoRainforest.push file  if suites.length

    @addViews()


  addViews: ->

    data = @getData()

    @addSubView @suiteResults = new kd.CustomHTMLView
      cssClass: 'suite-results'

    @suiteResults.addSubView @failuresModal = new kd.CustomHTMLView
      cssClass: 'failures-modal'

    singleResult = @files.length is 1

    [0..@files.length-1].forEach (i) =>
      fileName = @files[i]
      mustGotoRainforest = fileName in @mustGotoRainforest
      options =
        id: i
        fileName: fileName
        suites: data[fileName]
        isOpen: @isOpen[fileName]
        singleResult: singleResult
        mustGotoRainforest: mustGotoRainforest

      @addSuiteResult options


  addSuiteResult: (options) ->

    { fileName, suites, isOpen, mustGotoRainforest, callback, singleResult, id } = options

    @failuresModal.addSubView suite = new kd.CustomHTMLView
      cssClass: 'suite'
      click: =>
        @isOpen[fileName] = not @isOpen[fileName]
        @updateViewClasses fileName

    fileNameClassName = 'file-name'
    fileNameClassName = 'file-name rainforest' if mustGotoRainforest


    suite.addSubView @fileNameWrapper = new kd.CustomHTMLView
      cssClass: 'file-name-wrapper'
      partial : "<div class='#{fileNameClassName}'>#{fileName}</div>"


    suite.addSubView @header = new kd.CustomHTMLView
      cssClass : 'header hidden'
      partial : """
        <div class='suit-name'>Suit Name</div>
        <div class='status'>Status</div>
      """

    suite.addSubView @wrapper = new kd.CustomHTMLView
      cssClass: 'hidden'


    suites.forEach (s) =>
      @wrapper.addSubView @addSuitInfoWrapper s

    if singleResult
      @isOpen[fileName] = isOpen = yes
      @updateViewClasses fileName

    @stateControl[fileName] = { @fileNameWrapper, @header, @wrapper }


  updateViewClasses: (fileName) ->

    { @fileNameWrapper, @header, @wrapper } = @stateControl[fileName]

    if @isOpen[fileName]
      @fileNameWrapper.setClass 'active'
      @wrapper.show()
      @header.show()
    else
      @fileNameWrapper.unsetClass 'active'
      @wrapper.hide()
      @header.hide()


  addSuitInfoWrapper: (suite) ->

    { status, title } = suite

    statusClassName = unless status is 'Cannot be Automated' or status is 'Not Implemented' then 'error'
    else if status is 'Cannot be Automated' then 'hti'
    else 'ni'

    new kd.CustomHTMLView
      cssClass : 'suite-info-wrapper'
      partial : """
        <div class='title'>#{title}</div>
        <div class='status'>
          <span class=#{statusClassName}>#{status}</span>
        </div>
      """
