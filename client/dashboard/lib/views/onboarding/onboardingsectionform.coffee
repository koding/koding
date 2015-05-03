kd = require 'kd'
KDFormViewWithFields = kd.FormViewWithFields
KDSelectBox = kd.SelectBox
globals = require 'globals'
KodingSwitch = require 'app/commonviews/kodingswitch'
CustomPartialHelpers = require 'dashboard/custompartialhelpers'
OnboardingEvent = require 'app/onboarding/onboardingevent'
OnboardingEventName = require './onboardingeventname'

module.exports = class OnboardingSectionForm extends KDFormViewWithFields

  ###*
   * Form view to edit onboarding group
  ###
  constructor: (options = {}, data) ->

    groups = []
    groups.push { title: OnboardingEventName[event], value: event }  for event of OnboardingEvent

    options.cssClass      = "section-form"
    @jCustomPartial       = data
    formData              = data?.partial or {}
    options.fields        =
      event               :
        name              : "event"
        label             : "Initiator Event"
        type              : 'hidden'
        nextElement       :
          event           :
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


  ###*
   * Collects onboarding group data on the form
   * and saves it in DB. After that, emits event for the parent view
   *
   * @emits SectionSaved
  ###
  save: ->

    data              =
      partialType     : "ONBOARDING"
      partial         :
        visibility    : no
        overlay       : yes
        items         : @jCustomPartial?.partial.items   or []
      name            : @inputs.event.getValue()         or ""
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
      CustomPartialHelpers.createPartial data, (err, section) =>
        @emit "SectionSaved"
        @destroy()


  ###*
   * Cancelling onboarding editing destroys the form
   * and emits event for the parent view
   *
   * @emits SectionCancelled
  ###
  cancel: ->

    @emit "SectionCancelled"
    @destroy()
