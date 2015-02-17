kd = require 'kd'
KDModalView = kd.ModalView
module.exports = class EnvironmentApprovalModal extends KDModalView

  getContentFor = (items, action)->
    content     = 'God knows.'

    titles = {}
    for title in ['domain', 'machine', 'rule', 'extra']
      titles[title] = items[title].dia.getData().title  if items[title]

    if action is 'create'

      if titles.domain? and titles.machine?
        content = """Do you want to assign <b>#{titles.domain}</b>
                     to <b>#{titles.machine}</b> machine?"""
      else if titles.domain? and titles.rule?
        content = """Do you want to enable <b>#{titles.rule}</b> rule
                     for <b>#{titles.domain}</b> domain?"""
      else if titles.machine? and titles.extra?
        content = """Do you want to add <b>#{titles.extra}</b>
                     to <b>#{titles.machine}</b> machine?"""

    else if action is 'delete'

      if titles.domain? and titles.machine?
        content = """Do you want to remove <b>#{titles.domain}</b>
                     domain from <b>#{titles.machine}</b> machine?"""
      else if titles.domain? and titles.rule?
        content = """Do you want to disable <b>#{titles.rule}</b> rule
                     for <b>#{titles.domain}</b> domain?"""
      else if titles.machine? and titles.extra?
        content = """Do you want to remove <b>#{titles.extra}</b>
                     from <b>#{titles.machine}</b> machine?"""

    return "<div class='modalformline'><p>#{content}</p></div>"

  constructor:(options={}, data)->

    options.title       or= "Are you sure?"
    options.overlay      ?= yes
    options.overlayClick ?= no
    options.buttons       =
      Yes                 :
        loader            :
          color           : "#444444"
        cssClass          : if options.action is 'delete' \
                            then "modal-clean-red" else "modal-clean-green"
        callback          : =>
          @buttons.Yes.showLoader()
          @emit 'Approved'
      Cancel              :
        cssClass          : "modal-cancel"
        callback          : =>
          @emit 'Cancelled'
          @cancel()

    options.content = getContentFor data, options.action

    super options, data
