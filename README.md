# RbREPL.vim

RbREPL.vim is a VIM plugin that allows you to run a Ruby interactive
interpreter inside a VIM buffer.

# Preview

Screenshot:

![Version 0.0.7](http://farm7.static.flickr.com/6029/5926293207_eec79bce06_z.jpg)

[Video](http://www.youtube.com/watch?v=kzZD7FeKfcQ).

# Warning

*Multiline statements <del>don't yet</del> sort-of work.*

This plugin is in its early stages and I'm very new to Ruby programming.
It _probably_ won't do anything harmful to your computer, but it might,
at times, not work as expected. 

# Installation

Use `pathogen` and clone this repository into your `bundle` directory.

# Usage

Start the REPL using `<leader>R` or `:RbREPLToggle<CR>`. Type away. To
stop the REPL run either of those commands again. This will not close
the buffer.

It's possible to evaluate a file you're working on inside the REPL by
running the command `:RbREPLEvalFile<CR>` on a Ruby file.
