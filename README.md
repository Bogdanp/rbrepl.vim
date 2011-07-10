# RbREPL.vim

RbREPL.vim is a VIM plugin that allows you to run a Ruby interactive
interpreter inside a VIM buffer.

# Preview

Screenshot:

![Version 0.0.1](http://farm7.static.flickr.com/6013/5918697833_2ebe329b44_z.jpg)

# Warning

*Multiline statements <strike>don't yet</strike> sort-of work.*

This plugin is in its early stages and I'm very new to Ruby programming.
It _probably_ won't do anything harmful to your computer, but it might,
at times, not work as expected. 

# Installation

Use `pathogen` and clone this repository into your `bundle` directory.

# Usage

Start the REPL using with `<leader>R` or `:RbREPLToggle<CR>`. Type away.
To stop the REPL run either of those commands again. This will not close
the buffer.
