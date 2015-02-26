keyBindings = [
  { command: 'ring bell', binding: 'alt+meta+k', global: yes, readonly: no, description: 'Ring Bell' }
  { command: 'noop', binding: ['meta+v','meta+r'], global: yes, readonly: yes, description: null, hidden: true }
]

_ = require 'underscore'

out = []

for val in keyBindings
  binding = null
  unless Array.isArray val.binding
    j = val.binding
    binding = [[j.replace('meta', 'ctrl')], [j.replace('meta', 'command')]]
  else
    c = [[], []]
    _.each val.binding, (j) ->
      c[0].push j.replace('meta', 'ctrl')
      c[1].push j.replace('meta', 'command')
    binding = c

  obj =
    name: 't#' + val.command.replace(' ', '')
    description: val.description
    binding: binding
    readonly: val.readonly
    enabled: yes
    hidden: val.hidden or false
    options:
      mousetrap:
        global: val.global

  out.push obj

console.log JSON.stringify out, null, 2
