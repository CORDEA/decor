# decor

Command for displaying various information on terminal.

## Usage

```sh
% crystal build runner.cr
% ./runner get --immediately --config ./config.json
% ./runner puts
```

Gmail requires authentication by code.
To do the authentication, execute with the ```with-auth``` option.

```sh
% ./runner get --immediately --with-auth --config ./config.json
```

### Config.json

- service
  - Service name. "gmail" or "twitter".
- key
  - Unique key.
- expires_in
  - The expiration date of the data. Not used when ```immediately``` option is specified.
- path
  - Absolute path of the directory containing client_secret file.

#### Example

```json
{
    "order": [
        {
            "service": "gmail",
            "key": "gmail",
            "expires_in": 600,
            "path": "/your/env/dir/gmail/"
        },
        {
            "service": "twitter",
            "key": "twitter",
            "expires_in": 600,
            "path": "/your/env/dir/twitter/"
        },
        {
            "service": "twitter",
            "key": "<unique key>",
            "arg": "<Twitter screen name>",
            "expires_in": 600,
            "path": "/your/env/dir/twitter/"
        }
    ]
}
```

### client secret

The ```client_secret``` file is required for operation.

#### Gmail

Please download the client_secret file from the authentication information of Google Cloud Platform console.

#### Twitter

```json
{
    "consumer_key": "your consumer key",
    "consumer_secret": "your consumer secret",
    "token": "your token",
    "token_secret": "your token secret"
}
```
