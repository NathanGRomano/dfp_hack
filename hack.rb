#! /usr/bin/env ruby

require 'optparse'
require 'dfp_api'

NAME = "hack"
API_VERSION = :v201403
PAGE_SIZE = 500
ADVERTISER_ID = 15781698
NATHAN_ROMANO = 113047698
COMPANY_PROFILES_AD_UNIT_ID = 24115338
COLUMBUS_OH_LOCATION_ID = 1023640
T_VAR_ID = 391218

$options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{NAME}.rb [options]"
  opts.on("-e", "--emid [EMID]", String, "The emid of the company") do |v|
    $options[:emid] = v
  end
  opts.on("-p", "--product [PRODUCT]", String, "The product of the company") do |v|
    $options[:product] = v
  end
  opts.on("-k", "--keyword [KEYWORD]", String, "The keywords of the company") do |v|
    if !$options[:keywords]
      $options[:keywords] = v.split ','
    else
      $options[:keywords].concat v.split ','
    end
  end
end.parse!

puts $options

if !$options.length
  puts '--emid and --product need to be set'
  exit
end

if !$options[:emid]
  puts '--emid must be set'
  exit
end

if !$options[:product]
  puts '--product must be set'
  exit
end

if !$options[:keywords]
  puts '--keywords must be set'
  exit
end

puts 'Generating an order for emid: %s, product: %s' % [$options[:emid], $options[:product]]

$dfp = DfpApi::Api.new()

# authorization

ask_to_update = false

token = $dfp.authorize() do |auth_url|
  ask_to_update = true
  puts "Hit Auth error, please navigate to URL:\n\t%s " % auth_url
  print 'log in and type the verification code: '
  verification_code = gets.chomp
  verification_code
end

if token and ask_to_update
  print "\nWould you like to update your dfp_api.yml to save " +
      "OAuth2 credentials? (y/N): "
  response = gets.chomp
  if ('y'.casecmp(response) == 0) or ('yes'.casecmp(response) == 0)
    $dfp.save_oauth2_token(token)
    puts 'OAuth2 token is now saved to ~/dfp_api.yml and will be ' +
        'automatically used by the library.'
  end
end

def print_line_item_information
  # get a line itema nd output it
  line_item_service = $dfp.service(:LineItemService, API_VERSION)
  statement = {
    :query => "WHERE Name = 'API Create Line Item 2014-05-05T17:15:55-04:00' LIMIT 1"
  }
  page = line_item_service.get_line_items_by_statement(statement)
  puts JSON.pretty_generate page
end

# get the company
 
def print_companies_information 
  puts 'Getting the Companies...'
  company_service = $dfp.service(:CompanyService, API_VERSION)
  offset = 0
  page = {}

  begin
    statement = {:query => "LIMIT %d OFFSET %d" % [PAGE_SIZE, offset]}
    page = company_service.get_companies_by_statement(statement)
    if page[:results]
      offset += PAGE_SIZE
      start_index = page[:start_index]
      page[:results].each_with_index do |company, index|
        puts "%d) Company ID: '%d', name: '%s', type: '%s'" % [index + start_index, company[:id], company[:name], company[:type]]
      end
    end
  end while offset < page[:total_result_set_size]
  # Manta Minute : 15781698
end

def print_users_information 

  # get the users

  puts 'Getting the Users...'
  user_service = $dfp.service(:UserService, API_VERSION)
  offset = 0

  begin
    statement = {:query => "LIMIT %d OFFSET %d" % [PAGE_SIZE, offset]}
    page = user_service.get_users_by_statement(statement)
    if page[:results]
      offset += PAGE_SIZE
      start_index = page[:start_index]
      page[:results].each_with_index do |user, index|
        puts "%d) User ID: '%d', name: '%s', type: '%s', role_name: '%s', role_id: '%d'" % [index + start_index, user[:id], user[:name], user[:email], user[:role_name], user[:role_id] ]
      end
    end
  end while offset < page[:total_result_set_size]
end

