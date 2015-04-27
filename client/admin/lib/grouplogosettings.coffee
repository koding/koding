InlineImageSettings = require './views/inlineimagesettings'


module.exports = class GroupLogoSettings extends InlineImageSettings
  constructor: (options = {}, data) ->
    options = uploaderTitle: "Drop your 55x55 logo here!"
    super options, data

