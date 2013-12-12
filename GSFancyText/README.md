Summary
=======

GSFancyText is a rich text drawing library for iOS.


Example
==========

First define the styles using a CSS-like string:

    NSString* styleSheet = @".green {color:#00ff00; font-weight:bold} .gray {color:gray; font-weight:bold}";
    [GSFancyText parseStyleAndSetGlobal:styleSheet];

Then create a GSFancyTextView object to display some rich text

    GSFancyTextView* fancyTextView = [GSFancyTextView fancyTextViewWithFrame:frame markupText:@"<span class=green>Hulu</span> <span class=gray>Plus</span>"];
    [fancyTextView updateDisplay];
    
Or alternatively:

    [fancyTextView updateDisplayWithCompletionHandler:^{
        // logic to align fancyTextView based on its size
        // ...
    }];


Use the Demo
==========

The open the GSFancyTextDemo.xcodeproj file with Xcode and run the app. For better viewing experience, it's recommended to compile it to an iPhone, iPod touch, or iPhone simulator.

You can check the GSFancyTextDemoViewController.m file under demo folder to see how the fancy text is defined. You can also change the parameters and see how it affects the output.




Full Documentation
==========

For markup text and style sheet rules, please check the wiki page:
https://github.com/hulu/GrannySmith/wiki/GSFancyText

To install Xcode docset:
1. Install Doxygen, run ruby docs/create.rb to generate a docset file.
2. Copy the com.hulu.gsfancytext.docset file in GSFancyText/docs folder to ~/Library/Developer/Shared/Documentation/DocSets
3. Restart Xcode

After installing docset, you can hold option key and click a GSFancyText class or method name in Xcode, to preview or link to the documentation page.

To create documentation and docset based on the latest code, install Doxygen and run the script GSFancyText/docs/create.rb
A new docset will be created and installed, and HTML based documentations are available at:
GSFancyText/docs/Doxygen/output/html



Unit Test Coverage
==========

A major portion of GSMarkupNode, GSFancyText, GSHTML, GSParsingHelper, GSHierarchicalScan are covered by unit tests.

Methods involving drawing, view displaying, and view frame updating are not covered.

Covered topics:
* Markup text parsing
* Style sheet parsing
* Markup tree construction
* Node replacing/appending/removing
* Style updating
* Line breaking
* HTML unescaping
* Object deep copying


Demo App Screenshot
==========

![GSFancyText Demo App](https://github.com/hulu/GrannySmith/wiki/GSFancyTextDemo.png)


License
==========
Copyright (C) 2013 by Hulu, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.



