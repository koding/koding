_              = require 'lodash'
kd             = require 'kd'
Encoder        = require 'htmlencode'
validator      = require 'validator'
s3upload       = require 'app/util/s3upload'
showError      = require 'app/util/showError'
showError      = require 'app/util/showError'
JView          = require 'app/jview'
CustomLinkView = require 'app/customlinkview'
LOGO_PATH      = '/a/images/logos/sidebar_footer_logo.svg'

notify = (title, duration = 5000) -> new kd.NotificationView { title, duration }

separateCommas = (value) ->

  # split from comma then trim spaces then filter empty values
  return value.split ','
    .map    (i) -> return i.trim()
    .filter (i) -> return i


module.exports = class HomeTeamSettings extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    @_canEdit = kd.singletons.groupsController.canEditGroup()
    team      = @getData()
    url       = if team.slug is 'koding' then '' else "#{team.slug}."

    @teamName = new kd.InputView
      name         : 'title'
      cssClass     : 'name'
      defaultValue : Encoder.htmlDecode team.title ? ''

    @teamDomain = new kd.InputView
      name         : 'url'
      disabled     : yes
      defaultValue : "#{Encoder.htmlDecode team.slug}.koding.com" ? ''

    # @teamDomains = new kd.InputView
    #   name         : 'domains'
    #   placeholder  : 'domain.com, other.edu'
    #   defaultValue : Encoder.htmlDecode team.allowedDomains?.join(', ') ? ''

    @save  = new CustomLinkView
      cssClass : "HomeAppView--button primary#{unless @canEditGroup then ' hidden' else ''}"
      title    : 'SAVE'
      click    : @bound 'update'

    @delete  = new CustomLinkView
      cssClass : 'HomeAppView--button'
      title    : 'DELETE TEAM'
      # click    : @bound 'deleteTeam'

    @logo = new kd.CustomHTMLView
      tagName    : 'img'
      cssClass   : 'teamLogo'
      attributes : { src: team.customize?.logo or LOGO_PATH }
      click      : => @uploadInput.$().click()


    @uploadLogo = new CustomLinkView
      cssClass : 'HomeAppView--button primary'
      title    : 'UPLOAD LOGO'
      click      : => @uploadInput.$().click()
      # click    : @bound 'deleteTeam'

    @removeLogo = new CustomLinkView
      cssClass : 'HomeAppView--button'
      title    : 'REMOVE'
      click    : @bound 'removeLogo'

    @uploadInput = new kd.InputView
      type       : 'file'
      attributes : { accept : 'image/*' }
      change     : @bound 'handleUpload'


  handleUpload: ->

    [file] = @uploadInput.getElement().files

    return  unless file

    reader        = new FileReader
    reader.onload = (event) =>
      @upload
        mimeType : file.type
        content  : file

    reader.readAsDataURL file


  upload: (fileOptions, callback) ->

    { mimeType, content } = fileOptions

    team    = @getData()
    name    = "#{team.slug}-logo-#{Date.now()}.png"
    timeout = 3e4

    s3upload { name, content, mimeType, timeout }, (err, url) =>

      return showError err   if err

      team.modify { 'customize.logo': url }, =>
        @logo.setAttribute 'src', url or LOGO_PATH


  removeLogo: ->

    @getData().modify { 'customize.logo': '' }, =>
      @logo.setAttribute 'src', LOGO_PATH
      @uploadInput.setValue ''


  createDeletionForm: ->

    @addSubView section = @createSection
      name        : 'deletion'
      description : 'If Koding is no use to your team anymore, you can delete your team page here.'

    section.addSubView form = new kd.FormView

    @addInput form,
      itemClass    : kd.ButtonView
      cssClass     : 'solid medium red'
      description  : 'Note: Don\'t delete your team if you just want to change your team\'s name or URL. You also might want to export your data before deleting your team.'
      title        : 'DELETE TEAM'


  update: ->

    team         = @getData()
    dataToUpdate = {}
    # newDomains   = separateCommas domains

    unless @teamName.getValue() is team.title
      dataToUpdate.title = formData.title

    # unless _.isEqual newDomains, team.allowedDomains
    #   for domain in newDomains when not validator.isURL domain
    #     return notify 'Please check allowed domains again'
    #   dataToUpdate.allowedDomains = newDomains

    return if _.isEmpty dataToUpdate

    team.modify dataToUpdate, (err, result) =>
      message  = 'Team settings has been successfully updated.'

      if err
        message  = 'Couldn\'t update team settings. Please try again'
        kd.warn err

      notify message


  pistachio: ->

    """
    <div class='HomeAppView--uploadLogo'>
      {{> @logo}}
      <div class='uploadInputWrapper'>
        {{> @uploadLogo}}
        {{> @removeLogo}}
        {{> @uploadInput}}
      </div>
    </div>
    <form>
      <fieldset class='half'>
        <label>Team Name</label>
        {{> @teamName}}
      </fieldset>
      <fieldset class='half'>
        <label>Koding URL</label>
        {{> @teamDomain }}
      </fieldset>
      <fieldset>
        {{> @delete}}
        {{> @save}}
      </fieldset>
    </form>
    """
