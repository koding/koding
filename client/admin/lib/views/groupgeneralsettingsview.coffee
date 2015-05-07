_                  = require 'lodash'
kd                 = require 'kd'
KDView             = kd.View
KDFormView         = kd.FormView
KDInputView        = kd.InputView
KDCustomHTMLView   = kd.CustomHTMLView
KDToggleButton     = kd.ToggleButton
KDButtonView       = kd.ButtonView
KDModalView        = kd.ModalView
KDNotificationView = kd.NotificationView
KDSelectBox        = kd.SelectBox
GroupLogoSettings  = require '../grouplogosettings'
remote             = require('app/remote').getInstance()
showError          = require 'app/util/showError'
Encoder            = require 'htmlencode'


createSection = (options = {}) ->

  { name, title, description } = options

  section = new KDCustomHTMLView
    tagName  : 'section'
    cssClass : kd.utils.curry 'AppModal-section', name

  section.addSubView desc = new KDCustomHTMLView
    tagName  : 'p'
    cssClass : 'AppModal-sectionDescription'
    partial  : description

  return section


addInput = (form, options) ->

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

addButton = (form, options) ->

  { title, callback } = options

  form.addSubView new KDButtonView {
    title
    callback
    type     : 'submit'
    cssClass : 'solid medium green'
  }


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

    @addSubView section = createSection name: 'general-settings'

    section.addSubView form = @generalSettingsForm = new KDFormView

    addInput form,
      label        : 'Name'
      description  : 'Your team name is displayed in menus and emails. It usually is (or includes) the name of your company.'
      name         : 'title'
      defaultValue : Encoder.htmlDecode group.title ? ''
      placeholder  : 'Please enter a title here'

    addInput form,
      label        : 'URL'
      description  : 'Changing your team URL is currently not supported, if, for any reason, you must change this please send us an email at support@koding.com.'
      name         : 'url'
      disabled     : yes
      defaultValue : Encoder.htmlDecode group.slug ? ''
      placeholder  : 'Please enter a title here'

    addInput form,
      label        : 'Default Channels'
      description  : 'Your new members will automatically join to <b>#general</b> channel. Here you can specify more channels for new team members to join automatically.'
      name         : 'channels'
      placeholder  : 'product, design, ux, random etc'
      nextElement  : new KDCustomHTMLView
        cssClass   : 'warning-text'
        tagName    : 'span'
        partial    : 'Please add channel names separated by commas.'

    addButton form,
      title    : 'Save Changes'
      callback : @bound 'update'


  createAvatarUploadForm: ->

    @addSubView section = createSection
      name : 'avatar-upload'

    section.addSubView new KDCustomHTMLView
      cssClass : 'avatar'

    section.addSubView new KDButtonView
      cssClass : 'compact solid green upload'
      title    : 'UPLOAD IMAGE'


  createDeletionForm: ->

    @addSubView section = createSection
      name        : 'deletion'
      description : 'If Koding is no use to your team anymore, you can delete your team page here.'

    section.addSubView form = new KDFormView

    addInput form,
      itemClass    : KDButtonView
      cssClass     : 'solid medium red'
      description  : 'Note: Don\'t delete your team if you just want to change your team\'s name or URL. You also might want to export your data before deleting your team.'
      title        : 'DELETE TEAM'


  update: ->

    formData     = @generalSettingsForm.getFormData()
    jGroup       = @getData()
    dataToUpdate = {}

    if formData.title isnt jGroup.title
      dataToUpdate.title = formData.title

    return if _.isEmpty dataToUpdate

    jGroup.modify dataToUpdate, (err, result) =>
      message  = 'Group settings has been successfully updated.'

      if err
        message  = 'Couldn\'t update group settings. Please try again'
        kd.warn err

      new KDNotificationView title: message, duration: 5000
