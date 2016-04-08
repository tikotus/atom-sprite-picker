{$} = require 'atom-space-pen-views'

module.exports =
class SpritePickerView
  constructor: (serializedState) ->
    # Create root element
    @element = document.createElement('div')
    @element.classList.add('sprite-picker')
    @foo = 0

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element

  clear: ->
    $(".sprite-picker").empty()

  listSprites: (images) ->
    for src in images
      sprite = document.createElement('img')
      sprite.classList.add('preview-image')
      sprite.src = src.getPath()
      sprite.id = src.getPath().replace(/.*[\\\/]([a-z0-9_-]*)\.png/i,"$1")
      @element.appendChild(sprite)


  selectSprite: (img, found, selectSprite) ->
    $(".preview-image").unbind('click')
    if ($("##{img}").length)
      found(true)
      #$("##{img}")[0].scrollIntoView({block: "end", behavior: "smooth"})
      #$(".preview-image").css(opacity:0.4)
      #$("##{img}").css(opacity:1)
      $(".preview-image").click ->
        $(".preview-image").unbind('click')
        selectSprite($(this).attr('id'))
    else
      found(false)
