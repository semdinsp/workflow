require 'yaml'
require 'rubygems'


gem 'stomp_message'
require 'stomp_message'
gem 'ficonab_tools'
require 'ficonab_tools'
#puts 'after billing gem'

gem 'ruote'
require 'openwfe/engine/engine'
#require 'openwfe/engine/file_persisted_engine'
require 'openwfe/participants/participants'
require 'openwfe/participants/enoparticipants'
gem 'ruote-extras'
require 'openwfe/extras/participants/activeparticipants'
require 'socket'
module WorkflowManager
class ActiveTracker < OpenWFE::Extras::ActiveStoreParticipant
  # just bang it into the database
 
  def consume (workitem)
      debug=true
     # workitem.save
       puts "-----> ActiveTracker consume " if debug
       awi=nil
       begin
       awi = OpenWFE::Extras::Workitem.from_owfe_workitem(workitem)
       awi.store_name=@store_name
    #   awi.replace_fields(workitem.attributes)
       awi.save
     rescue Exception => e
       puts "exception found #{e.message}"
       puts "backtrace #{e.backtrace}"
     end
         puts "<----- ActiveTracker consume " if debug
      awi=nil
      reply_to_engine(workitem)
       
      
  end
  def reply_to_engine (workitem)
           debug=true
           # super workitem    #.as_owfe_workitem
           # workitem.save
                #
                 puts "<----- ActiveTracker reply engine " if debug
                # replies to the workflow engine   
               get_engine.reply(workitem)
  end
end
class Engine 
attr_accessor :wfe_engine, :thread_name, :final_response, :workflow_hash, :conn_mgr, :start_time
def initialize(tn)
  # puts "in initialize engine"
   self.thread_name=tn
   ac = {}
   self.final_response={}
   ac[:work_directory] = "work"
   ac[:ruby_eval_allowed] = true
   ac[:remote_definitions_allowed] = true  # remote url
   create_workflow_hash
   # @bs_mgr=nil
        if RUBY_PLATFORM =~ /java/
            @javaflag= @java_flag=true
         else
           @javaflag= @java_flag=false
         end
#   self.wfe_engine = OpenWFE::CachedFilePersistedEngine.new(ac)
   self.wfe_engine = OpenWFE::Engine.new(ac)
   self.reg_participants
   puts "#{self.thread_name} ready"
   self.conn_mgr=FiconabTools::ConnectionManager.instance()
   self.conn_mgr.setup(['sms', 'billing'])
   @debug=true;
end 
# create the hash of work flows to run, details, urls, etc
def create_workflow_hash
    self.workflow_hash= {}
    
    # define test flow
    # self.workflow_hash[:test]={}
    # self.workflow_hash[:test][:type]='RUBY'   #or url
    # self.workflow_hash[:test][:process_flow]= TheProcessDefinition0
      # define test2 flow
    #    self.workflow_hash[:test2]={}
     #   self.workflow_hash[:test2][:type]='RUBY'   #or url
     #   self.workflow_hash[:test2][:process_flow]= TheProcessDefinition2
     # define balance transfer flow
       ids= [:transfer, :pasaload, :load, :dispense_pin, :dealer_load, :balance_inquiry, :worktest]
          ids.each { |i|   
               self.workflow_hash[i]={}
                self.workflow_hash[i][:type]='URL'   #or url
                 self.workflow_hash[i][:url]= "process/process_definitions/#{i.to_s}.xml"
                 self.workflow_hash[i][:host]= 'localhost'
                  self.workflow_hash[i][:host]= 'svbalance.cure.com.ph' if Socket.gethostname == "svbalance.cure.com.ph" 
                   self.workflow_hash[i][:port]= '8080'
             }
      
end
 #def manage_jms_variables
 #  puts "createing bs mgr send topic #{@bs_mgr}"
 #  @bs_mgr=BillingWebService::BillingSendTopic.new({:topic => 'billing'}) if  @bs_mgr==nil
 #  puts "createing sms  send topic #{@bs_mgr}"
 #   @sms_mgr=SmscManager::SmsSendTopic.new({:topic => 'sms'}) if  @sms_mgr==nil
 #end
