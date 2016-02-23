$                    = require 'jquery'
kd                   = require 'kd'
KDListViewController = kd.ListViewController


module.exports = class AccountEditorListController extends KDListViewController
  constructor:(options,data)->
    data = $.extend
      items : [
        { title : "Editor settings are coming soon" }
        # { title : "Ace Editor",     extensions : ["html","php","css"],   type : "aceeditor"}
        # { title : "Pixlr Editor",   extensions : ["jpg","png","pxd"],    type : "pixlreditor"}
        # { title : "Pixlr Express",  extensions : ["gif","bmp"],          type : "pixlrexpress"}
        # { title : "CodeMirror",     extensions : ["js","py"],            type : "codemirror"}
      ]
    ,data
    super options,data
