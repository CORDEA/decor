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

class Twitter::Reader < Reader

    private def screen_name : String
        if arg = @env.arg
            return arg.as_s
        end
        return ""
    end

    def get
        expires_in = @env.expires_in
        manager = ExpirationManager.new @env.key, @env.path, expires_in
        if manager.is_expire
            get_immediately
            manager.refresh Time.now
        end
    end

    def get_immediately
        client = Client.new File.join(@env.path, CLIENT_SECRET), screen_name
        begin
            resp = client.get
        rescue ex
            File.write filepath, ex.message
        else
            contents = Array(String).new
            resp.each do |tweet|
                contents << "%s - %s" % [tweet.text, tweet.user.name]
            end
            File.write filepath, contents.join('\n')
        end
    end

    def out(prefix, suffix : String)
        selector = Selector.new filepath
        puts "%s%s%s" % [prefix, selector.select, suffix]
    end
end
