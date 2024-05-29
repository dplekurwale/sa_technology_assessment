#!/bin/sh
# Ensure bundler is installed
gem install bundler

# Install the necessary gems
bundle install

# Run the Ruby script
# Run the Ruby commands
ruby -e "
require './questionnaire.rb'
questionnaire = Questionnaire.new
questionnaire.do_prompt
questionnaire.do_report
"
