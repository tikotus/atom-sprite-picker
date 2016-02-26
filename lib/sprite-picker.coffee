SpritePickerView = require './sprite-picker-view'
{CompositeDisposable} = require 'atom'
{Directory, Point} = require 'atom'
{$} = require 'atom-space-pen-views'
fs = require 'fs'

module.exports = SpritePicker =
  spritePickerView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    console.log "Activate sprite picker"
    @spritePickerView = new SpritePickerView(state.spritePickerViewState)
    @modalPanel = atom.workspace.addRightPanel(item: @spritePickerView.getElement(), visible: true)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    # @subscriptions.add atom.commands.add 'atom-workspace', 'sprite-picker:toggle': => @toggle()
    if editor = atom.workspace.getActiveTextEditor()
      @subscriptions.add editor.onDidChangeCursorPosition (event) => @checkSpriteUnderCursor(event)
    paths = [path for path in atom.project.getPaths() when fs.existsSync("#{path}/circler/dev/assets/sprites")]
    path = paths[0]
    console.log "Path: #{path}"
    dir = new Directory("#{path}/circler/dev/assets/sprites")
    sprites = dir.getEntriesSync()
    @spritePickerView.listSprites(sprites)

    #@subscriptions.add atom.commands.add 'atom-workspace', 'editor:onDidChangeCursorPosition': => @toggle()
  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @spritePickerView.destroy()

  serialize: ->
    spritePickerViewState: @spritePickerView.serialize()

  selectSprite: (sprite, range) ->
    console.log sprite
    if editor = atom.workspace.getActiveTextEditor()
      editor.setTextInBufferRange(range, sprite)
      @spritePickerView.selectSprite(sprite)

  checkSpriteUnderCursor: (event) ->
    if editor = atom.workspace.getActiveTextEditor()
      getRange = ->
        range = event.cursor.getCurrentWordBufferRange(wordRegex: /["'][a-z0-9_-]*["']/i)
        if range.isEmpty()
          return null
        range = range.translate(new Point(0, 1), new Point(0, -1))
        if range.start.column >= range.end.column
          return null
        console.log range.start.column + " " + range.end.column
        return range

      show = do (@modalPanel) -> ((found) ->
          if found
            @modalPanel.show()
          else
            @modalPanel.hide())


      select = do (@spritePickerView, editor) -> ((sprite) ->
          range = getRange()
          editor.setTextInBufferRange(range, sprite)
          @spritePickerView.selectSprite(sprite, show, select)
        )

      range = getRange()
      if range and !range.isEmpty()
          @spritePickerView.selectSprite(editor.getTextInBufferRange(range), show, select)
      else
        @modalPanel.hide()

      # for path in atom.project.getPaths()
      #   ((path, view) ->
      #     console.log path
      #     if fs.existsSync("#{path}/assets/sprites/#{text}.png")
      #       view.setImage("#{path}/assets/sprites/#{text}.png")
      #     else if fs.existsSync("#{path}/assets/texture/#{text}.png")
      #       view.setImage("#{path}/assets/textures/#{text}.png"))(path, @spritePickerView)
