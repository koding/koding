_                  = require 'lodash'
kd                 = require 'kd'
remote             = require('app/remote').getInstance()
KDView             = kd.View
Encoder            = require 'htmlencode'
s3upload           = require 'app/util/s3upload'
showError          = require 'app/util/showError'
showError          = require 'app/util/showError'
geoPattern         = require 'geopattern'
KDFormView         = kd.FormView
KDModalView        = kd.ModalView
KDSelectBox        = kd.SelectBox
KDInputView        = kd.InputView
KDButtonView       = kd.ButtonView
KDToggleButton     = kd.ToggleButton
KDCustomHTMLView   = kd.CustomHTMLView
GroupLogoSettings  = require '../grouplogosettings'
KDNotificationView = kd.NotificationView

module.exports = class GroupGeneralSettingsView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'general-settings-view'

    super options, data

    @forms = {}

    @createGeneralSettingsForm()
    @createAvatarUploadForm()
    # @createDeletionForm()


  createGeneralSettingsForm: ->

    group = @getData()
    url   = if group.slug is 'koding' then '' else "#{group.slug}."

    @addSubView section = @createSection name: 'general-settings'

    section.addSubView form = @generalSettingsForm = new KDFormView

    @addInput form,
      label        : 'Name'
      description  : 'Your team name is displayed in menus and emails. It usually is (or includes) the name of your company.'
      name         : 'title'
      defaultValue : Encoder.htmlDecode group.title ? ''
      placeholder  : 'Please enter a title here'

    @addInput form,
      label        : 'URL'
      description  : 'Changing your team URL is currently not supported, if, for any reason, you must change this please send us an email at support@koding.com.'
      name         : 'url'
      disabled     : yes
      defaultValue : Encoder.htmlDecode group.slug ? ''
      placeholder  : 'Please enter a title here'

    @addInput form,
      label        : 'Default Channels'
      description  : 'Your new members will automatically join to <b>#general</b> channel. Here you can specify more channels for new team members to join automatically.'
      name         : 'channels'
      placeholder  : 'product, design, ux, random etc'
      defaultValue : Encoder.htmlDecode group.defaultChannels?.join(', ') ? ''
      nextElement  : new KDCustomHTMLView
        cssClass   : 'warning-text'
        tagName    : 'span'
        partial    : 'Please add channel names separated by commas.'

    form.addSubView new KDButtonView
      title    : 'Save Changes'
      type     : 'submit'
      cssClass : 'solid medium green'
      callback : @bound 'update'


  createAvatarUploadForm: ->

    @addSubView @uploadSection = section = @createSection
      name : 'avatar-upload'

    section.addSubView @avatar = new KDCustomHTMLView
      cssClass : 'avatar'

    section.addSubView @uploadButton = new KDButtonView
      cssClass : 'compact solid green upload'
      title    : 'UPLOAD IMAGE'
      loader   : yes

    section.addSubView @removeLogoButton = new KDButtonView
      cssClass : 'compact solid black remove'
      title    : 'REMOVE LOGO'
      loader   : yes
      callback : @bound 'removeLogo'

    section.addSubView @uploadInput = new KDInputView
      type       : 'file'
      cssClass   : 'upload-input'
      attributes : accept : 'image/*'
      change     : @bound 'handleUpload'


    logo = @getData().customize?.logo

    if logo then @showLogo logo else @showPattern()


  handleUpload: ->

    @uploadButton.showLoader()

    [file] = @uploadInput.getElement().files

    return @uploadButton.hideLoader()  unless file

    reader        = new FileReader
    reader.onload = (event) =>
      options     =
        mimeType  : file.type
        content   : file

      @uploadAvatar options, => @uploadAvatarBtn.hideLoader()

    reader.readAsDataURL file


  uploadAvatar: (fileOptions, callback) ->

    { mimeType, content } = fileOptions
    group   = kd.singletons.groupsController.getCurrentGroup()
    name    = "#{group.slug}-logo-#{Date.now()}.png"
    timeout = 3e4

    s3upload { name, content, mimeType, timeout }, (err, url) =>

      @uploadButton.hideLoader()

      return showError err   if err

      group.modify { 'customize.logo': url }, => @showLogo url


  showLogo: (url) ->

    @avatar.getElement().style.backgroundImage = "url(#{url})"
    @uploadSection.setClass 'with-logo'


  showPattern: ->

    avatarEl = @avatar.getElement()
    pattern  = geoPattern.generate @getData().slug, generator: 'plusSigns'

    avatarEl.style.backgroundImage = pattern.toDataUrl()
    avatarEl.style.borderColor     = pattern.color
    @uploadSection.unsetClass 'with-logo'


  removeLogo: ->

    @getData().modify { 'customize.logo': '' }, =>
      @showPattern()
      @removeLogoButton.hideLoader()


  createDeletionForm: ->

    @addSubView section = @createSection
      name        : 'deletion'
      description : 'If Koding is no use to your team anymore, you can delete your team page here.'

    section.addSubView form = new KDFormView

    @addInput form,
      itemClass    : KDButtonView
      cssClass     : 'solid medium red'
      description  : 'Note: Don\'t delete your team if you just want to change your team\'s name or URL. You also might want to export your data before deleting your team.'
      title        : 'DELETE TEAM'


  getChannelsArray: ->

    return @generalSettingsForm.getFormData().channels # get input value
      .split ','                                       # split from comma
      .map    (i) -> return i.trim()                   # trim spaces
      .filter (i) -> return i                          # filter empty values


  update: ->

    formData     = @generalSettingsForm.getFormData()
    jGroup       = @getData()
    newChannels  = @getChannelsArray()
    dataToUpdate = {}

    unless formData.title is jGroup.title
      dataToUpdate.title = formData.title

    unless _.isEqual newChannels, jGroup.defaultChannels
      dataToUpdate.defaultChannels = newChannels

    return if _.isEmpty dataToUpdate

    jGroup.modify dataToUpdate, (err, result) =>
      message  = 'Group settings has been successfully updated.'

      if err
        message  = 'Couldn\'t update group settings. Please try again'
        kd.warn err

      new KDNotificationView title: message, duration: 5000


  createSection: (options = {}) ->

    { name, title, description } = options

    section = new KDCustomHTMLView
      tagName  : 'section'
      cssClass : kd.utils.curry 'AppModal-section', name

    section.addSubView desc = new KDCustomHTMLView
      tagName  : 'p'
      cssClass : 'AppModal-sectionDescription'
      partial  : description

    return section


  addInput: (form, options) ->

    { name, label, description, itemClass, nextElement } = options

    itemClass  or= KDInputView
    form.inputs ?= {}

    form.addSubView field = new KDCustomHTMLView tagName : 'fieldset'

    if label
      field.addSubView labelView = new KDCustomHTMLView
        tagName : 'label'
        for     : name
        partial : label
      options.label = labelView

    field.addSubView form.inputs[name] = input = new itemClass options
    field.addSubView new KDCustomHTMLView tagName : 'p', partial : description  if description

    field.addSubView nextElement  if nextElement and nextElement instanceof KDView

    return input
