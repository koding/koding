kd               = require 'kd'
KDView           = kd.View
KDCustomHTMLView = kd.CustomHTMLView


module.exports = class MachineSettingsGuidesView extends KDView

  Guides = [
    {
      title : 'Making your VM secure using Ubuntu UFW'
      link  : 'http://learn.koding.com/guides/enable-ufw/'
    }
    {
      title : 'Connect with SSH, from Unix'
      link  : 'http://learn.koding.com/guides/ssh-into-your-vm/'
    }
    {
      title : 'Getting started with the Koding Package Manager'
      link  : 'http://learn.koding.com/guides/getting-started-kpm/'
    }
    {
      title : 'Installing MySQL'
      link  : 'http://learn.koding.com/guides/installing-mysql/'
    }
    {
      title : 'How can I do real-time collaboration on Koding?'
      link  : 'http://learn.koding.com/guides/collaboration/'
    }
  ]


  constructor: (options = {}, data) ->

    options.cssClass = 'guides AppModal-form'

    super options, data

    if @getData().isManaged()
      Guides[0] =
        title : 'Learn more about connecting your own VM'
        link  : 'http://learn.koding.com/guides/connect-your-vm/'

      Guides.splice 1, 2

    for guide in Guides
      @addSubView new KDCustomHTMLView
        cssClass : 'guide formline'
        partial  : "- <a href='#{guide.link}' target='_blank'>#{guide.title}</a>"