def print_user_roles_information 
  # get the roles
  puts 'Getting the Roles...'
  roles = user_service.get_all_roles()
  if roles
    roles.each_with_index do |role, index|
      puts "%d) Role ID: %d, name: %s" % [index, role[:id], role[:name]]
    end
  end

  # get the placements
  puts 'Getting the Placements...'
  placement_service = $dfp.service(:PlacementService, API_VERSION)
  offset = 0

  begin
    statement = {:query => "LIMIT %d OFFSET %d" % [PAGE_SIZE, offset]}
    page = placement_service.get_placements_by_statement(statement)
    if page[:results]
      offset += PAGE_SIZE
      start_index = page[:start_index]
      page[:results].each_with_index do |placement, index|
        puts "%d) Placement ID: '%d', name: '%s'" % [index + start_index, placement[:id], placement[:name] ]
      end
    end
  end while offset < page[:total_result_set_size]
end

# Get the InventoryService.
def print_inventory_information
  inventory_service = $dfp.service(:InventoryService, API_VERSION)

  offset = 0
  page = {}

  begin
    # Create a statement to get one page with current offset.
    statement = {:query => "WHERE Name LIKE 'Company Profiles'  LIMIT %d OFFSET %d" % [PAGE_SIZE, offset]}

    # Get ad units by statement.
    page = inventory_service.get_ad_units_by_statement(statement)

    if page[:results]
      # Increase query offset by page size.
      offset += PAGE_SIZE

      # Get the start index for printout.
      start_index = page[:start_index]

      # Print details about each ad unit in results.
      page[:results].each_with_index do |ad_unit, index|
        puts "%d) Ad unit ID: %d, name: %s, status: %s." %
            [index + start_index, ad_unit[:id],
             ad_unit[:name], ad_unit[:status]]
      end
    end
  end while offset < page[:total_result_set_size]
end


# Get the CustomTargetingService.
puts 'Getting Custom Targeting values...'

def get_custom_targeting_values (keywords) 

  custom_targeting_service = $dfp.service(:CustomTargetingService, API_VERSION)

  clause = []
  $options[:keywords].each do |word|
    clause.push "'"+word+"'"
  end

  page = custom_targeting_service.get_custom_targeting_values_by_statement({ :query => "WHERE name IN ("+clause.join(',')+") LIMIT %d" % [PAGE_SIZE] })

  values = []
  if page[:results]
    # Print details about each value in results.
    page[:results].each_with_index do |custom_targeting_value, index|
      values.push custom_targeting_value[:id]
    end
  end
  
  return values

end

def build_custom_targeting_children (values)

  set = []
  values.each do |value|
    set.push ({
      :xsi_type => 'CustomCriteria',
      :custom_criteria_node_type => 'CustomCriteria',
      :key_id => T_VAR_ID,
      :value_ids => [ value ],
    })
  end

  return set
end


# Create an Order
puts 'Creating an Order...'

order_service = $dfp.service(:OrderService, API_VERSION)
orders = order_service.create_orders([{
  :name => 'API Created Order ' + DateTime.now.to_s,
  :advertiser_id => ADVERTISER_ID,
  :salesperson_id => NATHAN_ROMANO,
  :trafficker_id => NATHAN_ROMANO,
  :status => 'DRAFT'
}])

if orders
  orders.each do |order|
    puts "Order with ID: %d and name \"%s\" was created." % [order[:id], order[:name]]
  end
end

# Create a Line Item

puts 'Creating the Line Item...'
line_item_service = $dfp.service(:LineItemService, API_VERSION)

