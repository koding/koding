kd = require 'kd'
KDView = kd.View
module.exports = class GuidesLinksView extends KDView

  Links      =
    'Firewalls'    : 'https://koding.com/docs/enable-ufw/'
    'ssh'          : 'https://koding.com/docs/ssh-into-your-vm/'
    'kpm'          : 'https://koding.com/docs/getting-started-kpm/'
    'MySQL'        : 'https://koding.com/docs/installing-mysql/'
    'Collaboration': 'https://koding.com/docs/collaboration/'

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'guides-links', options.cssClass

    unless options.partial?

      partial = ""
      for title, link of (options.links ? Links)
        partial += "<a href='#{link}' title='#{title}' target='_blank'>#{title}</a>, "
      partial = partial[...-2]

      options.partial = partial

    super options, data
