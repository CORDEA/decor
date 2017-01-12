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

class Preference

    private FILENAME = "pref.txt"

    private getter path : String

    def initialize(dirpath : String)
        @path = File.join(dirpath, FILENAME)
        @hash = {} of String => String
        read
    end

    def put(key, value)
        if !value.nil?
            @hash[key] = value
        end
    end

    def get(key)
        if @hash.has_key?(key)
            return @hash[key]
        end
    end

    def remove(key)
        @hash.delete key
    end

    def commit
        write
    end

    private def read
        if File.exists?(@path) && !File.directory?(@path)
            File.each_line(@path) do |line|
                unless line.blank?
                    l = line.split(',')
                    unless l.nil?
                        @hash[l[0]] = l[1]
                    end
                end
            end
        end
    end

    private def write
        if File.exists?(@path) && !File.directory?(@path)
            File.delete(@path)
        end
        lines = ""
        @hash.each do |k,v|
            unless v.blank?
                lines += "%s,%s\n" % [k, v]
            end
        end
        File.write @path, lines
    end

end
