_  = require 'lodash'
$ = require 'jquery'
kd = require 'kd'
ContentModal = require 'app/components/contentModal'


module.exports = class UploadCSVModal extends ContentModal

  constructor: (options = {}, data) ->

    { input: @input } = options

    @trailerContent = '''
      <p>Before starting to upload your file, please be sure that you have the right format.
      The file should contain Email, First Name (optional), Last Name (optional), and Role fields in the right order.
      Roles can be Admin or Member.
      </br></br>
      Here is an example:</p>

      <div class='example-csv'>
        Email, First Name, Last Name, Role </br>
        micheal@example.com, Micheal R., Crawley, Member </br>
        clora@example.com, Clora J., Ochoa, Member </br>
        randy@example.com, Randy S., Engel, Admin
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
      callback: =>
        $('.uploadcsv').change (event) =>
          @createFormDataAndRequest event
        @errorUploading.updatePartial ''
        @input.click()

    @buttonWrapper.addSubView @cancelButton = new kd.ButtonView
      cssClass: 'GenericButton cancel'
      title: 'Cancel'
      callback: => @destroy()

    @buttonWrapper.addSubView @sendAllInvites = new kd.ButtonView
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


  createFormDataAndRequest : (event) ->

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

    @errorUploading?.hide()

    @uploadingPage.updatePartial "
      <div>
       Selected File: </br>
        #{fileNames.join '</br>'}
      </div>
    "

    @makeReq '/-/teams/invite-by-csv-analyze', 'successAnalyzeCSV', 'errorAnalyzeCSV'

    @input.value = null
    $('.uploadcsv').unbind 'change'

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

    @loader.hide()

    if typeof result is 'string'
      @sendData()
      return
    @successPage.show()
    @selectAndUpload.hide()
    @sendAllInvites.show()
    @uploadingPage.updatePartial '''
      Would you like to send an invitation to all people below
      except already invited members? </br></br>
      In your files, we have found…
    '''
    { myself, admins, members, extras } = result
    @successPage.addSubView analyzeCSV = new kd.CustomHTMLView
      cssClass: 'analyzeCSV'
      partial: """
        <div class='wrapper'>
          <div class='total'>
            #{admins+members}</br>
            <label class='total-label'> Total
          </div>
          <div class='members'>
            #{members}</br>
            <label class='members-label'> Members
          </div>
          <div class='admins'>
            #{admins}</br>
            <label class='admins-label'> Admins
          </div>
        </div>
      """
    analyzeCSV.addSubView extraInfo = new kd.CustomHTMLView
    for ex in Object.keys(extras)
      if extras["#{ex}"].count
        extraInfo.setPartial """<div class='alreadyInvited'>+#{extras["#{ex}"].count} #{extras["#{ex}"].label}</div>"""


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
