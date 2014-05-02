# Description:
#   A 2048 Game Engine for Hubot
#
# Commands:
#   hubot 2048 me - Start a game of 2048
#   hubot 2048 <direction> - Move tiles in a <direction>
#   hubot 2048 reset - Resets the current game of 2048
#   hubot 2048 stop - Stops the current game of 2048
#
# Notes:
#   Direction Commands:
#     u(p) - up
#     d(own) - down
#     l(eft) - left
#     r(ight) - right
#
# Author:
#   whyjustin


# Copyright (c) 2014 Justin Young
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Some portions of code are copied from atom-2048 and available under the following license
# Copyright (c) 2014 Peng Sun
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


Tile = (position, value) ->
  @x = position.x
  @y = position.y
  @value = value or 2
  @previousPosition = null
  @mergedFrom = null
  return

Grid = (size) ->
  @size = size
  @cells = []
  @build()
  return

GameManager = (size, renderer) ->
  @size = size
  @startTiles = 2
  @renderer = renderer
  @setup()
  return

Tile::savePosition = ->
  @previousPosition =
    x: @x
    y: @y
  return

Tile::updatePosition = (position) ->
  @x = position.x
  @y = position.y
  return

Grid::build = ->
  x = 0
  while x < @size
    row = @cells[x] = []
    y = 0
    while y < @size
      row.push null
      y++
    x++
  return

Grid::randomAvailableCell = ->
  cells = @availableCells()
  return cells[Math.floor(Math.random() * cells.length)] if cells.length

Grid::availableCells = ->
  cells = []
  @eachCell (x, y, tile) ->
    unless tile
      cells.push
        x: x
        y: y
    return
  return cells

Grid::eachCell = (callback) ->
  x = 0
  while x < @size
    y = 0
    while y < @size
      callback x, y, @cells[x][y]
      y++
    x++
  return

Grid::cellsAvailable = ->
  return !!@availableCells().length

Grid::cellAvailable = (cell) ->
  return not @cellOccupied(cell)

Grid::cellOccupied = (cell) ->
  return !!@cellContent(cell)

Grid::cellContent = (cell) ->
  if @withinBounds(cell)
    return @cells[cell.x][cell.y]
  else
    return null

Grid::insertTile = (tile) ->
  @cells[tile.x][tile.y] = tile
  return

Grid::removeTile = (tile) ->
  @cells[tile.x][tile.y] = null
  return

Grid::withinBounds = (position) ->
  return position.x >= 0 and position.x < @size and position.y >= 0 and position.y < @size

GameManager::setup = ->
  @grid = new Grid(@size)
  @score = 0
  @over = false
  @won = false
  @keepPlaying = false
  @addStartTiles()
  @actuate()
  return

GameManager::getRenderer = ->
  return @renderer

GameManager::keepPlaying = ->
  @keepPlaying = true
  return

GameManager::isGameTerminated = ->
  if @over or (@won and not @keepPlaying)
    true
  else
    false

GameManager::addStartTiles = ->
  i = 0
  while i < @startTiles
    @addRandomTile()
    i++
  return

GameManager::addRandomTile = ->
  if @grid.cellsAvailable()
    value = (if Math.random() < 0.9 then 2 else 4)
    tile = new Tile(@grid.randomAvailableCell(), value)
    @grid.insertTile tile
  return

GameManager::actuate = ->
  @renderer.render @grid,
    score: @score,
    over: @over,
    won: @won,
    terminated: @isGameTerminated()
  return

GameManager::prepareTiles = ->
  @grid.eachCell (x, y, tile) ->
    if tile
      tile.mergedFrom = null
      tile.savePosition()
    return
  return

GameManager::moveTile = (tile, cell) ->
  @grid.cells[tile.x][tile.y] = null
  @grid.cells[cell.x][cell.y] = tile
  tile.updatePosition cell
  return

GameManager::move = (direction) ->
  self = this
  return if @isGameTerminated()
  cell = undefined
  tile = undefined
  vector = @getVector(direction)
  traversales = @buildTraversals(vector)
  moved = false

  @prepareTiles()

  traversales.x.forEach (x) ->
    traversales.y.forEach (y) ->
      cell = 
        x: x
        y: y

      tile = self.grid.cellContent(cell)
      if tile
        positions = self.findFarthestPosition(cell, vector)
        next = self.grid.cellContent(positions.next)

        if next and next.value is tile.value and not next.mergedFrom
          merged = new Tile(positions.next, tile.value * 2)
          merged.mergedFrom = [
            tile
            next
          ]
          self.grid.insertTile merged
          self.grid.removeTile tile

          tile.updatePosition positions.next

          self.score += merged.value

          self.won = true if merged.value is 2048
        else
          self.moveTile tile, positions.farthest

        moved = true unless self.positionsEqual(cell, tile)
      return
    return

  if moved
    @addRandomTile()
    @over = true unless @movesAvailable()
    @actuate()
  return

