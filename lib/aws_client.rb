#!/usr/bin/ruby
require 'mechanize'

class AWSClient
  AWS_USAGE_REPORTS_URL = 'https://aws-portal.amazon.com/gp/aws/developer/account/index.html?action=usage-report'

  def initialize(username, password)
    @username = username
    @password = password
    @agent = Mechanize.new { |agent|
      agent.user_agent = Mechanize::AGENT_ALIASES['Mac Safari']# + ' (awspend.com robot; anelson@nullpointer.net)'
      agent.follow_meta_refresh = true
      agent.log = Rails.logger
    }
    @authenticated = false
  end

  def authenticate
    @agent.log.debug "Requesting usage reports URL for the first time; will authenticate"
    @agent.get(AWS_USAGE_REPORTS_URL) do |page|
      #If this is the first connection, will redirect to the auth page
      @agent.log.debug "Sign-in page title is #{page.title}"

      page.form_with(:name => 'signIn') do |form|
        form.fields.each { |f| Rails.logger.debug "Sign in form contains field #{f.name}" }
        form.email = @username
        form.password = @password
      end.submit()
    end

    if @agent.page.form_with(:name => 'usageReportForm') == nil then
      @agent.log.error "Sign-in failed for #{@username}: \n#{@agent.page.body}"
      raise "Sign-in failed for user #{@username}"
    else
      @agent.log.debug "Sign-in succeeded"
    end

    @authenticated = true
  end

  def get_usage_report(type, start_date, end_date, granularity)
    authenticate unless @authenticated

    @agent.get(AWS_USAGE_REPORTS_URL) do |page|
      @agent.log.debug "Usage reports page title is #{page.title}"

      @agent.log.debug "Selecting product code"
      page.form_with(:name => 'usageReportForm') do |form|
        form.productCode = case type
        when :ec2 then 'AmazonEC2'
        when :sns then 'AmazonSNS'
        when :s3 then 'AmazonS3'
        when :vpc then 'AmazonVPC'
        else raise ArgumentError "Invalid service type"
        end

        page = form.submit
      end

      page.form_with(:name => 'usageReportForm') do |form|
        form.fields.each { |f| Rails.logger.debug "Second usage reports form contains field #{f.name}" }
        form.usageType = 'ALL'
        form.operation = 'ALL'
        form.timePeriod = 'aws-portal-custom-date-range'
        form.startMonth = start_date.month
        form.startDay = start_date.day
        form.startYear = start_date.year
        form.endMonth = end_date.month
        form.endDay = end_date.day
        form.endMonth = end_date.month
        form.periodType = 'hours'

        image_button = form.button_with(:name => 'download-usage-report-csv')
        image_button.x = 1
        image_button.y = 1
        report = form.click_button(image_button)

        puts report.body
      end
    end
  end
end
