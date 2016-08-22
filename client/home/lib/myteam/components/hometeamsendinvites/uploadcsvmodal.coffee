_  = require 'lodash'
$ = require 'jquery'
kd = require 'kd'
ContentModal = require 'app/components/contentModal'


module.exports = class UploadCSVModal extends ContentModal

  constructor: (options = {}, data) ->

    # { input: @input } = options

    options = _.assign {}, options,
      cssClass: 'content-modal csv-upload'
      width: 600

    super options

    @setTitle 'Upload CSV File'

    @createTrailerStatePage()
    @createUploadingStatePage()
    @createErrorUploadingPage()
    @createSuccessPage()
    @createButtons()


  createTrailerStatePage: ->

    @addSubView @trailerPage = new kd.CustomHTMLView
      tagName: 'main'
      cssClass: 'main-container trailer-state'
      partial: '''
        <p>Before uploading your file, please make sure you have the right format.
        The file should contain <strong>Email</strong>, <strong>First Name</strong> (optional), <strong>Last Name</strong> (optional), and <strong>Role </strong> fields in the right order.
        Roles can be <strong>Admin</strong> or <strong>Member</strong>.
        </br></br>
        <strong>Here is an example:</strong></p>
        </br>
        <div class='example-csv'>
          micheal@example.com, Micheal R., Crawley, Member </br>
          clora@example.com, Clora J., Ochoa, Member </br>
          randy@example.com, Randy S., Engel, Admin
        </div>
      '''


  createUploadingStatePage: ->

    @addSubView @uploadingPage = new kd.CustomHTMLView
      tagName: 'main'
      cssClass: 'main-container uploading-state hidden'


  createErrorUploadingPage: ->

    @addSubView @errorUploading = new kd.CustomHTMLView
      tagName: 'main'
      cssClass: 'main-container error-uploading hidden'


  createSuccessPage: ->

    @addSubView @successPage = new kd.CustomHTMLView
      tagName: 'main'
      cssClass: 'main-container success-state hidden'


  createButtons: ->

    @addSubView @buttonWrapper = new kd.CustomHTMLView
      cssClass: 'button-wrapper'

    @buttonWrapper.addSubView @input = new kd.InputView
      cssClass: 'uploadcsvinput'
      type: 'file'
      attributes:
        accept: '.csv'
      change: @bound 'createFormDataAndRequest'

    @buttonWrapper.addSubView @selectAndUpload = new kd.ButtonView
      cssClass: 'GenericButton select-upload'
      title: 'SELECT AND UPLOAD'
      callback: =>
        @input.getDomElement().click()
        @errorUploading.updatePartial ''


    @buttonWrapper.addSubView @cancelButton = new kd.ButtonView
      cssClass: 'GenericButton cancel'
      title: 'CANCEL'
      callback: @bound 'destroy'

    @buttonWrapper.addSubView @sendAllInvites = new kd.ButtonView
      cssClass: 'GenericButton select-upload hidden'
      callback: @bound 'sendData'


  getLoaderView: ->

    new kd.LoaderView
      cssClass   : 'main-loader'
      showLoader : yes
      size       :
        width    : 25
        height   : 25


  createFormDataAndRequest : () ->

    @formData = new FormData()
    file = @input.getElement().files[0]
    unless file
      return new kd.NotificationView
        title: 'Error! Please Try Again'
        duration: 2000

    @formData.append 'file', file, {
      filename: file.name
      contentType: 'multipart/form-data'
    }

    @setTitle 'Uploading'
    @trailerPage.hide()
    @uploadingPage.show()


    @errorUploading?.hide()

    @uploadingPage.updatePartial "
      <div>
       <p>Selected File: </p>
        #{file.name}
      </div>
    "

    @uploadingPage.addSubView @loader = @getLoaderView()

    @makeReq '/-/teams/invite-by-csv-analyze', 'successAnalyzeCSV', 'errorAnalyzeCSV'

    @input.setValue ''


  makeReq: (url, success, error) ->

    $.ajax
      data : @formData
      method : 'POST'
      url : url
      contentType: false
      processData : false # prs illegal invocation error
      success : @bound success
      error : @bound error


  sendData: ->

    @makeReq '/-/teams/invite-by-csv', 'success', 'error'


  successAnalyzeCSV: (result) ->

    @loader.hide()
    @setTitle 'Send Invitations'

    if typeof result is 'string'
      @sendData()
      return

    @successPage.show()
    @selectAndUpload.hide()
    @sendAllInvites.show()

    @uploadingPage.hide()
    { myself, admins, members, extras } = result

    memberLabel = if members.length > 1 then 'Members' else 'Member'
    adminLabel = if admins.length > 1 then 'Admins' else 'Admin'

    @totalInvitation = admins + members
    @validInvitations = admins + members

    @sendAllInvites.setTitle "SEND #{@validInvitations} INVITES"

    analyzeWrapperClassName = 'wrapper'
    for ex in Object.keys(extras)
      value = extras[ex]
      if value
        analyzeWrapperClassName = 'wrapper-with-extras'
        @totalInvitation = @totalInvitation + value


    @successPage.addSubView label = new kd.CustomHTMLView
      cssClass: 'success-state-label'
      partial: '''
        <p>
            In your file, we have found…
        </p>
      '''

    @successPage.addSubView analyzeCSV = new kd.CustomHTMLView
      cssClass: 'analyzeCSV'
      partial: """
        <div class=#{analyzeWrapperClassName}>
          <div class='total'>
            #{@totalInvitation}</br>
            <label class='total-label'> Total
          </div>
          <div class='members'>
            #{members}</br>
            <label class='members-label'>#{memberLabel}
          </div>
          <div class='admins'>
            #{admins}</br>
            <label class='admins-label'>#{adminLabel}
          </div>
        </div>
      """

    return  unless analyzeWrapperClassName is 'wrapper-with-extras'

    analyzeCSV.addSubView extraInfo = new kd.CustomHTMLView
      cssClass: 'extras-wrapper'
    extraInfo.addSubView secondaryWrapper = new kd.CustomHTMLView
      cssClass: 'secondary-wrapper'
    for ex in Object.keys(extras)
      value = extras[ex]
      if value
        if ex is 'alreadyMembers'
          label = if ex > 1 then 'Already Members' else 'Already Member'
        else if ex is 'notValidInvites'
          label = if ex > 1 then 'Invalid Invites' else 'Invalid Invite'
        else if ex is 'alreadyInvited'
          label = 'Already Invited'
        secondaryWrapper.setPartial """
          <div class='alreadyInvited'>
            #{value}</br>
            <label>
              #{label}
            </label>
          </div>
        """


  errorAnalyzeCSV: (err) ->

    @setTitle 'Something Went Wrong'
    @loader.hide()
    @errorUploading.show()
    @errorUploading.addSubView showError = new kd.CustomHTMLView
      cssClass: 'show-error'
      partial: '''
        It seems that the file you have selected is not formatted right or has no valid data in it.
        </br></br>
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

    @validInvitations = '' unless @validInvitations
    @getOptions().success @validInvitations
    @destroy()
