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
    @cursors = @editor.getCursorBufferPositions()
    @includeQuotes = atom.config.get 'expand-selection-to-quotes.includeQuotes'

    @first = true

    for pos, index in @cursors
      # Scope begins and ends before the character (or quote in this example)
      # Move cursor one to the left if we are adjacent to a closing quote
      pos = pos.copy()
      pos.column -=1 if pos.column > 0 and /'|"/.test @editor.getTextInBufferRange [pos, [pos.row, pos.column+1]]
      [..., scope] = @editor.scopeDescriptorForBufferPosition(pos).scopes
      # Do not process between strings, only inside them
      continue if not @scopeMatch.test scope
      @addSelection(pos, first)


  expandSelection: (position, direction = 0) ->
    try
      range = @editor.displayBuffer.bufferRangeForScopeAtPosition ".string.quoted", position

    return if not range


    # Select ran up to start of line (limitation of bufferRangeForScopeAtPosition).
    # Also check the next line
    if direction isnt 1 and range.start.column is 0 and range.start.row > 0
      check = range.start.copy()
      check.row -= 1
      check.column = @editor.lineTextForBufferRow(check.row).length
      lookBehind = @expandSelection(check, -1)
      range = new Range(lookBehind.start, range.end) if lookBehind

    # Select ran up to end of line (limitation of bufferRangeForScopeAtPosition).
    # Also check the next line
    lastLine = @editor.lineTextForBufferRow(range.end.row)
    totalLines = @editor.getLineCount()

    if direction isnt -1 and range.end.column is lastLine.length and range.end.row < totalLines
      check = range.end.copy()
      check.row += 1
      check.column = 0
      lookAhead = @expandSelection(check, 1)
      range = new Range(range.start, lookAhead.end) if lookAhead


    return range


  addSelection: (position, first) ->
    @initialScope = @editor.scopeDescriptorForBufferPosition(position).toString()
    range = @expandSelection(position)

    # if not @includeQuotes
    #   range.start = range.start.traverse [0, 1]
    #   range.end = range.end.traverse [0, -1]

    # Scope is expanded to INCLUDE quotation marks.
    return if not range

    if @first
      @editor.setSelectedBufferRange(range)
    else
      @editor.addSelectionForBufferRange(range)


    @first = false

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
