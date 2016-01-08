kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
JView = require './jview'


module.exports = class JCustomHTMLView extends KDCustomHTMLView

  JView.mixin @prototype
