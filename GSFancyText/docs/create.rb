#!/usr/bin/env ruby

# Script to generate documentations and install it in Xcode.
# To create docset, install Doxygen first.
# And then run the following command:
# ruby create.rb

FILE_PATH = File.expand_path(File.dirname(__FILE__))
DOXYGEN_PATH = "#{FILE_PATH}/Doxygen"
OUTPUT_PATH = "#{DOXYGEN_PATH}/output/html"

`cd #{DOXYGEN_PATH} && doxygen config && cd #{OUTPUT_PATH} && echo "making" && pwd && make && make install`

