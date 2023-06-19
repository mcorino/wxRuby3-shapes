# wxruby3/shapes

![wxruby3/shapes demo](assets/screenshot.png)

A wxRuby3 Shapes framework.

## Introduction

**wxruby3/shapes** (Wx::SF) is a pure Ruby software library/framework based on wxRuby3 which allows
easy development of software applications manipulating graphical objects (shapes) like various CASE 
tools, technological processes modeling tools, etc. This library is a pure Ruby implementation based
on the excellent [wxShapeFramework](https://sourceforge.net/projects/wxsf/) C++ library based on 
wxWidgets.

The library consists of several classes encapsulating a so called 'Shape canvas' (visual
GUI control used for management of diagrams) providing the following features:

- Create charts (diagrams) interactively in your wxRuby3 applications
- Serialize/deserialize charts to file or any io stream in multiple formats (currently supported formats are JSON and YAML)
- Support for Clipboard operations (Cut/Paste) and Drag&Drop of diagram components (shapes)
- Support for Undo/Redo operations
- Support for alignment of diagram components.
- Support for printing of diagrams (including preview)
- Support for diagram export to bitmap (any supported type)
- Support for Thumbnail view of diagram
- A standard collection of diagram components
  - Shapes: basic rectangular, square, circle, ellipse, rounded rectangle, grid, flexible grid, text, editable text, polygonal, diamond, bitmap
  - Lines: straight, curved, orthogonal, rounded orthogonal
  - Line arrows: solid, open, diamond, circle
- Highly customizable and extendable

The shape framework (and shape canvas) allows to define the relationship between various
shape types (for example which shape can be a child of another one, which shape types
can be connected together by which connection type, how do various connections look
like, etc) and provides an extensive set of events for customizing the interactive creation 
of diagrams.

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

### How does wxruby3/shapes compare to wxShapeFramework?

**wxruby3/shapes** is not a straight port of wxShapeFramework although much of the structure is maintained 
with the following major implementation differences:

- wxruby3/shapes implements a totally different serialization scheme in which none of the XML serializer 
code has been ported. In fact wxruby3/shapes does not offer any XML serialization out of the box but instead 
provides a more adaptable implementation with (for now) two supported output formats; JSON and YAML.
- Related to this the internal management of shape references has been changed as well as this was tightly 
linked to the serialization implementation.
- The API has been Ruby-fied with respect to constant names, method names and argument passing and return
values.
- The ScaledDC class has been integrated with wxRuby3 and is not part of wxruby3/shapes.

In addition many small tweaks, improvements and also bugfixes have been implemented as part of the port. 

### I am getting an error trying to install wxruby3/shapes

Please double-check the [INSTALL](INSTALL.md) documents, and search issue archives. If
this doesn't help, please post your question using GitHub Issues.
