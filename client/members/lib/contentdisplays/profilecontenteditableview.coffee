kd = require 'kd'
KDContentEditableView = kd.ContentEditableView
JView = require 'app/jview'


module.exports = class ProfileContentEditableView extends KDContentEditableView
  JView.mixin @prototype
