$ = require 'jquery'
getFullnameFromAccount = require '../../util/getFullnameFromAccount'
kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
JView = require '../../jview'


module.exports = class MemberMailLink extends KDCustomHTMLView

  JView.mixin @prototype

  constructor:(options, data)->
    options = $.extend
      tagName     : 'a'
      attributes  :
        href        : '#'
    , options
    super options, data

  pistachio:->
    name = getFullnameFromAccount @getData(), yes
    "<cite/><span>Contact #{name}</span>"

  click:(event)->

    event.preventDefault()
    {profile} = member = @getData()

    kd.getSingleton("appManager").tell "Inbox", "createNewMessageModal", [member]
