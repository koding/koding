kd = require 'kd'
KDHitEnterInputView = kd.HitEnterInputView

module.exports = class NFinderRenameInput extends KDHitEnterInputView
  constructor: (options = {}, data) ->
    super options, data
    @once 'viewAppended', @bound 'selectAll'

  click    : -> no
  dblClick : -> no
