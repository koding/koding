module.exports = (text = '') ->

  ranges = []
  read   = 0

  for part, index in text.split '```'
    blockquote = index %% 2 is 1

    if blockquote
      ranges.push [read, read + part.length - 1]

    read += part.length + 3

  return ranges
