_  = require 'lodash'
$ = require 'jquery'
kd = require 'kd'
ContentModal = require 'app/components/contentModal'


module.exports = class UploadCSVModal extends ContentModal

  constructor: (options = {}, data) ->

    { input: @input } = options

    $('.uploadcsv').change =>
      @createFormDataAndRequest()

    @trailerContent = '''
      <p>Before starting to upload your file, please be sure that you have the right format. The file should contain Email, First Name, Last Name, and Role fields in the right order. Roles can be Admin or Member.
      </br></br>
      Here is an example:</p>

      <div class='example-csv'>
        Email, First Name, Last Name, Role </br>
        somehting, somthing, something, somehting </br>
        somehting, somthing, something, somehting </br>
        somehting, somthing, something, somehting </br>
        somehting, somthing, something, somehting </br>

      </div>
    '''

    options = _.assign {}, options,
      title: 'Upload CSV File'
      cssClass: 'content-modal csv-upload'
      width: 600

    super options

    @createTrailerStatePage()
    @createUploadingStatePage()
    @createErrorUploadingPage()
    @createSuccessPage()
    @creatButtons()


  createTrailerStatePage: ->

    @addSubView @trailerPage = new kd.CustomHTMLView
      tagName: 'main'
      cssClass: 'main-container trailer-state'
      partial: @trailerContent


  createUploadingStatePage: ->

    @addSubView @uploadingPage = new kd.CustomHTMLView
      tagName: 'main'
      cssClass: 'main-container uploading-state hidden'

    @uploadingPage.addSubView @loader = @getLoaderView()


  createErrorUploadingPage: ->

    @addSubView @errorUploading = new kd.CustomHTMLView
      tagName: 'main'
      cssClass: 'main-container error-uploading hidden'


  createSuccessPage: ->

    @addSubView @successPage = new kd.CustomHTMLView
      tagName: 'main'
      cssClass: 'main-container success-state hidden'


  creatButtons: ->

    @addSubView @buttonWrapper = new kd.CustomHTMLView
      cssClass: 'button-wrapper'

    @buttonWrapper.addSubView @selectAndUpload = new kd.ButtonView
      cssClass: 'GenericButton select-upload'
      title: 'SELECT AND UPLOAD'
      callback: => @input.click()

    @buttonWrapper.addSubView @cancelButton = new kd.ButtonView
      cssClass: 'GenericButton cancel'
      title: 'Cancel'
      callback: => @getOptions().cancel()

    @buttonWrapper.addSubView @gonderGitsin = new kd.ButtonView
      cssClass: 'GenericButton select-upload hidden'
      title: 'SEND ALL INVITES'
      callback: =>
        @sendData()


  getLoaderView: ->

    new kd.LoaderView
      cssClass   : 'main-loader'
      showLoader : yes
      size       :
        width    : 25
        height   : 25


  createFormDataAndRequest : ->


    @trailerPage.hide()
    @uploadingPage.show()

    fileNames = []

    @formData = new FormData()

    for file in @input.files
      fileNames.push file.name
      @formData.append 'file', file, {
        filename: file.name
        contentType: 'multipart/form-data'
      }

    @uploadingPage.setPartial "
      <div>
        Selected Files: </br>
        #{fileNames.join '</br>'}
      </div>
    "

    @makeReq '/-/teams/invite-by-csv-analyze', 'successAnalyzeCSV', 'errorAnalyzeCSV'
    @input.value = null


  makeReq: (url, success, error) ->

    $.ajax
      data : @formData
      method : 'POST'
      url : url
      contentType: false
      processData : false # prevents illegal invocation error
      success : @bound success
      error : @bound error


  sendData: ->

    @makeReq '/-/teams/invite-by-csv', 'success', 'error'


  successAnalyzeCSV: (result) ->
    console.log 'res ', result
    @loader.hide()
    @successPage.show()
    @selectAndUpload.hide()
    @gonderGitsin.show()
    @uploadingPage.setPartial '''
      Would you like to send an invitation to all people below
      except already invited members? </br></br>
      In your files, we have found…
    '''
    @successPage.setPartial '''<div class='analyzeCSV'>
      <div class='wrapper'>
        <div class='total'>159</div>
        <div class='members'>89</div>
        <div class='admins'>15</div>
      </div>
      <div class='alreadyInvited'>+17 Already Invited members</div>
      </div>
    '''

  errorAnalyzeCSV: (err) ->

    @loader.hide()
    @errorUploading.show()
    @errorUploading.addSubView showError = new kd.CustomHTMLView
      cssClass: 'show-error'
      partial: '''
        It seems that the files you have selected not formatted right or empty or there are no valid data.
        Please make sure that you have selected the right files </br></br>
      '''

    showError.addSubView fileFormat = new kd.CustomHTMLView
      cssClass: 'file-format'
      partial: 'See the information about file format.'
      click: =>
        @errorUploading.updatePartial ''
        @trailerPage.show()
        @uploadingPage.hide()


  error: (err) ->

    @getOptions().error()
    @destroy()


  success: (result) ->

    @getOptions().success()
    @destroy()
