#!/usr/bin/env ruby
require 'optparse'
def usage
    puts "Usage: workflow_topic_server.rb to start up mmsc  " 
    puts "Usage: mms_topic_server.rb path_to_processs_rails_app environment " 
      puts "eg: workflow_topic_server.rb ./ development " 
   exit
end

require 'rubygems'
gem 'workflow_manager'
require 'workflow_manager'
    env_setting = ARGV[1] || "production"
    path_setting = ARGV[0] || "/opt/local/rails_apps/process/current/"
   puts "Starting Workflow Topic Server topic server:"
  
    WorkflowManager::WorkflowServer.new({:topic => '/topic/workflow', :thread_count => '4', :env => env_setting, :root_path => path_setting}).run
  
   
    
