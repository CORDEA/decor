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

class Gmail::Reader < Reader

    def get(with_auth : Bool)
        expires_in = @env.expires_in
        manager = ExpirationManager.new @env.key, @env.path, expires_in
        if manager.is_expire
            get_immediately with_auth
            manager.refresh Time.now
        end
    end

    def get_immediately(with_auth : Bool)
        creds = Client.read_client_secret_json File.join(@env.path, CLIENT_SECRET)
        oauth_params = OAuth2Params.new(
            creds.installed.client_id,
            creds.installed.client_secret,
            creds.installed.redirect_uris[0]
        )
        gmail = Client.new @env.path, oauth_params
        begin
            if gmail.is_need_access_authorize_url
                if with_auth
                    mails = authorize gmail
                else
                    raise "Authentication is required."
                end
            else
                mails = gmail.get
            end
        rescue ex
            File.write filepath, ex.message
        else
            contents = Array(String).new
            mails.each do |mail|
                payload = mail.payload
                if mail.nil? || payload.nil?
                    return
                end
                headers = payload.headers
                if headers.nil?
                    return
                end
                title = ""
                from = ""
                headers.each do |header|
                    title = header.value if header.name == "Subject"
                    from = header.value if header.name == "From"
                end
                if !title.blank? && !from.blank?
                    contents << "%s - %s" % [title, from]
                end
            end
            File.write filepath, contents.join('\n')
        end
    end

    private def authorize(gmail) : Array(Message)
        puts gmail.get_authorize_url
        if STDIN.tty?
            code = STDIN.gets || ""
            gmail.get_access_token_by_code code
            return gmail.get
        end
        raise "Must run from the stdin device."
    end

    def out(prefix, suffix : String)
        selector = Selector.new filepath
        puts "%s%s%s" % [prefix, selector.select, suffix]
    end
end
