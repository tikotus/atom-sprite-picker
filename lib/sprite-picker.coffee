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
    @modalPanel = atom.workspace.addRightPanel(item: @spritePickerView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-text-editor', 'beginners-editor:edit': (event) =>
      if @checkSpriteUnderCursor() == false
        event.abortKeyBinding();

    #if editor = atom.workspace.getActiveTextEditor()
    #  @subscriptions.add editor.onDidChangeCursorPosition (event) => @checkSpriteUnderCursor(event)

    #@subscriptions.add atom.commands.add 'atom-workspace', 'editor:onDidChangeCursorPosition': => @toggle()
  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @spritePickerView.destroy()

  serialize: ->
    spritePickerViewState: @spritePickerView.serialize()

  selectSprite: (sprite, range) ->
    if editor = atom.workspace.getActiveTextEditor()
      editor.setTextInBufferRange(range, sprite)
      @spritePickerView.selectSprite(sprite)

  findFolder: (directory, folderName) ->
    for dir in directory.getEntriesSync() when dir.isDirectory()
      if dir.getBaseName() == folderName
        return dir
      if foundInChildren = @findFolder(dir, folderName)
        return foundInChildren
    return null

  checkSpriteUnderCursor: () ->
    if editor = atom.workspace.getActiveTextEditor()
      getRange = ->
        range = editor.getLastCursor().getCurrentWordBufferRange(wordRegex: /["'][a-z0-9_-]*["']/i)
        if range.isEmpty()
          return null
        range = range.translate(new Point(0, 1), new Point(0, -1))
        if range.start.column >= range.end.column
          return null
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
        @spritePickerView.clear()
        for dir in atom.project.getDirectories()
          if spritesFolder = @findFolder(dir, "sprites")
            sprites = spritesFolder.getEntriesSync()
            @spritePickerView.listSprites(sprites)

        subs = new CompositeDisposable
        subs.add editor.onDidChangeCursorPosition (event) =>
          subs.dispose()
          @modalPanel.hide()
        @spritePickerView.selectSprite(editor.getTextInBufferRange(range), show, select)
        return true
      else
        return false

      # for path in atom.project.getPaths()
      #   ((path, view) ->
      #     console.log path
      #     if fs.existsSync("#{path}/assets/sprites/#{text}.png")
      #       view.setImage("#{path}/assets/sprites/#{text}.png")
      #     else if fs.existsSync("#{path}/assets/texture/#{text}.png")
      #       view.setImage("#{path}/assets/textures/#{text}.png"))(path, @spritePickerView)
