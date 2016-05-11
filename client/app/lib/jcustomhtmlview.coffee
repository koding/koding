kd    = require 'kd'
JView = require './jview'


module.exports = class JCustomHTMLView extends kd.CustomHTMLView

  JView.mixin @prototype
