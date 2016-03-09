kd             = require 'kd'
KDView         = kd.View
globals        = require 'globals'
KDSelectBox    = kd.SelectBox
KDLabelView    = kd.LabelView
KDHeaderView   = kd.HeaderView

AccountSessionList           = require './accountsessionlist'
AccountSessionListController = require './views/accountsessionlistcontroller'


module.exports = class AccountSessionListWrapper extends KDView

  constructor: (options = {}, data) ->

    super options, data

    @addSubView @top = new KDView
      cssClass : 'top'

    @top.addSubView @header = new KDHeaderView
      title : 'Active Sessions'

    @listController = new AccountSessionListController
      view                    : new AccountSessionList
      limit                   : 8
      useCustomScrollView     : yes
      lazyLoadThreshold       : 8

    @addSubView @listController.getView()


