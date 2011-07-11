module AMQP
  # Monkey-patch to strip opts[:no_declare] after the Exchange has been created.
  # If we don't do it, we will encounter an error that the exchange has already
  # been created with different options (the only difference being the presence
  # of :no_exchange).
  class Exchange < AMQ::Client::Exchange
    alias :orig_initialize :initialize
    def initialize(channel, type, name, opts = {}, &block)
      orig_initialize(channel, type, name, opts, &block)
      @opts.delete(:no_declare)
    end
  end

  class Queue

    alias :orig_initialize :initialize
    def initialize(channel, name = AMQ::Protocol::EMPTY_STRING, opts = {}, &block)
      opts.delete(:no_declare)
      orig_initialize(channel, name, opts, &block)
    end
    
    # Asks the broker to redeliver all unacknowledged messages on a
    # specified channel. Zero or more messages may be redelivered.
    #
    # * requeue (default false)
    # If this parameter is false, the message will be redelivered to the original recipient.
    # If this flag is true, the server will attempt to requeue the message, potentially then
    # delivering it to an alternative subscriber.
    #
    def recover(requeue = false)
      channel.once_open{
        channel.recover(true) # rabbitmq (as of 2.5.1) does not support requeue = false yet.
      }
      self
    end
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
      MQ.new(connection) # ideally AMQP::Channel.new(...) but MQ used in specs
    end
  end
end
