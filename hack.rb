#! /usr/bin/env ruby

require 'dfp_api'

API_VERSION = :v201403
PAGE_SIZE = 500

dfp = DfpApi::Api.new()

# authorization

ask_to_update = false

token = dfp.authorize() do |auth_url|
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
    dfp.save_oauth2_token(token)
    puts 'OAuth2 token is now saved to ~/dfp_api.yml and will be ' +
        'automatically used by the library.'
  end
end

# get the company

puts 'Getting the Companies...'
company_service = dfp.service(:CompanyService, API_VERSION)
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

# get the users

puts 'Getting the Users...'
user_service = dfp.service(:UserService, API_VERSION)
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

# Nathan Romano : 113047698

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
placement_service = dfp.service(:PlacementService, API_VERSION)
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

# Create an Order
puts 'Creating an Order...'

order_service = dfp.service(:OrderService, API_VERSION)
orders = order_service.create_orders([{
  :name => 'API Created Order ' + DateTime.now.to_s,
  :advertiser_id => 15781698,
  :salesperson_id => 113047698,
  :trafficker_id => 113047698,
  :status => 'DRAFT'
}])

if orders
  orders.each do |order|
    puts "Order with ID: %d and name \"%s\" was created." % [order[:id], order[:name]]
  end
end

# Create a Line Item

puts 'Creating the Line Item...'
line_item_service = dfp.service(:LineItemService, API_VERSION)

targeting = {

  :inventory_targeting => {
    :targeted_placement_ids => [
      3548418, # automotive
      3549618 # manufacturing
     ]
  },

  :geo_targeting => {
    :targeted_locations => [
      {:id => 2840},
    ]
  },

  :user_domain_targeting => {
    :domains => ['manta.com'],
    :targeted => true
  },

  :day_part_targeting => {
    :time_zone => 'BROWSER',
    :day_parts => [
      {:day_of_week => 'MONDAY', :start_time => { :hour => 0, :minute => 'ZERO' }, :end_time => { :hour => 24, :minute => 'ZERO' }},
      {:day_of_week => 'TUESDAY', :start_time => { :hour => 0, :minute => 'ZERO' }, :end_time => { :hour => 24, :minute => 'ZERO' }},
      {:day_of_week => 'WEDNESDAY', :start_time => { :hour => 0, :minute => 'ZERO' }, :end_time => { :hour => 24, :minute => 'ZERO' }},
      {:day_of_week => 'THURSDAY', :start_time => { :hour => 0, :minute => 'ZERO' }, :end_time => { :hour => 24, :minute => 'ZERO' }},
      {:day_of_week => 'FRIDAY', :start_time => { :hour => 0, :minute => 'ZERO' }, :end_time => { :hour => 24, :minute => 'ZERO' }}
    ]
  },

  :technology_targeting => {
    :browser_targeting => {
      :is_targeted => true,
      #just chrome
      :browsers => [{:id => 500072}]
    }
  }
}

line_items = line_item_service.create_line_items([{
  :name => 'API Create Line Item ' + DateTime.now.to_s,
  :order_id => orders[0][:id],
  :targeting => targeting,
  :line_item_type => 'STANDARD',
  :allow_overbook => true,
  :creative_rotation_type => 'EVEN',
  :creative_placeholders => [{ :size => {:width => 300, :height => 250, :is_aspect_ratio => false} }],
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
# Create a Creative
