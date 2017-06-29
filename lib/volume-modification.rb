require 'aws-sdk'
require 'pp'

def wait_until(action, done_check)
  loop do
    if done_check.(action.())
      return true
    end

    sleep(1)
    print '.'
  end
end

def get_volume_modification(client, volume_id)
  ->() do
    client
      .describe_volumes_modifications(volume_ids: [volume_id])
      .volumes_modifications
      .first
  end
end

def volume_mod_completed
  ->(volume_mod) { volume_mod&.modification_state == 'completed' }
end

client = Aws::EC2::Client.new(
    access_key_id:  ENV['AWS_ACCESS_KEY_ID'],
    secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
    region: ENV['AWS_REGION']
)

puts 'Creating new volume ...'
vol_created = client.create_volume({
    availability_zone: "eu-central-1b",
    size: 1,
    volume_type: "gp2",
})

client.wait_until(:volume_available, volume_ids: [vol_created.volume_id])

puts 'Volume modifications before modifying is applied:'
pp client.describe_volumes_modifications(
   filters: [{
        name: 'volume-id',
        values: [vol_created.volume_id],
    }]
)

start = Time.now

puts 'Modifying volume'
pp client.modify_volume( volume_id: vol_created.volume_id, size: 2)

puts 'Waiting until modification has been completed'
wait_until(
    get_volume_modification(client, vol_created.volume_id),
    volume_mod_completed
)

puts "\nModification took: #{Time.now - start}"