def billing_action(type,msisdn,value,dest='zzz')
       #  puts "BILLING ACTION: #{type} #{msisdn} #{value}"
         args={}  #add host etc here
         puts "----> in billing action #{type} msisdn #{msisdn}"
         result=[]
          begin
            res="bad message from billing system".to_yaml
            puts "JAVA flag is #{@java_flag}"
         # if @java_flag
                
                 res= self.conn_mgr.my_connections['billing'].send(type,msisdn,value,dest,args)
         #   else
         #   bs=BillingWebService::BillingSendTopic.new(args)
          #  res=bs.send(type,msisdn,value,dest,args)
           #  bs.disconnect_stomp
        #    end   
           
             result = YAML.load(res)
             res=nil
            
          rescue Exception => e
           
            result[0]='false'
            result[1]="billing action: #{res} #{e.message}"
          end
        #   result = YAML.load
         puts "<----- result from billing action is #{result.to_s} for: #{type} #{msisdn} #{value} #{dest}" 
         result
end
def send_sms(msg, dest,src)
   r=true
  begin
        sms=SmscManager::Sms.new(msg,dest,src)
        # if @java_flag
                #manage_jms_variables if @sms_mgr==nil
                val= self.conn_mgr.my_connections['sms'].send_topic_sms(sms)
       #    else
         #  sms_sender= SmscManager::SmsSendTopic.new
        #    val= sms_sender.send_topic_sms(sms)
         #   sms_sender.disconnect_stomp
        #   end
         puts  "sms result is #{val}" if @debug
        r= "response: #{val.to_s}"
      
   rescue Exception => e
      puts "exception found #{e.message} #{e.backtrace}" 
      r=false
   end
   r
end
#
# register a participant per workitem store
def reg_participants
    puts "#{self.thread_name} engine particpant setup"
    # SETUP MUST BE CALLED.
    # ANY exceptions or errors in the participants aborts the workflow and are hard to find.  YOU HAVE BEEN WARNED
    self.wfe_engine.register_participant :setup do |workitem|
         puts "------> setup got a workitem..."  if @debug
          target = ['scott.sproule@cure.com.ph', 'jan.ardosa@cure.com.ph']
          workitem.sms_source = "992"
          workitem.my_hostname = Socket.gethostname 
         workitem.sms_message = "no message"
          workitem.email_target = target
 #         workitem.email_from = "scott.sproule@cure.com.ph"
         workitem.workflow_status = "false"
          workitem.process_result = "false"
         workitem.final_response="failure"
         puts "<------- end of setup" if @debug
     end
   #   self.wfe_engine.register_participant( 
    #     'bal_transfer', 
   #      OpenWFE::Extras::ActiveStoreParticipant.new('bal_transfer
