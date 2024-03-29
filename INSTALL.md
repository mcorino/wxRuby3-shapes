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
As wxRuby3/Shapes has a dependency on wxRuby3 the wxRuby3 gem will be attempted to be installed if (the required version is) 
not yet installed. This will be attempted using a default installation of the wxRuby3 gem. As this is a gem building 
a native extension (except for Windows where the default install will be a prebuilt binary extension gem) this can take quite a
while. 

Due to the dependencies of the wxRuby3 gem itself it might be preferable to install that gem separately beforehand. See the
[INSTALL](https://github.com/mcorino/wxRuby3/blob/master/INSTALL.md) document of the wxRuby3 project for more details.

## Building from source

When installing from source the following basic requirements apply:

- Git version control toolkit
- Ruby 2.5 or later

Checkout the wxRuby3/Shapes sources from [GitHub](https://github.com/mcorino/wxRuby3-shapes).

The wxRuby3/Shapes project provides a Rake based build system. Call `rake help` to get an overview of the available commands.

Execute the `rake gem` command to build the wxruby-shapes gem. This will create a gem file in the `./pkg` folder.

Install the created gem by executing the command `gem install pkg/wxruby3-shapes-<version>.gem`. Everything described 
above for [Installation of a wxRuby3/Shapes Gem](#installation-of-a-wxruby3shapes-gem) applies.
