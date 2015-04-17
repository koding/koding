kd = require 'kd'
KDFormViewWithFields = kd.FormViewWithFields
KDSelectBox = kd.SelectBox
remote = require('app/remote').getInstance()
globals = require 'globals'
KodingSwitch = require 'app/commonviews/kodingswitch'


module.exports = class OnboardingSectionForm extends KDFormViewWithFields

  constructor: (options = {}, data) ->

    groups = [
      title: 'IDE', value: 'IDE'
    ]

    options.cssClass      = "section-form"
    @jCustomPartial       = data
    formData              = data?.partial or {}
    options.fields        =
      type                :
        name              : "type"
        label             : "Type"
        type              : 'hidden'
        nextElement       :
          type            :
            itemClass     : KDSelectBox
            defaultValue  : data?.name
            selectOptions : groups

    options.buttons       =
      Save                :
        title             : "SAVE CHANGES"
        style             : "solid green medium fr"
        callback          : @bound "save"
      Cancel              :
        title             : "CANCEL"
        style             : "solid medium fr cancel"
        callback          : @bound "cancel"

    super options, data


  save: ->

    data              =
      partialType     : "ONBOARDING"
      partial         :
        visibility    : no
        overlay       : yes
        items         : @jCustomPartial?.partial.items   or []
      name            : @inputs.type.getValue()          or ""
      viewInstance    : @jCustomPartial?.viewInstance    or ""
      isActive        : @jCustomPartial?.isActive        or no
      isPreview       : @jCustomPartial?.isPreview       or no
      previewInstance : @jCustomPartial?.previewInstance or no

    if @jCustomPartial
      @jCustomPartial.update data, (err, section) =>
        return kd.warn err  if err
        @emit "SectionSaved"
        @destroy()
    else
      remote.api.JCustomPartials.create data, (err, section) =>
        return kd.warn err  if err
        @emit "SectionSaved"
        @destroy()


  cancel: ->

    @emit "SectionCancelled"
    @destroy()
