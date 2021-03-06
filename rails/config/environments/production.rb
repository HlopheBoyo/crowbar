# Copyright 2013, Dell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
Crowbar::Application.configure do
  config.cache_classes = true
  # Full error reports are disabled and caching is turned on
  #config.action_controller.consider_all_requests_local = false
  config.action_controller.perform_caching             = true
  config.action_view.cache_template_loading            = true
  config.active_support.deprecation = :notify

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = true
  config.eager_load = true

  # See everything in the log (default is :info)
  config.log_level = :debug
  config.paths['log'] = "/var/log/crowbar/#{Rails.env}.log"

  # Use a different logger for distributed setups

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false
  config.crowbar.version = '2.3'
  config.crowbar.docs = "https://github.com/opencrowbar/core/tree/master/doc"
end
