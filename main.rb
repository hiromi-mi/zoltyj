# zoltyj
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

require 'mastodon'
require 'uri'
require 'nokogiri'
require 'io/console'
require 'sqlite3'
require 'yaml'
require 'optparse'
require 'gpgme'

opt = OptionParser.new
params = {}
params["saved"] = false

opt.on("-r", "--resume", "Use resumed data") {|v| params["saved"] = true}

opt.parse!(ARGV, into: params)
configfile = "config.yml"
latestfile = "latest.yml"
hiddenfile = "pk.txt"
config = YAML.load_file(configfile)
if FileTest.exist?(latestfile) && params["saved"]
  latest = YAML.load_file(latestfile, fallback: {})
else
  # couldn't load, then create
  latest = {}
  latest["first_id"] = ""
  latest["notifications_first_id"] = ""
end

base_url = URI(config["baseurl"])
crypto = GPGME::Crypto.new
file = File.open(hiddenfile, "r")
accesstoken_data = crypto.decrypt(file)
accesstoken = accesstoken_data.read(100) # at most 100 bytes
file.close
client = Mastodon::REST::Client.new(base_url: base_url, bearer_token: accesstoken)

# Capture CTRL+C
Signal.trap("EXIT", proc { File.write(latestfile, latest.to_yaml) })

loop do
  home = client.home_timeline(since_id: latest["first_id"].to_i)
  notifications = client.notifications(since_id: latest["notifications_first_id"].to_i, limit: 5)
  if notifications.size > 0 then
    latest["notifications_first_id"] = notifications.entries[0].id
    for i in notifications.entries.reverse do
      if i.status? then
        notifications_doc = Nokogiri::HTML(i.status.content)
        notifications_doc.xpath("//br").each { |x| x.content="; " }
        printf("[%s] @%s %s\n", i.type, i.account.acct, notifications_doc.text)
      else
        printf("[%s] @%s\n", i.type, i.account.acct)
      end
    end
  end
  if home.size > 0 then
    latest["first_id"] = home.entries[0].id
    for i in home.entries.reverse do
      home_doc = Nokogiri::HTML(i.content)
      # https://nokogiri.org/tutorials/searching_a_xml_html_document.html
      # make multiple line into one code
      home_doc.xpath("//br").each { |x| x.content="; " }
      printf("%s %s @%s\n", i.id, home_doc.text, i.account.acct)
    end
  end
  sleep(30)
end
