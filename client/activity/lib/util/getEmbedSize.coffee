module.exports = getEmbedSize = (embed) ->

  { width, height } = embed
  maxWidth          = 600
  maxHeight         = 450
  ratio             = width/height
  isWideImage       = ratio > 1
  needsResize       = width > maxWidth or height > maxHeight

  if needsResize
    if isWideImage
      width  = Math.floor Math.min maxWidth, width
      height = Math.floor width / ratio
    else
      height = Math.floor Math.min maxHeight, height
      width  = Math.floor height * ratio

  return { width, height }