kd      = require 'kd'
kookies = require 'kookies'
$       = require 'jquery'

RECAPTCHA_CHECK_INTERVAL = 1000 * 60 * 60 * 24 # 1 day
SUBMIT_COUNT_WITHOUT_RECAPTCHA = 3

module.exports = FindTeamHelper =

  getStorageData: ->

    checkDate   = localStorage.findTeamCheckDate
    submitCount = localStorage.findTeamSubmitCount

    if checkDate
      try
        checkDate = new Date checkDate
      catch
        checkDate = null

    checkDate   ?= new Date 1900, 0, 1
    submitCount ?= 0

    return { checkDate, submitCount }


  isRecaptchaRequired: ->

    { checkDate, submitCount } = @getStorageData()

    return new Date() - checkDate < RECAPTCHA_CHECK_INTERVAL and
      submitCount >= SUBMIT_COUNT_WITHOUT_RECAPTCHA


  trackSubmit: ->

    { checkDate, submitCount } = @getStorageData()

    now = new Date()

    if now - checkDate < RECAPTCHA_CHECK_INTERVAL
      submitCount++
    else
      checkDate   = now
      submitCount = 1

    localStorage.setItem 'findTeamCheckDate', checkDate
    localStorage.setItem 'findTeamSubmitCount', submitCount


  submitRequest: (formData, callbacks = {}) ->

    @trackSubmit()

    formData._csrf = Cookies.get '_csrf'
    $.ajax
      url         : '/findteam'
      data        : formData
      type        : 'POST'
      error       : callbacks.error
      success     : callbacks.success
