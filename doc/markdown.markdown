## Some notes about markdown

Please name the files `filename.markdown`. The important bit is the `.markdown`
extension, as our converter script will look for files with that extension and
convert them to html.

To compile a file locally you have to install markdown (`apt-cache search
markdown`).

**Please do not commit the generated files into the repository!** The files
will be generated regularly on the server.

## Markdown syntax

Here you have a few examples to get you started, the complete documentation can
be found on the [markdown Homepage](http://daringfireball.net/projects/markdown/syntax)

# First level Heading

or

First level Heading
===================

## Second level Heading

or

Second level Heading
--------------------

In the latter form, the underlines must be as long as the text of the heading
above.

#### Fourth level heading

> A block quote looks like this, this is a block quote, this is a block quote,
> this is a block quote, spanning over several lines

Unordered lists look like this:

* item 1
* item 2
* item 3
    * nested item 1
    * nested item 2
* item 3

Ordered lists look like this:

1. first item
2. second item
3. you get it

Text can be *italic*, **bold**, and ***bold italic***

Inline code fragments are written `like this`. Code blocks are indented by at
least four spaces or one tab and look like this:


    #!/usr/bin/env python

    def foo():
        print 'Markdown rocks!'
        print '(And so does Python!)'


    if __name__ == '__main__':
        foo()

