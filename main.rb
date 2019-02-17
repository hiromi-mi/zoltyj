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
# require 'websocket-client-simple'
#print("Insert Domain: ")
#base_url = URI(gets().delete_suffix("\n"))
#print("Insert Access Token: ")
# token = STDIN.noecho(&:gets)
accesstoken = config["accesstoken"]
client = Mastodon::REST::Client.new(base_url: base_url, bearer_token: accesstoken)
home = client.home_timeline()

first_id = ""
loop do
  if home.size > 0 then
    first_id = home.entries[0].id
    for i in home.entries.reverse do
      home_doc = Nokogiri::HTML(i.content)
      printf("%s @%s\n", home_doc.text, i.account.acct)
    end
    home_doc = Nokogiri::HTML(home.entries[0].content)
  end
  sleep(30)
  home = client.home_timeline(since_id: first_id.to_i)
end
