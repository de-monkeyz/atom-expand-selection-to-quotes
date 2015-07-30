{Range} = require 'atom'

# With cursor at X, the command should select the string:
# "Here is the X cursor"
#
# With cursor at X, the command should select the single quoted string:
# "Here is 'the X cursor' now"
#
# This one doesn't work right yet. We're assuming that the first quote is
# the one we want, which isn't always true.
# With cursor at X, the command should select the double quoted string:
# "Here the cursor is 'outside' the X selection"

class ExpandSelectionToQuotes

  constructor: (@editor) ->
    @scopeMatch = /\.quoted\./
    @cursors = editor.getCursorBufferPositions()
    @includeQuotes = atom.config.get 'expand-selection-to-quotes.includeQuotes'
    @recurrence = 0

    for pos, index in @cursors
      [..., scope] = @editor.scopeDescriptorForBufferPosition(pos).scopes
      # Do not process between strings, only inside them
      continue if not @scopeMatch.test scope
      @addSelection(pos)


  expandSelection: (position, direction) ->

    range = @editor.displayBuffer.bufferRangeForScopeAtPosition ".string.quoted", position

    return if not range


    # Select ran up to start of line (limitation of bufferRangeForScopeAtPosition).
    # Also check the next line
    if direction isnt 1 and range.start.column is 0 and range.start.row > 0
      check = range.start.copy()
      check.row -= 1
      check.column = @editor.lineTextForBufferRow(check.row).length
      @addSelection(check, -1)

    # Select ran up to end of line (limitation of bufferRangeForScopeAtPosition).
    # Also check the next line
    lastLine = @editor.lineTextForBufferRow(range.end.row)
    totalLines = @editor.getLineCount()

    # console.log "Line length: #{lastLine.length}, Column: #{range.end.column}"

    if direction isnt -1 and range.end.column is lastLine.length and range.end.row < totalLines
      check = range.end.copy()
      check.row += 1
      check.column = 0
      @addSelection(check, 1)


    return range


  addSelection: (position, direction) ->
    @initialScope = @editor.scopeDescriptorForBufferPosition(position).toString()
    range = @expandSelection(position, direction)

    # if not @includeQuotes
    #   range.start = range.start.traverse [0, 1]
    #   range.end = range.end.traverse [0, -1]

    # Scope is expanded to INCLUDE quotation marks.
    @editor.addSelectionForBufferRange(range) if range


module.exports =
  activate: ->
    atom.commands.add 'atom-text-editor', 'expand-selection-to-quotes:toggle', ->
      paneItem = atom.workspace.getActivePaneItem()
      new ExpandSelectionToQuotes(paneItem)

  config:
    includeQuotes:
      type: 'boolean'
      default: true
      description: 'Include surrounding quotation marks in expanded selections'

  ExpandSelectionToQuotes: ExpandSelectionToQuotes
