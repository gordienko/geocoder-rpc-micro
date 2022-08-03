# frozen_string_literal: true

require 'pry'
require 'bunny'
require 'json'

# Geocoder Server
#
class GeocoderServer
  def initialize
    @connection = Bunny.new
    @connection.start
    @channel = @connection.create_channel(nil, 10)
  end

  def start(queue_name)
    @queue = channel.queue(queue_name)
    @exchange = channel.default_exchange
    subscribe_to_queue
  end

  def stop
    channel.close
    connection.close
  end

  def loop_forever
    # This loop only exists to keep the main thread
    # alive. Many real world apps won't need this.
    loop { sleep 5 }
  end

  private

  attr_reader :channel, :exchange, :queue, :connection

  def subscribe_to_queue
    queue.subscribe do |_delivery_info, properties, payload|
      payload = JSON(payload)
      result = Geocoder.geocode(payload['city'])

      exchange.publish(
        { lon: result.first, lat: result.last }.to_json,
        routing_key: properties.reply_to,
        correlation_id: properties.correlation_id
      )
    end
  end
end
