# main.rb
# https://nokogiri.org/tutorials/parsing_an_html_xml_document.html
# https://www.rubydoc.info/gems/mastodon-api/Mastodon/Status
# https://www.rubydoc.info/gems/mastodon-api/Mastodon/REST/Timelines#home_timeline-instance_method
# https://docs.joinmastodon.org/api/entities/#status
# https://docs.joinmastodon.org/api/rest/timelines/

require 'rubygems'
require 'mastodon'
require 'uri'
require 'nokogiri'
require 'io/console'
require 'sqlite3'
require 'yaml'

configfile = "config.yml"
config = YAML.load_file(configfile)

base_url = URI(config["baseurl"])
accesstoken = config["accesstoken"]
client = Mastodon::REST::Client.new(base_url: base_url, bearer_token: accesstoken)
home = client.home_timeline()
notifications = client.notifications(limit: 5)

first_id = ""
notifications_first_id = ""
loop do
  if notifications.size > 0 then
    notifications_first_id = notifications.entries[0].id
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
    first_id = home.entries[0].id
    for i in home.entries.reverse do
      home_doc = Nokogiri::HTML(i.content)
      # https://nokogiri.org/tutorials/searching_a_xml_html_document.html
      # make multiple line into one code
      home_doc.xpath("//br").each { |x| x.content="; " }
      printf("%s @%s\n", home_doc.text, i.account.acct)
    end
    # TODO
    home_doc = Nokogiri::HTML(home.entries[0].content)
  end
  sleep(30)
  home = client.home_timeline(since_id: first_id.to_i)
  notifications = client.notifications(since_id: notifications_first_id.to_i, limit: 5)
end
