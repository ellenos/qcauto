namespace :monitor do
desc "Remove jobs from AutoQC queues"

task :remove_from_queues => :environment do

require 'net/http'
require 'rubygems'

# Constants
RailsServer = 'http://prod-qtp114:3000/qtp_resources/create'
QcQueue = '\\\\prodbuild2\\build2\\live\\status\\QcAutomation\\Queues'


def post_qcauto(dbCode, dbLabel, email, email_include)
  url = URI.parse(RailsServer)
  req = Net::HTTP::Post.new(url.path)
  req.set_form_data("qtp_resource[dbcode]"=>dbCode, "qtp_resource[Email]"=>email, "label"=>dbLabel, "qtp_resource[EmailIncludeAll]"=>email_include, "qtp_resource[coverage]"=>"")
  # set the request environment custom to say its from a script, not the form
  req['user-agent'] = 'qcauto'
  
  res = Net::HTTP.new(url.host, url.port).start {|http|
    http.request(req) }
    
  rescue Exception
    Rails.logger.info "AUTOQC: Problem connecting to AutoQC server " + RailsServer
  
end



###################
#--Get oldest file 
#   Returns nil if no file
def get_from_queue(queue_name)
  oldest = nil
  oldestfilelist = {}
  q_path =QcQueue + '\\' + queue_name
  contains = Dir.new(q_path).entries
  contains.each do |product|
    if !FileTest.directory?(product)
      $filedate = File.mtime(q_path + '\\' + product)
      oldestfilelist[ $filedate.to_i ] = product
    end
  end
  if !oldestfilelist.empty? then
    t = oldestfilelist.sort.to_a
    oldest = t[0][1]
  end
  return oldest
end

def remove_oldest_file(oldest)
    begin
      # delete it from the queue
      File.delete(oldest)
    rescue
      Rails.logger.info "AUTOQC: Problem deleting file" + oldest
    end
end

def queue_it(the_queue, label)
  email = "None"
  email_include = 1
  oldest = get_from_queue(the_queue)
  q_path =QcQueue + '\\' + the_queue
  if oldest != nil then
    remove_oldest_file(q_path + '\\' + oldest)
    #Rails.logger.info "AUTOQC: Deleted the oldest file: " + q_path + '\\' + oldest
    post_qcauto(oldest, label, email, email_include)
  end
end

# go thru each queue removing one file
queue_it('LiveQueue', 'live')

queue_it('RebuildLiveQueue', 'rebuildlive')

queue_it('LiveQcQueue', 'liveqc')

queue_it('RebuildQueue', 'rebuild')

queue_it('RebuildQcQueue', 'rebuildqc')
end

end
