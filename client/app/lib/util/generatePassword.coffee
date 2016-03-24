###
password-generator
Copyright(c) 2011 Bermi Ferrer <bermi@bermilabs.com>
MIT Licensed
###


vowel = /[aeiouAEIOU]$/
consonant = /[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ]$/

fn = (length = 10, memorable = yes, pattern = /\w/, prefix = '') ->

  return prefix if prefix.length >= length

  if memorable
    pattern = if consonant.test(prefix) then vowel else consonant

  n   = (Math.floor(Math.random() * 100) % 94) + 33
  chr = String.fromCharCode(n)
  chr = chr.toLowerCase() if memorable

  unless pattern.test chr
    return fn length, memorable, pattern, prefix

  return fn length, memorable, pattern, '' + prefix + chr

module.exports = fn
