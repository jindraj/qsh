" Vim plugin for qsh
" Last Change:  2020 Nov 12
" Maintainer:   Muhmud Ahmad
" License:      This file is placed in the public domain.

let s:save_cpo = &cpo
set cpo&vim

" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

function QshExecute(delimiter = ";", includeDelimiter = 1)
  let delimiterLength = strlen(a:delimiter)

  " Search for the previous delimiter
  let [ previousLine, previousPos ] = searchpos(a:delimiter, "bnW")

  " If there was no previous delimiter, use the start of the document
  if !(previousLine == 0 && previousPos == 0)
    let previousPos += delimiterLength
  endif
  
  " If the cursor is currently on a delimiter, we will use the current
  " position
  let currentChar = strcharpart(getline('.')[col('.') - 1:], 0, delimiterLength)
  if currentChar == a:delimiter
    let pos = getpos(".")

    let nextLine = pos[1]
    let nextPos = pos[2]
  else
    " Search forwards for the next delimiter
    let [ nextLine, nextPos ] = searchpos(a:delimiter, "enW")

    " If no delimiter was found, use the end of the document
    if nextLine == 0 && nextPos == 0
      let nextLine = line('$')
    endif
  endif

  " Get the lines and adjust appropriately for the required position range
  let lines = getline(previousLine, nextLine)
  let lines[0] = lines[0][previousPos:]

  if nextPos != 0
    " Chop off the delimiter if it is not required
    if a:includeDelimiter == 0
     let nextPos -= delimiterLength
    endif

    " If we still have a nextPos, adjust accordingly, otherwise the delimiter
    " was the only thing on the last line, so blank it out
    let lines[-1] = nextPos != 0 ? lines[-1][:nextPos] : ""
  endif

  " Write to the requested file
  call writefile(lines, $QSH_EXECUTE_QUERY)

  echo "Qsh: Sending Query >>>"
  call system($QSH)
endfunction

function QshExecuteSelection() range
  echo
  normal gv

  " Get the start and end of the ranges
  let rangeStart = getpos("'<")
  let rangeEnd = getpos("'>")

  if rangeStart != rangeEnd
    let lines = getline(rangeStart[1], rangeEnd[1])

    let lines[0] = lines[0][rangeStart[2]-1:]
    let lines[-1] = lines[-1][:rangeEnd[2]-1]

    " Write to the requested file
    call writefile(lines, $QSH_EXECUTE_QUERY)

    echo "Qsh: Sending Query >>>"
    call system($QSH)
  endif
endfunction

function QshExecuteAll()
  " Write to the requested file
  call writefile(getline(1, line('$')), $QSH_EXECUTE_QUERY)

  echo "Qsh: Sending Script >>>"
  call system($QSH)
endfunction

function QshExecuteNamedQuery(query) range
  echo
  normal gv

  " Get the start and end of the ranges
  let rangeStart = getpos("'<")
  let rangeEnd = getpos("'>")

  if rangeStart != rangeEnd
    let lines = getline(rangeStart[1], rangeEnd[1])

    let lines[0] = lines[0][rangeStart[2]-1:]
    let lines[-1] = lines[-1][:rangeEnd[2]-1]

    " Write to the requested file
    call writefile(lines, $QSH_EXECUTE_QUERY)
  endif

  echo "Qsh: " . a:query . " >>>"
  call system("$QSH query " . a:query)
endfunction

function QshExecuteQuery() range
  echo
  normal gv

  " Get the start and end of the ranges
  let rangeStart = getpos("'<")
  let rangeEnd = getpos("'>")

  if rangeStart != rangeEnd
    let lines = getline(rangeStart[1], rangeEnd[1])

    let lines[0] = lines[0][rangeStart[2]-1:]
    let lines[-1] = lines[-1][:rangeEnd[2]-1]

    " Write to the requested file
    let query = join(lines)

    echo "Qsh: " . query . " >>>"
    call system("$QSH query " . query)
  endif
endfunction

function QshExecuteResultQuery() range
  echo
  normal gv

  " Get the start and end of the ranges
  let rangeStart = getpos("'<")
  let rangeEnd = getpos("'>")

  let query = ''
  if rangeStart == rangeEnd
    let [ matchLine, matchPos ] = searchpos("[^( ]\\+\\s*([^()]*)", "bsW")
    
    if matchLine != 0 
      let rangeStart = getpos(".")

      let rangeEnd = getpos("''")
      let rangeEnd[2] = rangeEnd[2] + 1
    endif
  endif

  if rangeStart != rangeEnd
    let lines = getline(rangeStart[1], rangeEnd[1])

    " Store the parts of the lines that we need to keep
    let lineStart = strpart(lines[0], 0, rangeStart[2] - 1)
    let lineEnd = strpart(lines[-1], rangeEnd[2] - 1)

    " Amend the selection so that we only have the selected part
    let lines[0] = lines[0][rangeStart[2]-1:]
    let lines[-1] = lines[-1][:rangeEnd[2]-1]

    " Write to the requested file
    let query = join(lines)

    " Display a message to the user
    let message = "Qsh: *" . query . " >>>"
    echo message

    let result = system("$QSH result-query " . shellescape(query))
    if v:shell_error != 0
      echo message .. " " .. result
    else
      " Prepare the results
      let result = split(result, '\n')[:-1]
      let result[0] = lineStart . result[0]
      let result[-1] = result[-1] . lineEnd

      exec 'normal "_d'
      call setline(rangeStart[1], result)

      " Position the cursor at the end of the snippet
      call setpos(".", [ rangeStart[0], rangeStart[1] + len(result) - 1, strlen(result[-1]), rangeStart[3] ])
    endif
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

