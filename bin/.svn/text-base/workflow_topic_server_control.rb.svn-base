#!/usr/bin/env ruby
require 'optparse'
require 'rubygems'
gem 'workflow_manager'
require 'workflow_manager'
gem 'daemons'
require 'daemons'
 puts "#{ARGV[0]} Workflow Topic server:"
  #  begin
  options = {
  #  :ontop => true,
  #  :multiple => true,
    :monitor => true
    
  }
     Daemons.run(File.join(File.dirname(__FILE__), 'workflow_topic_server.rb'), options)
     
        

   
    
