module AMQP
  class Queue
    
    # Monkey patch to add :no_declare => true for new queue objects. See the
    # explanation for MQ::Exchange#initialize below.
    # def initialize(mq, name, opts = {})
    #       @mq = mq
    #       @opts = opts
    #       @name = name unless name.empty?
    #       @bindings ||= {}
    # #      @mq.queues << self if @mq.queues.empty?
    #       @mq.callback{
    #         @mq.send Protocol::Queue::Declare.new({ :queue => name,
    #                                                 :nowait => true }.merge(opts))
    #       } unless opts[:no_declare]
    #     end
    # Asks the broker to redeliver all unacknowledged messages on a
    # specifieid channel. Zero or more messages may be redelivered.
    #
    # * requeue (default false)
    # If this parameter is false, the message will be redelivered to the original recipient.
    # If this flag is true, the server will attempt to requeue the message, potentially then
    # delivering it to an alternative subscriber.
    #
    def recover(requeue = false )
      @mq.callback{
        @mq.send Protocol::Basic::Recover.new(:requeue => requeue)
      }
      self
    end
  end
  
  def close_connection
    @connection.close
  end
end

module Nanite
  module AMQPHelper
    def start_amqp(options)
      connection = AMQP.connect({
        :user => options[:user],
        :pass => options[:pass],
        :vhost => options[:vhost],
        :host => options[:host],
        :port => (options[:port] || ::AMQP::Client::AMQP_PORTS["amqp"]).to_i,
        :insist => options[:insist] || false,
        :retry => options[:retry] || 5,
        :connection_status => options[:connection_callback] || proc {|event| 
          Nanite::Log.debug("Connected to MQ") if event == :connected
          Nanite::Log.debug("Disconnected from MQ") if event == :disconnected
        }
      })
      MQ.new(connection)
    end
  end
end