targeting = {

  :inventory_targeting => {
    :targeted_ad_units => [
      {:ad_unit_id => COMPANY_PROFILES_AD_UNIT_ID,} # company profiles
    ]
#    :targeted_placement_ids => [
#      3548418, # automotive
#      3549618 # manufacturing
#     ]
  },

  :geo_targeting => {
    :targeted_locations => [
      {:id => COLUMBUS_OH_LOCATION_ID}, # columbus, oh
    ]
  },

  :user_domain_targeting => {
    :domains => ['manta.com'],
    :targeted => true
  },

  :day_part_targeting => {
    :time_zone => 'BROWSER',
    :day_parts => [
      {:day_of_week => 'SUNDAY', :start_time => { :hour => 0, :minute => 'ZERO' }, :end_time => { :hour => 24, :minute => 'ZERO' }},
      {:day_of_week => 'MONDAY', :start_time => { :hour => 0, :minute => 'ZERO' }, :end_time => { :hour => 24, :minute => 'ZERO' }},
      {:day_of_week => 'TUESDAY', :start_time => { :hour => 0, :minute => 'ZERO' }, :end_time => { :hour => 24, :minute => 'ZERO' }},
      {:day_of_week => 'WEDNESDAY', :start_time => { :hour => 0, :minute => 'ZERO' }, :end_time => { :hour => 24, :minute => 'ZERO' }},
      {:day_of_week => 'THURSDAY', :start_time => { :hour => 0, :minute => 'ZERO' }, :end_time => { :hour => 24, :minute => 'ZERO' }},
      {:day_of_week => 'FRIDAY', :start_time => { :hour => 0, :minute => 'ZERO' }, :end_time => { :hour => 24, :minute => 'ZERO' }},
      {:day_of_week => 'SATURDAY', :start_time => { :hour => 0, :minute => 'ZERO' }, :end_time => { :hour => 24, :minute => 'ZERO' }}
    ]
  },

  :custom_targeting => { :xsi_type => 'CustomCriteriaSet', :logical_operator => 'OR', :children => [
      { :xsi_type => 'CustomCriteriaSet', :logical_operator => 'OR', :children => build_custom_targeting_children(get_custom_targeting_values($options[:keywords]))},
    ] 
  },

#  :technology_targeting => {
#    :browser_targeting => {
#      :is_targeted => true,
#      #just chrome
#      :browsers => [{:id => 500072}]
#    }
#  }
}

line_items = line_item_service.create_line_items([{
  :name => 'API Create Line Item ' + DateTime.now.to_s,
  :order_id => orders[0][:id],
  :targeting => targeting,
  :line_item_type => 'STANDARD',
  :allow_overbook => true,
  :creative_rotation_type => 'EVEN',
  :creative_placeholders => [{ :size => {:width => 300, :height => 600, :is_aspect_ratio => false} }],
  :start_date_time_type => 'IMMEDIATELY',
  :end_date_time => Time.new + 60 * 60 * 24 * 7,
  :cost_type => 'CPM',
  :cost_per_unit => { :currency_code => 'USD', :micro_amount => 2000000 },
  :units_bought => 50000,
  :unit_type => 'IMPRESSIONS'
}])

if line_items
  line_items.each do |line_item|
    puts "Line item with ID: %d, belonging to order ID: %d, and named: %s was created." % [line_item[:id], line_item[:order_id], line_item[:name]]
  end
else
  raise 'No line items were created'
end


# Create the Creative...
puts 'Creating the Creative...'

creative_service = $dfp.service(:CreativeService, API_VERSION)
creatives = creative_service.create_creatives([{
  :xsi_type => 'CustomCreative',
  :name => 'Manta Ad',
  :advertiser_id => ADVERTISER_ID,
  :destination_url => 'http://local.manta.com:8000/cp/%s/%s/' % [$options[:emid], $options[:product]],
  :html_snippet => '<iframe src="http://local.manta.com:8000/cp/%s/%s/?view=micro"></iframe>' % [$options[:emid], $options[:product]],
  :size => {:width => 300, :height => 600, :is_aspect_ratio => false }
}])

if creatives
  creatives.each do |creative|
    puts "Custom creative with ID: %d, name: '%s'and type: '%s' was created." % [creative[:id], creative[:name], creative[:creative_type]]
  end
else
  raise 'Creative was not created.'
end

# create the assocation between the creative and the line item

lica_service = $dfp.service(:LineItemCreativeAssociationService, API_VERSION)
licas = lica_service.create_line_item_creative_associations([{
  :line_item_id => line_items[0][:id],
  :creative_id => creatives[0][:id]
}])

if licas
  licas.each do |lica|
    puts "LICA with line item ID: %d, creative ID: %d and status: %s was created" % [lica[:line_item_id], lica[:creative_id], lica[:status]]
  end
else
  raise "no LICA's were created"
end

# approve the order

statement = { :query => 'WHERE id = %d' % [orders[0][:id]] }
result = order_service.perform_order_action({:xsi_type => 'ApproveAndOverbookOrders'}, statement)

if results and result[:num_changes] > 0
  puts 'Order %d approved' % [orders[0][:id]] 
else
  raise 'The order was not approved!'
end

