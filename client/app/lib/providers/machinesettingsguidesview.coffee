kd               = require 'kd'
KDView           = kd.View
KDCustomHTMLView = kd.CustomHTMLView


module.exports = class MachineSettingsGuidesView extends KDView

  Guides = [
    {
      title : 'Making your VM secure using Ubuntu UFW'
      link  : 'https://koding.com/docs/enable-ufw/'
    }
    {
      title : 'Connect with SSH, from Unix'
      link  : 'https://koding.com/docs/ssh-into-your-vm/'
    }
    {
      title : 'Getting started with the Koding Package Manager'
      link  : 'https://koding.com/docs/getting-started-kpm/'
    }
    {
      title : 'Installing MySQL'
      link  : 'https://koding.com/docs/installing-mysql/'
    }
    {
      title : 'How can I do real-time collaboration on Koding?'
      link  : 'https://koding.com/docs/collaboration/'
    }
  ]


  constructor: (options = {}, data) ->

    options.cssClass = 'guides AppModal-form'

    super options, data

    if @getData().isManaged()
      Guides[0] =
        title : 'Learn more about connecting your own VM'
        link  : 'https://koding.com/docs/connect-your-machine/'

      Guides.splice 1, 2

    for guide in Guides
      @addSubView new KDCustomHTMLView
        cssClass : 'guide formline'
        partial  : "- <a href='#{guide.link}' target='_blank'>#{guide.title}</a>"
