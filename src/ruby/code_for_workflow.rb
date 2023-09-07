# frozen_string_literal: true

STATUS_COMPLETE = 1
STATUS_FAILED = 2
STATUS_ERROR = 3

# Step: User and IP
def get_params(inputs, outputs)
  outputs['ipaddress'] = inputs['File']['peer_ip']
  tags = JSON.parse(inputs['File']['tags'])
  outputs['username'] = tags['aspera']['shares']['user']
  STATUS_COMPLETE
end

# Step: Allowed Addresses
def get_user_white_list(inputs, outputs)
  user_name = inputs['username']
  user_to_groups = JSON.parse(File.read(inputs['user_to_group_json']))
  white_list_by_name = YAML.load_file(inputs['whitelist_yaml'])
  white_list = []
  white_list.concat(white_list_by_name[user_name]) if white_list_by_name.key?(user_name)
  if user_to_groups.key?(user_name)
    user_to_groups[user_name].each do |group|
      white_list.concat(white_list_by_name[group]) if white_list_by_name.key?(group)
    end
  end
  outputs['allowed_list'] = white_list
  return STATUS_COMPLETE
end

## Step: User-Group Allowed
def check_filters(inputs, outputs)
  # lambda to convert ip address to integer
  ip_to_integer = ->(ip) { ip.split('.').map(&:to_i).inject { |result, octet| (result << 8) + octet } }
  # lambda to validate an ipv4 address format
  valid_ip = ->(ip) { !/^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/.match(ip).nil? }
  # This code takes 2 parameters
  # @param ip_address : the ip address to check
  # @param ip_or_range : the ip address or range to check against
  ip_address = inputs['user_ip']
  return STATUS_ERROR unless valid_ip.call(ip_address)

  allowed_list = inputs['allowed_list']
  return STATUS_FAILED, 'No allowed IP or Mask found' if allowed_list.empty?

  allowed_list.each do |ip_or_range|
    # split the ip address and range into ip and mask bits
    range_ip, mask_bits = ip_or_range.split('/')
    # number of bits on right to dismiss for comparison
    shift_bits = mask_bits.nil? ? 0 : 32 - mask_bits.to_i
    # return STATUS_ERROR unless valid_ip.call(range_ip)
    return STATUS_COMPLETE if ip_to_integer.call(range_ip) >> shift_bits == ip_to_integer.call(ip_address) >> shift_bits
  end
  return STATUS_FAILED, "No match found for #{ip_address} in #{allowed_list}"
end

get_user_white_list(
  { 'username' => 'user1', 'user_to_group_json' => 'user_to_group.json', 'whitelist_yaml' => 'whitelist.yaml' }, {}
)
