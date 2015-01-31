class GuidesLinksView extends KDView

  Links      =
    'Firewalls'    : 'http://learn.koding.com/guides/enable-ufw/'
    'ssh'          : 'http://learn.koding.com/guides/ssh-into-your-vm/'
    'sudo'         : 'http://learn.koding.com/faq/what-is-my-sudo-password/'
    'MySQL'        : 'http://learn.koding.com/guides/installing-mysql/'
    'Collaboration': 'http://learn.koding.com/guides/collaboration/'

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'guides-links', options.cssClass

    unless options.partial?

      partial = ""
      for title, link of (options.links ? Links)
        partial += "<a href='#{link}' title='#{title}' target='_blank'>#{title}</a>, "
      partial = partial[...-2]

      options.partial = partial

    super options, data
