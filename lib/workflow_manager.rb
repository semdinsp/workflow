#$:.unshift File.dirname(__FILE__)
#puts  "i am " + File.dirname(__FILE__)

Dir[File.join(File.dirname(__FILE__), 'workflow_manager/**/*.rb')].sort.each { |lib| 
   require lib }
module WorkflowManager
  
end