#self.wfe_engine.register_participant :bal_transfer do |workitem|
#          puts "bal_transfer got a workitem..."
#          workitem.particpant = 'bal_transfer'
#           workitem.store = 'bal_transfer'
#           workitem.save
#end
#FIX LATER
 s=%w(bal_transfer pasaload dispense_pin dealer_load load process2 )
 s.each {|i|# self.wfe_engine.register_participant( "#{i}_store",      ActiveTracker.new("#{i}")) 
            puts "---REG PARticipant #{i}_store   "
            self.wfe_engine.register_participant "#{i}_store" do |workitem|
                  puts "#{i}_store got a workitem..."
                  #workitem.monkey_comment = "this thing looks interesting"
              end 
               }
         
      self.wfe_engine.register_participant :credit do |workitem|
            puts "----> credit action got a workitem..." if @debug
             workitem.credit_result=false
             res= self.billing_action('credit',workitem.credit_msisdn,workitem.peso_value )
             puts "action credit msisdn #{workitem.credit_msisdn} value #{workitem.peso_value} RES: #{res}"
              puts "<----credit action finished res #{res}..."  if @debug
             workitem.process_result=res
        end
          self.wfe_engine.register_participant :pasaload do |workitem|
                puts "----> pasaload action got a workitem..." if @debug
                 workitem.process_result=false
                  workitem.sms_source = "992"
                   puts "before action  pasaload msisdn #{workitem.source_msisdn} value #{workitem.value} dest: #{workitem.dest_msisdn}"
                 res= self.billing_action('pasaload',workitem.source_msisdn,workitem.value, workitem.dest_msisdn)
                 puts "action pasaload msisdn #{workitem.source_msisdn} value #{workitem.value} dest: #{workitem.dest_msisdn} RES: #{res}"
                  puts "<----pasaload action finished res #{res}..."  if @debug
                    workitem.process_message=res.to_yaml
                    workitem.final_response="all ok"  if res[0]=='true'
            
            end
             self.wfe_engine.register_participant :dealer_load do |workitem|
                    puts "----> dealer load action got a workitem..." if @debug
                     workitem.process_result=false
                      workitem.sms_source = "913"
                       puts "before action  dealer load msisdn #{workitem.source_msisdn} value #{workitem.value} dest: #{workitem.dest_msisdn}"
                     res= self.billing_action('dealer_load',workitem.source_msisdn,workitem.value, workitem.dest_msisdn)
                     puts "action dealer load msisdn #{workitem.source_msisdn} value #{workitem.value} dest: #{workitem.dest_msisdn} RES: #{res}"
                      puts "<----dealer load action finished res #{res}..."  if @debug
                        workitem.process_message=res.to_yaml
                        workitem.final_response="all ok"  if res[0]=='true'
                end
            self.wfe_engine.register_participant :load do |workitem|
                  puts "----> load action got a workitem..." if @debug
                   workitem.process_result=false
                    workitem.sms_source = "990"
                     puts "before action  load msisdn #{workitem.source_msisdn} value #{workitem.value} dest: #{workitem.dest_msisdn}"
                   res= self.billing_action('load',workitem.source_msisdn,workitem.value, workitem.dest_msisdn)
                   puts "action load msisdn #{workitem.source_msisdn} value #{workitem.value} dest: #{workitem.dest_msisdn} RES: #{res}"
                    puts "<----load action finished res #{res}..."  if @debug
                        workitem.process_message=res.to_yaml
                        workitem.final_response="all ok"  if res[0]=='true'
                       workitem.loadvalue=res[1] if res[0]=='true'
                   
              end
               self.wfe_engine.register_participant :dispense_pin do |workitem|
                      puts "----> dispense_pin action got a workitem..." if @debug
                       workitem.process_result=false
                         puts "before action  dispense_pin msisdn #{workitem.source_msisdn} value #{workitem.value} dest: #{workitem.dest_msisdn}"
                       res= self.billing_action('dispense_pin', workitem.source_msisdn, workitem.value, workitem.dest_msisdn)
                       puts "action dispense_pin msisdn #{workitem.source_msisdn} value #{workitem.value} dest: #{workitem.dest_msisdn} RES: #{res.to_s}"
                        puts "<----load action finished res #{res}..."  if @debug
                     #   result = YAML.load
                           workitem.process_message=res.to_yaml
                          workitem.final_response="all ok"  if res[0]=='true'
                         workitem.pin=res[1] if res[0]=='true'
                      
                  end
              
        
          self.wfe_engine.register_participant :debit do |workitem|
                puts "----> debit action got a workitem..."  if @debug
                 workitem.debit_result=false 
                 # peso charge  -- could be variable
                value=-1*workitem.peso_value.to_i-1
                res=self.billing_action('debit',workitem.debit_msisdn,value.to_s )
                 puts "action debit msisdn #{workitem.debit_msisdn} value #{workitem.peso_value} RES: #{res}"
                workitem.process_result=res
                 workitem.process_message=res
                 puts "<----debit action finsihed res #{res}..."  if @debug
            end
    self.wfe_engine.register_participant :monkey do |workitem|
         puts "monkey got a workitem..."
         workitem.monkey_comment = "this thing looks interesting"
     end
        self.wfe_engine.register_participant :intprocess2 do |workitem|
            puts "process2 got a workitem..."
            workitem.process2_comment = "yeah process 2"
        end
     self.wfe_engine.register_participant :bob do |workitem|
         puts "bob got a workitem..."
         workitem.bob_comment = "not for me, I prefer VB"
         workitem.bob_comment2 = "Bob rules"
            workitem.final_response = "all ok"
         self.final_response[workitem.fei.workflow_instance_id.to_s] = workitem.final_response
     end
      self.wfe_engine.register_participant :sms do |workitem|
          puts "sms got a workitem..."
          puts "sms #{workitem.sms_destination} message: #{workitem.sms_message}"
          res=send_sms(workitem.sms_message,workitem.sms_destination, workitem.sms_source)
          workitem.problem=!res 
      end
      # needs workitem.email_target  set
        mailp=OpenWFE::MailParticipant.new(
             :smtp_server => "mail2.cure.com.ph",
             :smtp_port => 25,
            :from_address => "scott.sproule@cure.com.ph"
         ) do |workitem|
           puts "----> mail got workitem"
           s = ""
            duration=Time.now-self.start_time
            s << "Subject: Workflow PROCESS [#{workitem.process_name}] [#{workitem.final_response}]\n\n"
           s <<  "result is #{workitem.final_response}\n"
           s <<  "Processing Time so far: #{duration} \n"
           s << "summary of process #{workitem.fei.workflow_instance_id}\n"
           workitem.attributes.each do |k, v|
               s << " - #{k} : '#{v}'\n"
           end           
          s << "Time: #{Time.new.to_s}\n"
          puts "----> leaving mail"
          s
         end
         self.wfe_engine.register_participant( 
                    "mail",     mailp)
  
           
       self.wfe_engine.register_participant :debug do |workitem|
            puts "--->debug got a workitem..."
            puts "--status of process #{workitem.fei.workflow_instance_id}"
                  workitem.attributes.each do |k, v|
                      puts " - #{k} : '#{v}'"
                  end
            puts '<------end of debug'
        end
    # summarize must be called to set final_response
     self.wfe_engine.register_participant :summarize do |workitem|
          puts "---->Summarize got a workitem..."
         # workitem.final_response="all ok" if workitem.attributes['process_result']=='true' 
          puts  "result is #{workitem.final_response}"
          self.final_response[workitem.fei.workflow_instance_id.to_s] = workitem.process_message
          puts "summary of process #{workitem.fei.workflow_instance_id}"
                workitem.attributes.each do |k, v|
                   # next unless k.match ".*_comment$"
                    puts " - #{k} : '#{v}'"
                end
         puts '<-------end of summary'
      end
      self.wfe_engine.register_participant :reverse_charges do |workitem|
            puts "-----> reverse got a workitem..."
             res=false
             if workitem.attributes['debit_result']=='true'
                 value=1*workitem.peso_value.to_i+1
                 res=self.billing_action('credit',workitem.debit_msisdn,value.to_s )
                 puts "return from reversing debit: #{res}"
               end
             if   workitem.attributes['credit_result']=='true'
                 res= self.billing_action('debit',workitem.credit_msisdn,workitem.peso_value )
                   puts "return from reversing credit: #{res}"
             end
            puts 'end of reverse charges'
        end
         self.wfe_engine.register_participant :process_failure do |workitem|
              puts "----> process_failure got a workitem..."
              res=false
               #  res=send_sms("There was a problem with your request (process id:'#{workitem.fei.workflow_instance_id})'.  Call *999 if you require further information", workitem.source_msisdn, workitem.sms_source)
                puts "<------ out of process failure"
            end
           self.wfe_engine.register_participant :inform_success_pasa do |workitem|
                puts "---->Inform_success_pasa got a workitem..."
                res=true
                if workitem.final_response=="all ok"
                #   res=send_sms("You have sent #{workitem.value} pesos to #{workitem.dest_msisdn}: (process id:'#{workitem.fei.workflow_instance_id})'", workitem.source_msisdn, workitem.sms_source)
                    res=send_sms("You have received #{workitem.value} pesos from #{workitem.source_msisdn}: To check your balance, text BAL to 991", workitem.dest_msisdn,workitem.sms_source) and res
                    #(process id:#{workitem.fei.workflow_instance_id})
                end
                puts "<---- end inform_sucess"
                res
          end
            self.wfe_engine.register_participant :inform_success_dispense_pin do |workitem|
                  puts "---->Inform_success_dispense_pin got a workitem..."
                  res=false
                  if workitem.final_response=="all ok"
                     res=send_sms("Your pin is #{workitem.loadvalue}   via tracking process id:'#{workitem.fei.workflow_instance_id}'", workitem.source_msisdn, workitem.sms_source)
                    
                  end
                  puts "<---- end inform_success_dispense_pin"
                  res
            end
            self.wfe_engine.register_participant :inform_success_load do |workitem|
                  puts "---->Inform_success_load got a workitem..."
                  res=false
                  if workitem.final_response=="all ok"
                  #   res=send_sms("You have loaded #{workitem.loadvalue} pesos (process id: #{workitem.fei.workflow_instance_id})", workitem.source_msisdn, workitem.sms_source)
                    
                  end
                  puts "<---- end inform_sucess"
                  res
            end
       self.wfe_engine.register_participant :inform_success do |workitem|
            puts "Inform_success got a workitem..."
            res=false
            if workitem.final_response=="all ok"
               res=send_sms("You have sent #{workitem.peso_value} peso to #{workitem.credit_msisdn}:  (process id:'#{workitem.fei.workflow_instance_id}')", workitem.debit_msisdn, workitem.sms_source)
                res=send_sms("You have received #{workitem.peso_value} pesos from #{workitem.debit_msisdn}: tracking process id:'#{workitem.fei.workflow_instance_id}' ",workitem.credit_msisdn,workitem.sms_source) and res
            end
      end
      
