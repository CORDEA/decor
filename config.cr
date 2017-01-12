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

module Int::SpanConverter
    def self.from_json(value : JSON::PullParser) : Time::Span
        Time::Span.new 0, 0, value.read_int
    end
end

class Config
    JSON.mapping(
        order: Array(Env)
    )
end

class Env
    JSON.mapping(
        service: String,
        key: String,
        arg: {type: JSON::Any, nilable: true},
        path: String,
        expires_in: {type: Time::Span, converter: Int::SpanConverter}
    )
end
