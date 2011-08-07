require 'date'
require 'aws_client'

namespace :aws_client do
  task :test => :environment do
    client = AWSClient.new("nhusain@appassure.com", "exchange2003")

    puts "Authenticating to AWS"
    client.authenticate

    puts "Getting usage report"
    client.get_usage_report :ec2, Date.civil(2011, 8, 1), Date.civil(2011, 8, 2), :hour
  end
end
