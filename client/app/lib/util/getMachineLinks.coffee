Machine = require 'app/remote-extensions/machine'

module.exports = getMachineLinks = (machine, type) ->

  links =
    ide: -> getIDEUrl machine
    dashboard: -> getDashboardUrl machine

  return links[type]()  if type

  return {
    ide: links.ide()
    dashboard: links.dashboard()
  }


getIDEUrl = (machine) ->

  { Own, Shared, Reassigned, Collaboration } = Machine.Type

  switch machine.getType()
    when Own then "/IDE/#{machine.slug or machine.label}"
    when Collaboration then "/IDE/#{machine.uid}"
    when Shared, Reassigned then "/IDE/#{machine.uid}"
    else ''

getDashboardUrl = (machine) -> "/Home/stacks/virtual-machines/#{machine.getId()}"