GameManager::getVector = (direction) ->
  map = 
    0:
      x: 0
      y: -1
    1:
      x: 1
      y: 0
    2:
      x: 0
      y: 1
    3:
      x: -1
      y: 0
  return map[direction]

GameManager::buildTraversals = (vector) ->
  traversales =
    x: []
    y: []
  pos = 0

  while pos < @size
    traversales.x.push pos
    traversales.y.push pos
    pos++

  traversales.x = traversales.x.reverse() if vector.x is 1
  traversales.y = traversales.y.reverse() if vector.y is 1
  return traversales

GameManager::findFarthestPosition = (cell, vector) ->
  previous = undefined

  loop
    previous = cell
    cell = 
      x: previous.x + vector.x
      y: previous.y + vector.y
    break unless @grid.withinBounds(cell) and @grid.cellAvailable(cell)

  farthest: previous
  next: cell

GameManager::movesAvailable = ->
  @grid.cellsAvailable() or @tileMatchesAvailable()

GameManager::tileMatchesAvailable = ->
  self = this
  tile = undefined
  x = 0

  while x < @size
    y = 0

    while y < @size
      tile = @grid.cellContent(
        x: x
        y: y
      )
      if tile
        direction = 0

        while direction < 4
          vector = self.getVector(direction)
          cell = 
            x: x + vector.x
            y: y + vector.y

          other = self.grid.cellContent(cell)
          return true if other and other.value is tile.value
          direction++
      y++
    x++
  return false

GameManager::positionsEqual = (first, second) ->
  first.x is second.x and first.y is second.y

Renderer = ->
  @msg = undefined

Renderer::setMsg = (msg) ->
  @msg = msg

Renderer::renderHorizontalLine = (length) ->
  self = this
  i = 0
  message = '-'
  while i < length
    message += '--'
    i++
  self.msg.send message

Renderer::render = (grid, metadata) ->
  self = this;
  self.renderHorizontalLine grid.cells.length
  grid.cells.forEach (column) ->
    message = '|'
    column.forEach (cell) ->
      value = if cell then cell.value else ' '
      message += value + '|'
    self.msg.send message
  self.renderHorizontalLine grid.cells.length
  self.msg.send "Score: #{metadata.score}"


gameManagerKey = 'gameManager'

getUserName = (msg) ->
  # Running under hipchat adaptor
  if msg.message.user.mention_name?
    msg.message.user.mention_name
  else
    msg.message.user.name

sendHelp = (robot, msg) ->
  prefix = robot.alias or robot.name
  msg.send "Start Game: #{prefix} 2048 me"
  msg.send "Move Tile: #{prefix} 2048 {direction}"
  msg.send "Directions: u(p), d(own), l(eft), r(ight)"
  msg.send "Reset Game: #{prefix} 2048 reset"
  msg.send "Stop Game: #{prefix} 2048 stop"

module.exports = (robot) ->
  robot.respond /2048 me/i, (msg) ->
    gameManager = robot.brain.get(gameManagerKey)

    unless gameManager?
      msg.send "#{getUserName(msg)} has started a game of 2048."
      hubotRenderer = new Renderer()
      hubotRenderer.setMsg msg
      gameManager = new GameManager(4, hubotRenderer)
      robot.brain.set(gameManagerKey, gameManager)
      robot.brain.save()
    else
      msg.send "2048 game already in progress."
      sendHelp robot, msg

  robot.respond /2048 help/i, (msg) ->
    sendHelp robot, msg

  robot.respond /2048 (u(p)?|d(own)?|l(eft)?|r(ight)?)/i, (msg) ->
    gameManager = robot.brain.get(gameManagerKey)
    unless gameManager?
      msg.send "No 2048 game in progress."
      sendHelp robot, msg
      return

    directioon = switch msg.match[1].toLowerCase()
      when 'd', 'down' then 1
      when 'u', 'up' then 3
      when 'l', 'left' then 0
      when 'r', 'right' then 2
    hubotRenderer = gameManager.getRenderer()
    hubotRenderer.setMsg msg
    gameManager.move directioon

  robot.respond /2048 reset/i, (msg) ->
    gameManager = robot.brain.get(gameManagerKey)
    unless gameManager?
      msg.send "No 2048 game in progress."
      sendHelp robot, msg
      return

    msg.send "#{getUserName(msg)} has started a game of 2048."
    gameManager.setup()

  robot.respond /2048 stop/i, (msg) ->
    robot.brain.set(gameManagerKey, null)
    robot.brain.save()