" =======================================================================
" File:        rbrepl.vim
" Version:     0.0.9
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

class String
  OpenerTokens = %w[begin module class def case do for while <<EOF] + ['\{', '\[', '\(']
  CloserTokens = %w[end EOF] + ['\}', '\]', '\)']
  # Tokens that should only start a block if they are at the beginning
  # of a line.
  SpecialTokens = %w[if unless]

  def balanced?
    copy = self.gsub(/\/[^\/]*\//, '').
                gsub(/"[^"]*"/, '').
                gsub(/'[^']*'/, '').
                gsub(/#.*$/, '')
    openers = copy.scan(/(#{OpenerTokens.join('|')})/).length
    closers = copy.scan(/(#{CloserTokens.join('|')})/).length
    openers += copy.scan(/^\s*(#{SpecialTokens.join('|')})/).length
    openers - closers == 0
  end
end

module RbREPL
  class REPL
    def initialize(prompt='rb> ', block_prompt='..> ')
      @prompt, @block_prompt = prompt, block_prompt
      @binding = binding
      @block = ''
    end
  
    def redirect_stdstreams
      @old_stderr = $stderr
      @old_stdout = $stdout
      $stderr = $stdout = StringIO.new
    end
  
    def restore_stdstreams
      $stderr = @old_stderr
      $stdout = @old_stdout
    end

    def clear_block
      @block = ''
    end

    def clear_lines
      VIM::command("normal! jdG")
    end

    def insert_prompt(newline=false, block=false)
      command = newline ? 'o' : 'i'
      prompt = block ? @block_prompt : @prompt
      clear_lines
      VIM::command("normal! #{command}#{prompt}$")
      VIM::command('startinsert!')
    end
  
    def insert_line(line)
      clear_lines
      VIM::command("normal! o#{line.rstrip}")
    end
  
    def insert_result(result)
      result = 'nil' if result.to_s.empty?
      insert_line("=> #{result}")
    end
  
    def insert_stdout
      $stdout.rewind
      $stdout.readlines.each do |line|
        insert_line(line)
      end
    end
  
    def evaluate(stream)
      begin
        result = eval(stream, @binding)
      rescue StandardError, SyntaxError => e
        insert_line(e.inspect.to_s[2..-2])
        # Skip the first 5 lines of the backtrace since they refer to
        # this file
        e.backtrace[5..-1].each do |line|
          insert_line('    ' + line)
        end
      else
        insert_stdout
        insert_result(result)
      end
      insert_prompt(true)
    end

    def evaluate_block
      evaluate(@block) unless @block.empty?
      clear_block
    end

    def evaluate_file(filename)
      redirect_stdstreams
      evaluate(IO.read(filename))
      restore_stdstreams
    end
  
    def get_line
      $curbuf.line.gsub(/^#{@prompt} ?/, '').
                   gsub(/^#{@block_prompt} ?/, '').
                   rstrip
    end

    def update_block
      @block += "#{get_line}\n"
    end
  
    def read_line
      redirect_stdstreams
      update_block
      if @block.balanced?
        evaluate_block
      else
        insert_prompt(true, true)
      end
      restore_stdstreams
    end
  end
end

$rbrepl = RbREPL::REPL.new
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
    setl buftype=nofile
    setl ft=ruby
    setl noai nocin nosi inde=
    map  <buffer><silent><CR> :ruby $rbrepl.read_line<CR>
    imap <buffer><silent><CR> :ruby $rbrepl.read_line<CR>
    map  <buffer><silent><leader>c :ruby $rbrepl.clear_block<CR>
    ruby $rbrepl.insert_prompt
    echo("RbREPL started.")
endfun

fun! s:StartREPLWithFile()
    let s:filename = expand('%')
    call s:StartREPL()
    ruby $rbrepl.evaluate_file(VIM::evaluate("s:filename"))
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
command! -nargs=0 RbREPLEvalFile call s:StartREPLWithFile()
" }}}

" vim:fdm=marker
