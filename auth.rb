# Authentitate script (not tested well) for zoltyj
# License: Apache-2.0 (See LICENSE)

require 'rubygems'
require 'mastodon'
require 'uri'
require 'net/http'
require 'yaml'

configfile = "config.yml"
config = YAML.load_file(configfile)

base_url = URI(config["baseurl"])
client = Mastodon::REST::Client.new(base_url: base_url)
new_app_token = client.create_app('zoltyj', "urn:ietf:wg:oauth:2.0:oob")
       
encoded_uri = URI.encode_www_form([["scope", "read"], ["response_type", "code"], ["client_id", new_app_token.client_id],["redirect_uri", "urn:ietf:wg:oauth:2.0:oob"], ["client_secret", new_app_token.client_secret]])
printf("In this script, get access token from %s ,and save into %s", base_url, configfile)
printf("To Authentitate, visit this website:\n%s/oauth/authorize?%s\n", base_url, encoded_uri)
printf("Input the code shown on that website: ")
authcode = gets().delete_suffix("\n")
posturi = URI(sprintf("%s/oauth/token", base_url))
postres = Net::HTTP.post_form(posturi, [["client_id", new_app_token.client_id], ["client_secret", new_app_token.client_secret], ["grant_type", "authorization_code"], ["code", authcode],["redirect_uri", "urn:ietf:wg:oauth:2.0:oob"]])
config["access_token"] = JSON.parse(postres.body)["access_token"]
File.write(configfile, config.to_yaml)
