module.exports = getEmbedSize = (embed, maxWidth) ->

  { width, height } = embed
  maxWidth          = Math.min (maxWidth or 600), 600
  maxHeight         = 400
  ratio             = width/height
  isWideImage       = ratio > 1
  needsResize       = width > maxWidth or height > maxHeight

  if needsResize
    if isWideImage
      width  = Math.floor Math.min maxWidth, width
      height = Math.floor width / ratio
      if height > maxHeight
        height = maxHeight
        width  = Math.floor height * ratio

    else
      height = Math.floor Math.min maxHeight, height
      width  = Math.floor height * ratio
      if width > maxWidth
        width  = maxWidth
        height = Math.floor width / ratio

  return { width, height }
