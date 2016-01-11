kd              = require 'kd'
showError       = require 'app/util/showError'
KDModalView     = kd.ModalView
KDButtonView    = kd.ButtonView
applyMarkdown   = require 'app/util/applyMarkdown'
objectToString  = require 'app/util/objectToString'


module.exports = class MetaInfoButtonView extends KDButtonView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'troll-button', options.cssClass
    options.title    = "Info"
    options.callback = ->

      data.fetchMetaInformation (err, info)->

        return if showError err

        info = objectToString info,
          separator : "  "
          maxDepth  : 100

        colorized = applyMarkdown "```json \n#{info}\n```"

        new KDModalView
          cssClass : 'meta-info-modal has-markdown'
          title    : "Information of #{data.profile.nickname}"
          content  : colorized
          overlay  : yes

    super options
