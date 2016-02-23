BeginnersEditorView = require './beginners-editor-view'
{CompositeDisposable} = require 'atom'
{Directory, Point} = require 'atom'
{$} = require 'atom-space-pen-views'
fs = require 'fs'

module.exports = BeginnersEditor =
  beginnersEditorView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @beginnersEditorView = new BeginnersEditorView(state.beginnersEditorViewState)
    @modalPanel = atom.workspace.addRightPanel(item: @beginnersEditorView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    # @subscriptions.add atom.commands.add 'atom-workspace', 'beginners-editor:toggle': => @toggle()
    if editor = atom.workspace.getActiveTextEditor()
      @subscriptions.add editor.onDidChangeCursorPosition (event) => @checkSpriteUnderCursor(event)
    paths = path for path in atom.project.getPaths() when fs.existsSync("#{path}/assets/sprites")
    console.log "Path: #{paths}"
    dir = new Directory("#{path}/assets/sprites")
    sprites = dir.getEntriesSync()
    @beginnersEditorView.listSprites(sprites)

    #@subscriptions.add atom.commands.add 'atom-workspace', 'editor:onDidChangeCursorPosition': => @toggle()
  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @beginnersEditorView.destroy()

  serialize: ->
    beginnersEditorViewState: @beginnersEditorView.serialize()

  selectSprite: (sprite, range) ->
    console.log sprite
    if editor = atom.workspace.getActiveTextEditor()
      editor.setTextInBufferRange(range, sprite)
      @beginnersEditorView.scrollToSprite(sprite)

  checkSpriteUnderCursor: (event) ->
    if editor = atom.workspace.getActiveTextEditor()
      getRange = ->
        range = event.cursor.getCurrentWordBufferRange(wordRegex: /["']?[a-z0-9_-]*["']?/i)
        if range.isEmpty()
          return null
        return range.translate(new Point(0, 1), new Point(0, -1))

      show = do (@modalPanel) -> ((found) ->
          if found
            @modalPanel.show()
          else
            @modalPanel.hide())


      select = do (@beginnersEditorView, editor) -> ((sprite) ->
          range = getRange()
          editor.setTextInBufferRange(range, sprite)
          @beginnersEditorView.scrollToSprite(sprite, show, select)
        )

      if range = getRange()
        @beginnersEditorView.scrollToSprite(editor.getTextInBufferRange(range), show, select)
      else
        @modalPanel.hide()

      # for path in atom.project.getPaths()
      #   ((path, view) ->
      #     console.log path
      #     if fs.existsSync("#{path}/assets/sprites/#{text}.png")
      #       view.setImage("#{path}/assets/sprites/#{text}.png")
      #     else if fs.existsSync("#{path}/assets/texture/#{text}.png")
      #       view.setImage("#{path}/assets/textures/#{text}.png"))(path, @beginnersEditorView)
