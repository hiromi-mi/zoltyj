# zoltyj compose
# License: Apache-2.0 (See LICENSE)
#
#   Copyright hiromi-mi 2019
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# https://nokogiri.org/tutorials/parsing_an_html_xml_document.html
# https://www.rubydoc.info/gems/mastodon-api/Mastodon/Status
# https://www.rubydoc.info/gems/mastodon-api/Mastodon/REST/Timelines#home_timeline-instance_method
# https://docs.joinmastodon.org/api/entities/#status
# https://docs.joinmastodon.org/api/rest/timelines/

require 'rubygems'
require 'mastodon'
require 'uri'
require 'nokogiri'
require 'yaml'
require 'optparse'
require 'readline'

configfile = "config.yml"
config = YAML.load_file(configfile)
base_url = URI(config["baseurl"])
client = Mastodon::REST::Client.new(base_url: base_url, bearer_token: config["accesstoken"])
toot = Readline.readline("Toot: ", false)
id = Readline.readline("Reply to: ", false)
client.create_status(toot, {visibility: "private",in_reply_to_id: id} )
