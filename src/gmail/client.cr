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

class Gmail::OAuth2Params
    getter client_id : String
    getter client_secret : String
    getter redirect_uri : String
    getter auth_url : String
    getter token_url : String

    def initialize(@client_id, @client_secret, @redirect_uri,
                   @auth_url = "https://accounts.google.com/o/oauth2/v2/auth",
                   @token_url = "https://www.googleapis.com/oauth2/v4/token")
    end
end

class Gmail::ClientSecret
    JSON.mapping(
        installed: Installed
    )
end

class Gmail::Installed
    JSON.mapping(
        client_id: String,
        auth_uri: String,
        token_uri: String,
        client_secret: String,
        redirect_uris: Array(String)
    )
end

class Gmail::Client

    API_HOST = "www.googleapis.com"
    LIST_API_PATH = "/gmail/v1/users/me/messages"
    DETAIL_API_PATH = "/gmail/v1/users/me/messages/%s"

    ACCESS_TOKEN_KEY = "access_token"
    CLIENT_SECRET_KEY = "client_secret"
    SCOPE = "https://www.googleapis.com/auth/gmail.readonly"

    getter client : HTTP::Client
    getter dirpath : String

    private def manager(token)
        if expires_in = token.expires_in
            return ExpirationManager.new ACCESS_TOKEN_KEY, @dirpath,Time::Span.new(0, 0, expires_in)
        end
        raise "Expires_in is nil."
    end

    def initialize(@dirpath, oauth2_params : OAuth2Params)
        @oauth2_client = OAuth2::Client.new(
            "",
            oauth2_params.client_id,
            oauth2_params.client_secret,
            authorize_uri: oauth2_params.auth_url,
            token_uri: oauth2_params.token_url,
            redirect_uri: oauth2_params.redirect_uri
        )
        @client = HTTP::Client.new(API_HOST, tls: true)
        @state = State(OAuth2::AccessToken).new(@dirpath, ACCESS_TOKEN_KEY)
    end

    def self.read_client_secret_json(path : String) : ClientSecret
        if File.exists?(path) && !File.directory?(path)
            return ClientSecret.from_json File.read(path)
        end
        raise "Secret file not found. path: %s" % [path]
    end

    def is_need_access_authorize_url
        @state.restore().nil?
    end

    def get_authorize_url
        @oauth2_client.get_authorize_uri(SCOPE)
    end

    def get_access_token_by_code(code : String)
        token = @oauth2_client.get_access_token_using_authorization_code code
        @state.save token
        manager(token).refresh Time.now
    end

    private def refresh_access_token_if_need(token : OAuth2::AccessToken)
        manager= manager token
        if manager.is_expire
            refresh_token = @oauth2_client.get_access_token_using_refresh_token token.refresh_token
            token.access_token = refresh_token.access_token
            token.expires_in = refresh_token.expires_in
            @state.save token
            manager.refresh Time.now
        end
        token
    end

    def get : Array(Message)
        token = @state.restore
        if token.nil?
            raise "Access token is required."
        end
        token = refresh_access_token_if_need token

        access_token = OAuth2::AccessToken::Bearer.new token.access_token, 172_800
        access_token.authenticate(@client)

        path = URI.new(path: LIST_API_PATH, query: "maxResults=10")
        response = @client.get path.to_s
        if response.success? && response.body?
            resp = Response.from_json response.body
            @client.close
            mails = Array(Message).new
            resp.messages.each do |message|
                detail = get_detail message.id
                unless detail.nil?
                    mails << detail
                end
            end
            return mails
        end
        @client.close
        raise "Request failed. [%d] %s" % [response.status_code, response.body]
    end

    private def get_detail(id)
        sleep 1.seconds
        path = URI.new(path: DETAIL_API_PATH % [id], query: "maxResults=10")
        response = @client.get path.to_s
        if response.success? && response.body?
            resp = Message.from_json response.body
            @client.close
            return resp
        end
        @client.close
        raise "Request failed. [%d] %s" % [response.status_code, response.body]
    end
end
