<!--
# @markup markdown
-->

# Installation of wxRuby3/Shapes

## Installation of a wxRuby3/Shapes Gem

The wxRuby3/Shapes project provides gems on [RubyGems](https://rubygems.org) which can be installed with the
standard `gem install` command line this:

```sh
gem install wxruby3-shapes
 ```

This will install the wxruby3-shapes gem on any system supporting Ruby and wxRuby.
As wxRuby3/Shapes has a dependency on wxRuby3 the wxRuby3 gem will be installed as well if not yet installed. 
Depending on your system this may install a prebuilt binary package (see the [wxRuby3](https://github.com/mcorino/wxRuby3) 
project for more information about supported platforms) or require you to run a post-install step to build the wxRuby3
extension library binaries before you can use wxRuby3/Shapes (see the
[INSTALL](https://github.com/mcorino/wxRuby3/blob/master/INSTALL.md) document of the wxRuby3 project for more details).

## Building from source

When installing from source the following basic requirements apply:

- Git version control toolkit
- Ruby 2.5 or later

Checkout the wxRuby3/Shapes sources from [GitHub](https://github.com/mcorino/wxRuby3-shapes).

The wxRuby3/Shapes project provides a Rake based build system. Call `rake help` to get an overview of the available commands.

Execute the `rake gem` command to build the wxruby-shapes gem. This will create a gem file in the `./pkg` folder.

Install the created gem by executing the command `gem install pkg/wxruby3-shapes-<version>.gem`. Everything described 
above for [Installation of a wxRuby3/Shapes Gem](#installation-of-a-wxruby3shapes-gem) applies.
