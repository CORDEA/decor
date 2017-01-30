# Copyright 2017 Yoshihiro Tanaka
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

  # http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Author: Yoshihiro Tanaka <contact@cordea.jp>
# date  :2017-01-12

class Twitter::Params

    getter secret_path : String

    def initialize(@secret_path) end
end

class Twitter::ClientSecret
    JSON.mapping(
        token: String,
        token_secret: String,
        consumer_key: String,
        consumer_secret: String
    )
end

class Twitter::Tweet
    JSON.mapping(
        text: String,
        user: User
    )
end

class Twitter::User
    JSON.mapping(
        name: String
    )
end

class Twitter::Search
    JSON.mapping(
        statuses: Array(Tweet)
    )
end

class Twitter::Client

    API_HOST = "api.twitter.com"
    USER_TIMELINE_API_PATH = "/1.1/statuses/user_timeline.json?screen_name=%s"
    HOME_TIMELINE_API_PATH = "/1.1/statuses/home_timeline.json"

    SEARCH_API_PATH = "/1.1/search/tweets.json?q=%s&locale=%s&lang=%s&count=%d"
    SEARCH_LOCALE = "ja"
    SEARCH_LANG = "ja"
    SEARCH_COUNT = 10

    ACCESS_TOKEN_KEY = "twitter/access_token"

    getter client : HTTP::Client
    getter path : String
    getter query : String

    def initialize(@path, @query)
        @client = HTTP::Client.new(API_HOST, tls: true)
    end

    def read_client_secret_json : ClientSecret
        if File.exists?(@path) && !File.directory?(@path)
            return ClientSecret.from_json File.read(@path)
        end
        raise "Secret file not found. path: %s" % [@path]
    end

    def get : Array(Tweet)
        params = read_client_secret_json
        OAuth.authenticate(@client,
                           params.token,
                           params.token_secret,
                           params.consumer_key,
                           params.consumer_secret)
        is_search = false
        query = @query
        if query.blank?
            response = @client.get HOME_TIMELINE_API_PATH
        else
            qs = query.split ':'
            case qs[0]
            when "u"
                response = @client.get USER_TIMELINE_API_PATH % [qs[1]]
            when "s"
                is_search = true
                response = @client.get SEARCH_API_PATH % [qs[1], SEARCH_LOCALE, SEARCH_LANG, SEARCH_COUNT]
            else
                raise "Unsupported request type: %s" % [qs[0]]
            end
        end
        if response.success? && response.body?
            if is_search
                result = Search.from_json response.body
                resp = result.statuses
            else
                resp = Array(Tweet).from_json response.body
            end
            @client.close
            return resp
        end
        raise "Request failed. [%d] %s" % [response.status_code, response.body]
    end
end
