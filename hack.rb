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

# Create an Order

order_service = dfp.service(:OrderService, API_VERSION)
orders = order_service.create_orders([{
  :name => 'API Created ' + DateTime.now.to_s,
  :advertiser_id => 15781698,
  :salesperson_id => 113047698,
  :trafficker_id => 113047698
}])

if orders
  orders.each do |order|
    puts "Order with ID: %d and name \"%s\" was created." % [order[:id], order[:name]]
  end
end

# Create a Line Item

# Create a Creative
