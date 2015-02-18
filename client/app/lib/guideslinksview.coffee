kd = require 'kd'
KDView = kd.View
module.exports = class GuidesLinksView extends KDView

  Links      =
    'Firewalls'    : 'http://learn.koding.com/guides/enable-ufw/'
    'ssh'          : 'http://learn.koding.com/guides/ssh-into-your-vm/'
    'kpm'          : 'http://learn.koding.com/guides/getting-started-kpm/'
    'MySQL'        : 'http://learn.koding.com/guides/installing-mysql/'
    'Collaboration': 'http://learn.koding.com/guides/collaboration/'

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'guides-links', options.cssClass

    unless options.partial?

      partial = ""
      for title, link of (options.links ? Links)
        partial += "<a href='#{link}' title='#{title}' target='_blank'>#{title}</a>, "
      partial = partial[...-2]

      options.partial = partial

    super options, data
