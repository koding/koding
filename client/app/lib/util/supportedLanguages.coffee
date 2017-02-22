isSupported = no
language    = navigator.language or navigator.userLanguage
languages   = [
  'ca', 'da', 'de', 'en', 'eu', 'fi',
  'fr', 'gd', 'he', 'id', 'is', 'it',
  'ja', 'ji', 'ko', 'nl', 'no', 'sv'
]

for supported in languages when language.indexOf(supported) isnt -1
  isSupported = yes
  break

module.exports = isSupported
