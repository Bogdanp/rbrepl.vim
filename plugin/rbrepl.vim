" =======================================================================
" File:        rbrepl.vim
" Version:     0.0.1
" Description: Vim plugin that lets you run a Ruby interactive
"              interpreter inside a VIM buffer.
" Maintainer:  Bogdan Popa <popa.bogdanp@gmail.com>
" License:     Copyright (C) 2011 Bogdan Popa
"
"              Permission is hereby granted, free of charge, to any
"              person obtaining a copy of this software and associated
"              documentation files (the "Software"), to deal in
"              the Software without restriction, including without
"              limitation the rights to use, copy, modify, merge,
"              publish, distribute, sublicense, and/or sell copies
"              of the Software, and to permit persons to whom the
"              Software is furnished to do so, subject to the following
"              conditions:
"
"              The above copyright notice and this permission notice
"              shall be included in all copies or substantial portions
"              of the Software.
"
"              THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
"              ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
"              TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
"              PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
"              THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
"              DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
"              CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
"              CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
"              IN THE SOFTWARE.
" ======================================================================

" Exit if already loaded or compatible mode is set. {{{
if exists("g:rbrepl_loaded") || &cp || !has("ruby")
    finish
endif
let g:rbrepl_loaded = 1
" }}}
" REPL code in Ruby {{{
ruby <<EOF
require 'stringio'

class RbREPL
  def initialize
    @prompt = 'ruby>'
    @binding = binding
  end

  def redirect_stdout
    @old_stdout = $stdout
    $stdout = StringIO.new
  end

  def restore_stdout
    $stdout = @old_stdout
  end

  def clear_lines
    VIM::command("normal! jdG")
  end

  def insert_prompt(newline=false)
    cmd = newline ? 'o' : 'i'
    VIM::command("normal! #{cmd}#{@prompt} $")
    VIM::command('startinsert!')
  end

  def insert_result(result)
    clear_lines
    VIM::command("normal! o#{result}")
  end

  def evaluate(line)
    begin
      result = eval(line, @binding, '<string>')
    rescue => e
      insert_result(e.inspect.to_s[2..-2])
      e.backtrace[4..-1].each do |line|
        insert_result('    ' + line)
      end
    else
      insert_result(result) if result
    end
    insert_prompt(true)
  end

  def strip_line(line)
    line.gsub(/#{@prompt} ?/, '').rstrip
  end

  def read_line
    redirect_stdout
    line = strip_line($curbuf.line)
    evaluate line if line
    restore_stdout
  end
end

$rbrepl = RbREPL.new
EOF
" }}}
" Public interface. {{{
if !hasmapto("<SID>ToggleREPL")
    map <unique><leader>R :call <SID>ToggleREPL()<CR>
endif

fun! s:ToggleREPL()
    if exists("s:repl_started")
        call s:StopREPL()
        unlet! s:repl_started
    else
        call s:StartREPL()
        let s:repl_started = 1
    endif
endfun

fun! s:StartREPL()
    enew
    setl ft=ruby
    setl noai nocin nosi inde=
    map  <buffer><silent><CR> :ruby $rbrepl.read_line<CR>
    imap <buffer><silent><CR> :ruby $rbrepl.read_line<CR>
    ruby $rbrepl.insert_prompt
    echo("RbREPL started.")
endfun

fun! s:StopREPL()
    map  <buffer><silent><S-CR> <S-CR>
    imap <buffer><silent><S-CR> <S-CR>
    map  <buffer><silent><CR> <CR>
    imap <buffer><silent><CR> <CR>
    echo("RbREPL stopped.")
endfun

" Expose the Toggle function publicly.
command! -nargs=0 RbREPLToggle call s:ToggleREPL()
" }}}

" vim:fdm=marker
