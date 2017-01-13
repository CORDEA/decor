require "json"

class Gmail::Response
    JSON.mapping(
        messages: Array(Message),
    )
end

class Gmail::Message
    JSON.mapping(
        id: String,
        threadId: String,
        payload: { type: Payload, nilable: true }
    )
end

class Gmail::Payload
    JSON.mapping(
        headers: Array(Header)
    )
end

class Gmail::Header
    JSON.mapping(
        name: String,
        value: String
    )
end
