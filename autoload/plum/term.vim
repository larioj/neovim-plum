function! plum#term#ReadHeredocBody(start, end_token)
  let end_token = a:end_token
  let start = a:start
  let end = start
  let lines = [getline(end)]
  while end < line('$') && lines[-1] !~# (end_token . '$')
    let end = end + 1
    call add(lines, getline(end))
  endwhile
  return [end + 1, lines]
endfunction

function! plum#term#ReadEscapeTerminatedLines(start)
  let start = a:start
  let end = start
  let lines = [getline(end)]
  while lines[-1][-1:] ==# '\' && end < line('$')
    let end = end + 1
    call add(lines, getline(end))
  endwhile
  return [end + 1, lines]
endfunction

function! plum#term#ReadBash()
  let start = line('.')
  let [end, cmd] = plum#term#ReadEscapeTerminatedLines(start)
  if  cmd[-1] =~# '<<EOF' || cmd[-1] =~# "<<'EOF'"
    let [end, body] = plum#term#ReadHeredocBody(end, 'EOF')
    let cmd = cmd + body
  endif
  return cmd
endfunction

function! plum#term#ReadActiveBash()
  return plum#term#ReadBash()
endfunction

function! plum#term#Extract(marker)
  let is_comment = synIDattr(synIDtrans(synID(line("."), col("$")-1, 1)), "name") ==# 'Comment'
  let cmd = plum#term#ReadActiveBash()
  let indent = 0
  while indent < len(cmd[0]) && strpart(cmd[0], indent, 2) !=# a:marker
    let indent = indent + 1
  endwhile
  let prefix = strpart(cmd[0], 0, indent)
  if indent >= len(cmd[0]) || 
        \ (is_comment && len(prefix) && prefix !~# '\v^\W*\s+$') || 
        \ (!is_comment && len(trim(prefix)))
    return ['', v:false]
  endif
  if is_comment
    call map(cmd, { _, l -> l[indent:] })
    let indent = 0
  endif
  let end = 0
  while end < len(cmd) && cmd[end][-1:] ==# '\'
    let end = end + 1
  endwhile
  let first_line = cmd[0:end]
  let rest = cmd[end+1:]
  call map(first_line, { _, l -> trim(l[-1:] ==# '\' ? strpart(l, 0, len(l) - 1) : l) })
  let first_line = join(first_line, ' ')
  call map(rest, { _, l -> l[indent:] })
  return [join([first_line] + rest, "\n")[2:], v:true]
endfunction
