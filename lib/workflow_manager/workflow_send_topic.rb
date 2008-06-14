require 'yaml'
require 'rubygems'
gem 'stomp'
require 'stomp'
gem 'stomp_message'
require 'stomp_message'
# This sends the sms to a activemq topic
module WorkflowManager
class WorkflowSendTopic < StompMessage::StompSendTopic
  attr_accessor :result, :a_hash
  #need to define topic, host properly
  @@TOPIC='workflow'
  # must be defined as method in sms_listener
 def initialize(options={})
   # set up variables using hash
    options[:topic] =   options[:topic]==nil ? @@TOPIC : options[:topic]  
    super(options)
    a_hash=options
    self.result=false
   # set_up_jms(options[:topic]) if @javaflag
  end
  def initiate_workflow(msg2,arg_hash)
    
       m=StompMessage::Message.new('stomp_WORKFLOW', msg2.to_yaml)
      # puts "message is initiate workflow #{m.to_xml}"
      #  billing_sender.setup_auto_close
       wftimeout=25
       arg_hash= {} if arg_hash==nil
        msg_received_flag =false
        result=false
       # puts "Workflow Send topic #{msg2.to_yaml}"
        if @javaflag
         result =jms_msg_result(m) 
        else
        result=self.send_topic_ack(m,arg_hash,wftimeout-1) 
      end
        result
  end

 

 
end #class
end #module