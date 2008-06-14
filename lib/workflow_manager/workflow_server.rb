require 'yaml'
require 'rubygems'
gem 'stomp'
require 'stomp'
gem 'stomp_message'
require 'stomp_message'

module WorkflowManager
class WorkflowServer < StompMessage::StompZActiveRecordServer
  attr_accessor :test #:mmsc_host, :mmsc_port, :mmsc_url
  def initialize(options={})
    self.model_list = []
    self.model_list << "workitem_record.rb"
      ver_num= self.version_number.to_s + '/'
   options[:root_path]=ENV['JRUBY_HOME']+'/lib/ruby/gems/1.8/gems/workflow_manager-'+ ver_num if RUBY_PLATFORM =~ /java/
    super(options)
    puts "#{self.class} #{ver_num} initializing"
  end

 def setup_thread_specific_items(mythread_number)
    super(mythread_number)
    puts " ----creating workflow manager for #{get_id} name: wfe_#{mythread_number}"
     self.variables[get_id][:wfe]= WorkflowManager::Engine.new("wfe_#{mythread_number}")
  end
 
  def stomp_WORKFLOW(msg, stomp_msg)
     puts "about to process msg is #{stomp_msg.body} messsage body #{msg.body}"
     #mms=MmscManager::MmsStompMessage.load_xml(stomp_msg.body)
     # puts "#{Thread.current[:name]}sending mms #{mms.get_mms_message}" if @debug
      res=self.variables[get_id][:wfe].launch(msg.body)
      reply_msg = StompMessage::Message.new('stomp_REPLY', res)
      puts "response message: #{reply_msg.to_xml}" 
      [true, reply_msg]
    #  check_response(res,mms)
    # res
  end
  
end # workflow server

end #module
