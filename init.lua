local taflo = {}

taflo.quit_server = function ()
  os.execute('flow stop')
end

taflo.start_server = function ()
  os.execute('flow start')
  -- First call will fail. Later calls prevent multiple quit_server calls on QUIT.
  events.disconnect(events.QUIT, taflo.quit_server)
  events.connect(events.QUIT, taflo.quit_server)
end

taflo.complete = function ()
  taflo.start_server()
  local line, pos = buffer:get_cur_line()
  local line_no = buffer:line_from_position(buffer.current_pos)
  local flow_command = table.concat({
    'flow',
    'autocomplete',
    '--no-auto-start',
    '--quiet',
    buffer.filename,
    line_no+1,
    pos+1
  }, ' ')
  local flow_proc = spawn(flow_command)
  flow_proc:write(buffer:get_text())
  flow_proc:close()
  local part = line:sub(1, pos):match('%s*([^%s]*)')
  local list = { }
  local flow_line = flow_proc:read()
  while flow_line ~= nil and flow_line ~= '' do
    table.insert(list, part..flow_line:match('([^%s]*)%s'))
    flow_line = flow_proc:read()
  end
  flow_proc:kill()
  return #part, list
end

taflo.jump_to_def = function ()
  taflo.start_server()
  local _, pos = buffer:get_cur_line()
  local line_no = buffer:line_from_position(buffer.current_pos)
  local flow_command = table.concat({
    'flow',
    'get-def',
    '--no-auto-start',
    '--quiet',
    buffer.filename,
    line_no+1,
    pos+1
  }, ' ')
  local flow_proc = spawn(flow_command)
  local flow_output = flow_proc:read('*a')
  --/home/user/code/index.js:6:7,6:12
  local file, sline, spos, eline, epos = flow_output:match('(.*):(.*):(.*),(.*):(.*)')
  flow_proc:kill()
  if file == '' then
    return
  end
  if file ~= buffer.filename then
    io.open_file(file)
  end
  local movepos = buffer:position_from_line(sline-1) + spos
  buffer:goto_pos(movepos)
end

taflo.init = function ()
  textadept.editing.autocompleters.javascript = taflo.complete
  return taflo
end

return taflo
