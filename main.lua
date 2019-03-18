function love.load()
  assets = {
    wall_lava = love.graphics.newImage("lava.png"),
    wall_water = love.graphics.newImage("water.png"),
    start_point = love.graphics.newImage("start.png"),
    finish_point = love.graphics.newImage("goal.png"),
    player_mouse = love.graphics.newImage("mouse.png"),
    title_font = love.graphics.newFont(20),
    big_font = love.graphics.newFont(42),
    hint_font = love.graphics.newFont(16)
  }

  game = new_game()
end

function love.draw()
  game:draw_game(0, 60)
end

function love.keypressed(key)
  if key == "space" then
    game:toggle_game_mode()
  elseif key == "r" then
    game = new_game()
  elseif key == "e" then
    local mouse_x, mouse_y = love.mouse.getPosition()
    game:game_place_finish(mouse_x, mouse_y - 60)
  elseif key == "s" then
    local mouse_x, mouse_y = love.mouse.getPosition()
    game:game_place_start(mouse_x, mouse_y - 60)
  end
end

function love.mousepressed(x, y, button)
  if button == 1 then
    game:set_editor_mode("carve")
  elseif button == 2 then
    game:set_editor_mode("fill")
  end

  game:game_mousemoved(x, y - 60)
end

function love.mousereleased(x, y, button)
  game:set_editor_mode("view")
end

function love.mousemoved(x, y)
  game:game_mousemoved(x, y - 60)
end

function new_game()
  local game = {}

  -- Setup game state
  game.mode = "edit"
  game.editor_mode = "view"
  game.box_size = 30
  game.map_size = 20

  -- Setup game map
  game.map = {}
  for i = 1, game.map_size do
    game.map[i] = {}
    for j = 1, game.map_size do
      game.map[i][j] = "wall"
    end
  end

  -- Game drawing logic
  function game:draw_game(game_x, game_y)
    local window_width, window_height = love.graphics.getDimensions()
    local mouse_x, mouse_y = love.mouse.getPosition()

    -- Draw title and help text
    love.graphics.printf("Magma Mouse Maze", assets.title_font, 0, 0, window_width, "center")
    love.graphics.printf("Mode: " .. self.mode, assets.hint_font, 0, 0, window_width, "left")
    love.graphics.printf("[SPACE]: Toggle editor [S]: Place start [E]: Place end [R]: Reset",
                                assets.hint_font, 0, 30, window_width, "center")
    -- Draw game map
    for y = 1, #self.map do
      for x = 1, #self.map[y] do
        local box_x = game_x + ((x - 1) * self.box_size)
        local box_y = game_y + ((y - 1) * self.box_size)

        -- Draw a wall if the current tile is a wall
        if self.map[x][y] == "wall" then
          -- Draw water in edit mode, and lava in play mode
          if self.mode == "edit" then
            love.graphics.draw(assets.wall_water, box_x, box_y)
          else
            love.graphics.draw(assets.wall_lava, box_x, box_y)
          end
        -- Draw a start point if the current tile is a start point
        elseif self.map[x][y] == "start" then
          love.graphics.draw(assets.start_point, box_x, box_y)
        -- Draw a finish point if the current tile is a finish point
        elseif self.map[x][y] == "finish" then
          love.graphics.draw(assets.finish_point, box_x, box_y)
        end
      end
    end

    -- Draw playing state graphics
    if self.mode == "play" then
      love.graphics.draw(assets.player_mouse, mouse_x - 15, mouse_y - 15)
    end

    -- Draw edit state graphics
    if self.mode == "edit" then
      local edit_box_x = math.floor(mouse_x / self.box_size) * 30
      local edit_box_y = math.floor(mouse_y / self.box_size) * 30

      if self.editor_mode == "carve" then
        love.graphics.setColor(1.0, 0.0, 0.0)
      elseif self.editor_mode == "fill" then
        love.graphics.setColor(0.0, 1.0, 0.0)
      end

      love.graphics.rectangle("line", edit_box_x, edit_box_y, self.box_size, self.box_size)

      love.graphics.setColor(1.0, 1.0, 1.0)
    end

    -- Won state graphics
    if self.mode == "won" then
      love.graphics.printf("You won!", assets.big_font, 0, 300, window_width, "center")
    end
    -- Dead state graphics
    if self.mode == "dead" then
      love.graphics.printf("You died!", assets.big_font, 0, 300, window_width, "center")
    end
  end


  function game:toggle_game_mode()
    if self.mode == "edit" then
      self.mode = "play"

      for y = 1, #self.map do
        for x = 1, #self.map[y] do
          if self.map[x][y] == "start" then
            love.mouse.setPosition(x * self.box_size - 15, y * self.box_size + 45)
          end
        end
      end
    else
      self.mode = "edit"
    end
  end

  function game:game_mousemoved(x, y)
    local map_x, map_y = math.ceil(x / 30), math.ceil(y / 30)

    if self.mode == "edit" then
      if self.editor_mode == "carve" then
        self.map[map_x][map_y] = "path"
      elseif self.editor_mode == "fill" then
        self.map[map_x][map_y] = "wall"
      end
    elseif self.mode == "play" then
      if self.map[map_x][map_y] == "wall" then
        self.mode = "dead"
      elseif self.map[map_x][map_y] == "finish" then
        self.mode = "won"
      end
    end
  end

  function game:set_editor_mode(mode)
    self.editor_mode = mode
  end

  function game:game_place_start(x, y)
    if self.mode == "edit" then
      for y = 1, #self.map do
        for x = 1, #self.map[y] do
          if self.map[x][y] == "start" then
            self.map[x][y] = "wall"
          end
        end
      end

      local map_x, map_y = math.ceil(x / 30), math.ceil(y / 30)

      self.map[map_x][map_y] = "start"
    end
  end

  function game:game_place_finish(x, y)
    if self.mode == "edit" then
      for y = 1, #self.map do
        for x = 1, #self.map[y] do
          if self.map[x][y] == "finish" then
            self.map[x][y] = "wall"
          end
        end
      end

      local map_x, map_y = math.ceil(x / 30), math.ceil(y / 30)

      self.map[map_x][map_y] = "finish"
    end
  end

  return game
end
