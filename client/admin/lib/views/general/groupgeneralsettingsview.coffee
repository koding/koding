_                  = require 'lodash'
kd                 = require 'kd'
KDView             = kd.View
KDCustomScrollView = kd.CustomScrollView
Encoder            = require 'htmlencode'
s3upload           = require 'app/util/s3upload'
showError          = require 'app/util/showError'
validator          = require 'validator'
showError          = require 'app/util/showError'
geoPattern         = require 'geopattern'
KDFormView         = kd.FormView
KDInputView        = kd.InputView
KDButtonView       = kd.ButtonView
KDCustomHTMLView   = kd.CustomHTMLView
KDNotificationView = kd.NotificationView


module.exports = class GroupGeneralSettingsView extends KDCustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass = 'general-settings-view'

    super options, data

    @forms = {}

    @_canEditGroup = kd.singletons.groupsController.canEditGroup()

    @createGeneralSettingsForm()
    @createAvatarUploadForm()  if @_canEditGroup
    # @createDeletionForm()


  createGeneralSettingsForm: ->

    group = @getData()
    url   = if group.slug is 'koding' then '' else "#{group.slug}."

    @wrapper.addSubView section = @createSection { name: 'general-settings' }

    section.addSubView form = @generalSettingsForm = new KDFormView

    @addInput form,
      label        : 'Name'
      description  : 'Your team name is displayed in menus and emails. It usually is (or includes) the name of your company.'
      name         : 'title'
      cssClass     : 'name'

      defaultValue : Encoder.htmlDecode group.title ? ''
      placeholder  : 'Please enter a title here'

    @addInput form,
      label        : 'URL'
      description  : 'Changing your team URL is currently not supported, if, for any reason, you must change this please send us an email at support@koding.com.'
      name         : 'url'
      disabled     : yes
      defaultValue : Encoder.htmlDecode group.slug ? ''
      placeholder  : 'Please enter a title here'

    # @addInput form,
    #   label        : 'Default Channels'
    #   description  : 'Your new members will automatically join to <b>#general</b> channel. Here you can specify more channels for new team members to join automatically.'
    #   name         : 'channels'
    #   placeholder  : 'product, design, ux, random etc'
    #   defaultValue : Encoder.htmlDecode group.defaultChannels?.join(', ') ? ''
    #   nextElement  : new KDCustomHTMLView
    #     cssClass   : 'warning-text'
    #     tagName    : 'span'
    #     partial    : 'Please add channel names separated by commas.'

    # @addInput form,
    #   label        : 'Allowed Domains'
    #   description  : 'Allow anyone to sign up with an email address from a domain you specify here. If you need to enter multiple domains, please separate them by commas. e.g. acme.com, acme-inc.com'
    #   name         : 'domains'
    #   placeholder  : 'domain.com, other.edu'
    #   defaultValue : Encoder.htmlDecode group.allowedDomains?.join(', ') ? ''

    if @_canEditGroup
      form.addSubView new KDButtonView
        title    : 'Save Changes'
        type     : 'submit'
        cssClass : 'solid medium green'
        callback : @bound 'update'


  createAvatarUploadForm: ->

    @wrapper.addSubView @uploadSection = section = @createSection
      name : 'avatar-upload'

    section.addSubView @avatar = new KDCustomHTMLView
      cssClass : 'avatar'

    section.addSubView @uploadButton = new KDButtonView
      cssClass : 'compact solid green upload'
      title    : 'UPLOAD LOGO'
      loader   : yes

    section.addSubView @removeLogoButton = new KDButtonView
      cssClass : 'compact solid black remove'
      title    : 'REMOVE LOGO'
      loader   : yes
      callback : @bound 'removeLogo'

    section.addSubView @uploadInput = new KDInputView
      type       : 'file'
      cssClass   : 'upload-input'
      attributes : { accept : 'image/*' }
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
    pattern  = geoPattern.generate @getData().slug, { generator: 'plusSigns' }

    avatarEl.style.backgroundImage = pattern.toDataUrl()
    @uploadSection.unsetClass 'with-logo'


  removeLogo: ->

    @getData().modify { 'customize.logo': '' }, =>
      @showPattern()
      @removeLogoButton.hideLoader()
      @uploadInput.setValue ''


  createDeletionForm: ->

    @wrapper.addSubView section = @createSection
      name        : 'deletion'
      description : 'If Koding is no use to your team anymore, you can delete your team page here.'

    section.addSubView form = new KDFormView

    @addInput form,
      itemClass    : KDButtonView
      cssClass     : 'solid medium red'
      description  : 'Note: Don\'t delete your team if you just want to change your team\'s name or URL. You also might want to export your data before deleting your team.'
      title        : 'DELETE TEAM'


  separateCommas: (value) ->

    # split from comma then trim spaces then filter empty values
    return value.split ','
      .map    (i) -> return i.trim()
      .filter (i) -> return i


  update: ->

    # { channels, domains } = @generalSettingsForm.getFormData()
    { domains } = @generalSettingsForm.getFormData()

    formData     = @generalSettingsForm.getFormData()
    jGroup       = @getData()
    # newChannels  = @separateCommas channels
    # newDomains   = @separateCommas domains
    dataToUpdate = {}

    unless formData.title is jGroup.title
      dataToUpdate.title = formData.title

    # unless _.isEqual newChannels, jGroup.defaultChannels
    #   dataToUpdate.defaultChannels = newChannels

    # unless _.isEqual newDomains, jGroup.allowedDomains
    #   for domain in newDomains when not validator.isURL domain
    #     return @notify 'Please check allowed domains again'

    #   dataToUpdate.allowedDomains = newDomains

    return if _.isEmpty dataToUpdate

    jGroup.modify dataToUpdate, (err, result) =>
      message  = 'Group settings has been successfully updated.'

      if err
        message  = 'Couldn\'t update group settings. Please try again'
        kd.warn err

      @notify message


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

    form.addSubView field = new KDCustomHTMLView { tagName : 'fieldset' }

    if label
      field.addSubView labelView = new KDCustomHTMLView
        tagName : 'label'
        for     : name
        partial : label
      options.label = labelView

    field.addSubView form.inputs[name] = input = new itemClass options
    field.addSubView new KDCustomHTMLView { tagName : 'p', partial : description }  if description

    field.addSubView nextElement  if nextElement and nextElement instanceof KDView

    return input


  notify: (title, duration = 5000) ->

    new KDNotificationView { title, duration }
