# Authentitate script (not tested well) for zoltyj
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

require 'mastodon'
require 'uri'
require 'net/http'
require 'yaml'
require 'gpgme'
require 'fileutils'

configfile = "config.yml"
hiddenfile = "pk.txt"
config = YAML.load_file(configfile)

base_url = URI(config["baseurl"])
client = Mastodon::REST::Client.new(base_url: base_url)
redirect_uri = "urn:ietf:wg:oauth:2.0:oob"
scopes = "read:statuses read:notifications write:statuses"
new_app_token = client.create_app('zoltyj', redirect_uri, scopes, "https://github.com/hiromi-mi/zoltyj")
       
encoded_uri = URI.encode_www_form([["client_id", new_app_token.client_id],
                                   ["redirect_uri", redirect_uri],
                                   ["response_type", "code"],
                                   ["scope", scopes]])
printf("In this script, get access token from %s ,and save into %s\n", base_url, configfile)
printf("To Authentitate, visit this website:\n%s/oauth/authorize?%s\n", base_url, encoded_uri)
printf("Input the code shown on that website: ")
authcode = gets().delete_suffix("\n")
posturi = URI(sprintf("%s/oauth/token", base_url))
postres = Net::HTTP.post_form(posturi, [["client_id", new_app_token.client_id], ["client_secret", new_app_token.client_secret], ["grant_type", "authorization_code"], ["code", authcode],["redirect_uri", "urn:ietf:wg:oauth:2.0:oob"]])
accesstoken = JSON.parse(postres.body)["access_token"]
# File.write(configfile, config.to_yaml)
crypto = GPGME::Crypto.new
file = File.open(hiddenfile, "w+")
FileUtils.chmod 0700 hiddenfile # keep it 700
crypto.encrypt accesstoken, :output => file
file.close
print "Saved.\n"
