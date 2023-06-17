# wxruby3/shapes

A wxRuby3 Shapes framework.

## Introduction

**wxruby3/shapes** (Wx::SF) is a pure Ruby software library/framework based on wxRuby3 which allows
easy development of software applications manipulating graphical objects (shapes) like various CASE 
tools, technological processes modeling tools, etc. This library is a pure Ruby port of the excellent 
[wxShapesFramework](https://sourceforge.net/projects/wxsf/) C++ library based on wxWidgets.

The library consists of several classes encapsulating so called 'Shape canvas' (visual
GUI control used for management of included diagrams; it supports serialization/
deserialization to files (currently supported formats are JSON and YAML), clipboard and 
drag&drop operations with diagram components, undo/redo operations, diagram export to 
BMP files, etc), printing (and previewing) and a standard collection of diagram components 
(basic rectangular and elliptic shapes, line and curve shape, polygonal shapes, static and 
in-place editable text, bitmap images, etc).

The shape framework (and shape canvas) allows to define relationship between various
shape types (for example which shape can be a child of another one, which shape types
can be connected together by which connection type, how do various connections look
like, etc) and provides ability to interactively design diagrams composited of those
shape objects.

More over, the library source code is pure Ruby based on wxRuby3 GUI toolkit, so it will
run on any platform that supports Ruby and wxRuby3.

## wxruby3/shapes licence

wxruby3/shapes is free and open-source. It is distributed under the liberal
MIT licence which is compatible with both free and commercial development.
See [LICENSE](LICENSE) for more details.

See the [wxRuby3](https://github.com/mcorino/wxRuby3) project for more information
concerning licensing of wxRuby3.

### Required Credits and Attribution

Generally, neither wxRuby3 nor wxruby3/shapes require attribution, beyond
retaining existing copyright notices. 
See [here](CREDITS.md) for more details and acknowledgements.

## FAQ

### What platforms and operating systems are supported in wxruby3/shapes?

All platforms supporting Ruby and wxRuby3. See the [wxRuby3](https://github.com/mcorino/wxRuby3) 
project for more information 

### Where can I ask a question, or report a bug?

Use GitHUb Issues.

When asking a question, if something is not working as you expect,
please provide a *minimal*, *runnable* sample of code that demonstrates
the problem, and say what you expected to happen, and what actually
happened. Please also provide basic details of your platform, Ruby,
wxruby3/shapes, wxRuby and wxWidgets version, and make a reasonable effort 
to find answers in the archive and documentation before posting. People are mostly happy
to help, but it's too much to expect them to guess what you're trying to
do, or try and debug 1,000 lines of your application.
Very important also; do not use offensive language and be **polite**.

### How can I learn to use wxruby3/shapes?

The wxruby3/shapes API has a lot of features and takes some time to learn. 
The wxruby3/shapes distribution comes with several samples which illustrate how 
to use many specific parts of the API. Good one's to start with are the
basic samples (samples/sample1|2|3|4) which provide insights in various basic 
features. The samples also include a fairly advanced and complete diagramming
demo application showcasing most of the features of wxruby3/shapes.

Complete (more or less) wxruby/shapes API documentation should be part of any
complete wxruby3/shapes build. This tends to focus on providing a reference
of all available modules, classes ad methods and how to use specific
classes and methods, rather than on how to construct an application
overall.
This documentation (for the latest release) is also available online
[here](https://mcorino.github.io/wxRuby3-shapes/file.00_starting.html).

### I am getting an error trying to install wxruby3/shapes

Please double-check the [INSTALL](INSTALL.md) documents, and search issue archives. If
this doesn't help, please post your question using GitHub Issues.
