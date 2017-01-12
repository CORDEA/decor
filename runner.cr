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

require "json"
require "option_parser"
require "./gmail"
require "./reader"
require "./twitter"
require "./selector"
require "./preference"
require "./expiration_manager"

GMAIL_KEY = "gmail"
TWITTER_KEY = "twitter"

class Runner

    getter readers : Array(Reader)

    getter config : Config

    def initialize(path : String)
        @readers = Array(Reader).new
        if File.exists?(path) && !File.directory?(path)
            @config = Config.from_json File.read(path)
            @config.order.each do |env|
                @readers << initialize_readers env
            end
        else
            raise "Config file not found."
        end
    end

    private def initialize_readers(env : Env)
        case env.service
        when GMAIL_KEY
            return Gmail::Reader.new env
        when TWITTER_KEY
            return Twitter::Reader.new env
        else
            return Reader.new env
        end
    end

    def get_immediately(with_auth : Bool)
        @readers.each do |reader|
            reader.get_immediately
            sleep 1.seconds
        end
    end

    def get(with_auth : Bool)
        @readers.each do |reader|
            reader.get
            sleep 1.seconds
        end
    end

    def out(prefix, suffix : String)
        @readers.each do |reader|
            reader.out prefix, suffix
        end
    end
end

STDOUT.blocking = true
STDERR.blocking = true

if ARGV.any?
    sub = ARGV.shift

    get_immediately = false
    with_auth = false
    config_path = ""
    prefix = ""
    suffix = ""

    OptionParser.parse ARGV do |parser|
        parser.on("--config=CONFIG", "") { |config| config_path = config }
        parser.on("--immediately", "") { get_immediately = true }
        parser.on("-a", "--with-auth", "") { with_auth = true }
        parser.on("-p PREF", "--prefix=PREF", "") { |pref| prefix = pref }
        parser.on("-s SUFF", "--suffix=SUFF", "") { |suff| suffix = suff }
    end

    runner = Runner.new config_path
    case sub
    when "get"
        runner.get with_auth
        if get_immediately
            runner.get_immediately with_auth
        end
    when "puts"
        runner.out prefix, suffix
    else
        raise "Please enter a valid subcommand."
    end
end
