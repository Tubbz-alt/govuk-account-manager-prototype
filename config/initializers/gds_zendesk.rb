require "yaml"
require "gds_zendesk/client"
require "gds_zendesk/dummy_client"

GDS_ZENDESK_CLIENT = if Rails.env.development?
                       GDSZendesk::DummyClient.new(logger: Rails.logger)
                     else
                       GDSZendesk::Client.new(
                         username: ENV["ZENDESK_CLIENT_USERNAME"] || "abc",
                         token: ENV["ZENDESK_CLIENT_TOKEN"] || "def",
                         logger: Rails.logger,
                       )
                     end