end
# this  should read xml files
#class TheProcessDefinition0 < OpenWFE::ProcessDefinition
 #      sequence do
 #           participant :setup
 #            participant :detail
 #          concurrence do
  #             participant :monkey
  #             participant :bob
  #         end
  #         participant :sms
  #         participant :summarize
  #     end
  # end
   
def manage_processes
  puts "in manage process"
end
def build_launch_item(msg)
  msg_hash=YAML.load(msg)
   id = :test2 if msg== "process2"
   id = :test if msg== "process"
   self.start_time=Time.now
  # puts msg_hash.to_s 
   msg_hash.each {|k,v| puts "key is #{k} value is #{v}"}
  # puts "process:  #{msg_hash[:process]}"
  case msg_hash[:process]
    when   "balance_transfer"
      id = :transfer
      when   "balance_inquiry"
        id = :balance_inquiry
    when  "pasaload"
      id = :pasaload
    when "loadpin"
     id = :load 
   when "dealer_load"
      id = :dealer_load 
   when "dispense_pin"
    id = :dispense_pin 
   else
      puts "UNKNOWN PROCESS in switch"
       raise "unknown process: #{msg_hash[:process]}" if id==nil
    end
 
  case self.workflow_hash[id][:type]
     when   "RUBY"
       li= OpenWFE::LaunchItem.new(self.workflow_hash[id][:process_flow])
      when   "URL"
           li  = OpenWFE::LaunchItem.new
           url = "http://" + self.workflow_hash[id][:host] + ':' + self.workflow_hash[id][:port] +'/' + self.workflow_hash[id][:url]
           li.workflow_definition_url = url 
           puts "url is: #{url}"
           msg_hash.each {|k,v|   eval("li.#{k}=v") }
      else   
        raise 'bad type in build launch item'
      end
      li.launcher = 'admin'
      li.process_name = "#{id}"

   #   li.__initial_message = msg  #no need to add initial message to work item..
    li
end
def launch(message_string)
     puts "#{self.thread_name} #{Time.now} received #{message_string}"
       li=nil
     begin
        li=build_launch_item(message_string)
        puts "#{self.thread_name} #{Time.now} built li check for object #{li.kind_of?(OpenWFE::LaunchItem)} class #{li.class.to_s}"
        fei = self.wfe_engine.launch li
        a=['false']  #trigger for bad result
        self.final_response[fei.workflow_instance_id.to_s]=a.to_yaml
        puts "#{self.thread_name} #{Time.now} started process '#{fei.workflow_instance_id}'"

        self.wfe_engine.wait_for fei
        puts "#{self.thread_name} #{Time.now} finished process '#{fei.workflow_instance_id}'"
      rescue RuntimeError => r
        puts "Runtimeerror #{r.message}"
        raise r
     rescue Exception => e
        puts  "message #{e.message} #{e.class} #{e.backtrace}"
        puts  "#{self.thread_name} #{Time.now} finished process '#{fei.workflow_instance_id}' found exception #{e.message}"
     end 
     li=nil
     self.final_response[fei.workflow_instance_id.to_s]
end
  

end  #module
end # classs
