module.exports =
  name         : 'Activity'
  searchRoute  : '/Activity?q=:text:'
  commands     :
    'next tab'     : 'goToNextTab'
    'previous tab' : 'goToPreviousTab'
  keyBindings: [
    { command: 'next tab',      binding: 'alt+]',    global: yes }
    { command: 'next tab',      binding: 'alt+down', global: yes }
    { command: 'previous tab',  binding: 'alt+up',   global: yes }
    { command: 'previous tab',  binding: 'alt+[',    global: yes }
  ]

