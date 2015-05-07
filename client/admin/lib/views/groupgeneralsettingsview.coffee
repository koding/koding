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

    section.addSubView form = new KDFormView #callback : @bound 'saveSettings'

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
      callback : -> console.log 'lolooloo'


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

















  # createFormFields: (formOptions) ->

  #   group              = @getData()
  #   formOptions.fields = {}

  #   if group.slug isnt "koding"
  #     formOptions.fields.Logo =
  #       label                 : "Logo"
  #       itemClass             : GroupLogoSettings

  #   formOptions.fields.Title  =
  #     label                   : "Group Name"
  #     name                    : "title"
  #     defaultValue            : Encoder.htmlDecode group.title ? ""
  #     placeholder             : 'Please enter a title here'

  #   formOptions.fields.Description =
  #     label                   : "Description"
  #     type                    : "textarea"
  #     name                    : "body"
  #     defaultValue            : Encoder.htmlDecode group.body ? ""
  #     placeholder             : 'Please enter a description here.'
  #     autogrow                : yes

  #   formOptions.fields.Stack =
  #     itemClass               : KDSelectBox
  #     label                   : "Stack"
  #     type                    : "select"
  #     name                    : "stackTemplates"
  #     selectOptions           : [
  #       { title: "Loading stack templates...", disabled: yes }
  #     ]
  #     nextElement             :
  #       showTemplate          :
  #         itemClass           : KDButtonView
  #         title               : "Show Template"
  #         cssClass            : "solid green mini hidden"
  #         callback            : =>

  #           { Stack } = @settingsForm.inputs
  #           data = @_templates["_#{Stack.getValue()}"]
  #           return new KDNotificationView title: "No data found!"  unless data

  #           { title, description, rules, domains, machines, extras } = data
  #           data = { title, description, rules, domains, machines, extras }

  #           try
  #             parsed = JSON.stringify data, null, 2
  #           catch e
  #             kd.warn e; kd.log data
  #             return new KDNotificationView
  #               title: "An error occurred"

  #           new KDModalView
  #             content : "<pre>#{parsed}</pre>"


  #   formOptions.fields["Visibility settings"] =
  #     itemClass               : KDSelectBox
  #     label                   : "Visibility"
  #     type                    : "select"
  #     name                    : "visibility"
  #     defaultValue            : group.visibility ? "visible"
  #     selectOptions           : [
  #       { title : "Visible"   , value : "visible" }
  #       { title : "Hidden"    , value : "hidden"  }
  #     ]

  # createFormButtons: (formOptions) ->
  #   formOptions.buttons   =
  #     Save                :
  #       style             : "solid medium green"
  #       type              : "submit"
  #       loader            : yes

  # saveSettings: (formData) ->
  #   saveButton = @settingsForm.buttons.Save
  #   group      = @getData()

  #   if formData.stackTemplates is "none"
  #     formData.stackTemplates = [ ]
  #   else if not formData.stackTemplates?
  #     delete formData.stackTemplates
  #   else
  #     formData.stackTemplates = [ formData.stackTemplates ]

  #   group.modify formData, (err)->
  #     saveButton.hideLoader()
  #     return showError err if err

  #     new KDNotificationView
  #       title    : "Group settings saved"
  #       type     : "mini"
  #       cssClass : "success"
  #       duration : 4000

  # viewAppended:->
  #   super

  #   { stackTemplates } = @getData()
  #   { Stack } = @settingsForm.inputs

  #   remote.api.JStackTemplate.some {}, (err, templates)=>

  #     Stack.removeSelectOptions()

  #     if err

  #       Stack.setSelectOptions "Failed to fetch templates": []
  #       kd.warn err

  #     else if templates.length is 0

  #       Stack.setSelectOptions "No template available": []

  #     else

  #       @_templates   = {}
  #       selectOptions = []

  #       for t in templates
  #         selectOptions.push { title:t.title, value:t._id }
  #         @_templates["_#{t._id}"] = t

  #       selectOptions.push title: "Do not create anything.", value: "none"

  #       Stack.setSelectOptions "Select stack template..." : selectOptions

  #       showButton = @settingsForm.inputs["Show Template"]
  #       showButton.setCss margin: "7px"
  #       showButton.show()

  #       if stackTemplates?.length > 0
  #         Stack.setDefaultValue stackTemplates.first
  #       else
  #         Stack.setDefaultValue "none"
