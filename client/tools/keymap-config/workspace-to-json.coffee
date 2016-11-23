keyBindings = [
    { command: 'find file by name',   binding: 'ctrl+alt+o',           global: yes }
    { command: 'search all files',    binding: 'ctrl+alt+f',           global: yes }
    { command: 'split vertically',    binding: 'ctrl+alt+v',           global: yes }
    { command: 'split horizontally',  binding: 'ctrl+alt+h',           global: yes }
    { command: 'merge splitview',     binding: 'ctrl+alt+m',           global: yes }
    { command: 'preview file',        binding: 'ctrl+alt+p',           global: yes }
    { command: 'save all files',      binding: 'ctrl+alt+s',           global: yes }
    { command: 'create new file',     binding: 'ctrl+alt+n',           global: yes }
    { command: 'create new terminal', binding: 'ctrl+alt+t',           global: yes }
    { command: 'create new browser',  binding: 'ctrl+alt+b',           global: yes }
    { command: 'create new drawing',  binding: 'ctrl+alt+d',           global: yes }
    { command: 'toggle sidebar',      binding: 'ctrl+alt+k',           global: yes }
    { command: 'close tab',           binding: 'ctrl+alt+w',           global: yes }
    { command: 'go to left tab',      binding: 'ctrl+alt+[',           global: yes }
    { command: 'go to right tab',     binding: 'ctrl+alt+]',           global: yes }
    { command: 'go to tab number1',    binding: 'mod+1',                global: yes }
    { command: 'go to tab number2',    binding: 'mod+2',                global: yes }
    { command: 'go to tab number3',    binding: 'mod+3',                global: yes }
    { command: 'go to tab number4',    binding: 'mod+4',                global: yes }
    { command: 'go to tab number5',    binding: 'mod+5',                global: yes }
    { command: 'go to tab number6',    binding: 'mod+6',                global: yes }
    { command: 'go to tab number7',    binding: 'mod+7',                global: yes }
    { command: 'go to tab number8',    binding: 'mod+8',                global: yes }
    { command: 'go to tab number9',    binding: 'mod+9',                global: yes }
    { command: 'fullscreen',   binding: 'mod+shift+enter',      global: yes }
    { command: 'move tab up',         binding: 'mod+alt+shift+up',     global: yes }
    { command: 'move tab down',       binding: 'mod+alt+shift+down',   global: yes }
    { command: 'move tab left',       binding: 'mod+alt+shift+left',   global: yes }
    { command: 'move tab right',      binding: 'mod+alt+shift+right',  global: yes }
]

_ = require 'underscore'
descs = require './workspace-descriptions'

out = []

for val in keyBindings
  binding = [[], []]
  binding[0].push val.binding.replace('mod', 'ctrl')
  binding[1].push val.binding.replace('mod', 'command')
  j = val.command.replace(/\s/g, '')
  obj =
    name: 'w#' + j
    description: descs[j]
    binding: binding
    readonly: false
    enabled: yes
    hidden: false
    options:
      mousetrap:
        global: val.global

  out.push obj

console.log JSON.stringify out, null, 2
