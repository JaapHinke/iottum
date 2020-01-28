# push-api

## Introduction

The iotspot Push API enables customers to _subscribe_ to a iotspot stream of _data events_.

Data events are incoming sensor messages or user-driven events (specifically, the start or end of a booking). The following _categories_ of data events are available:
* occupancies (originating from sensors or from booking start/end events)
* climate
* headcount

iotspot uses SNS to push these data events to subscribing _endpoints_, typically an HTTPS REST API.

The SNS notification message contains the following data and meta data:
* an array with one or more data events
* ids describing the _organization_ and _location_ (to be done)
* the _category_ of the data events


## Customer endpoint for a subscription

An endpoint subscribing to a iotspot data events stream is typically an HTTPS REST API.  Authentication can be done with Basic or Digest Authentication. There is no option to include an Authorization header, eg, with an API key,

The requirements for such an endpoint are described in:
https://docs.aws.amazon.com/sns/latest/dg/sns-http-https-endpoint-as-subscriber.html.

As described in that document, an endpoint always needs to _confirm_ a subscription for messages to start flowing.


## Payload structure and example

The SNS notification's payload contains (among others):
* a `Message` field that contains a JSON representation of the data events
* a `MessageAttributes` field that describes the _organization\_id_, _location\_id_ (to be done) and _category_ of the message's data events
* URLs to subscribe or unsubscribe from the stream
* a `Signature` for message verification (see **Message verification** section below)

A message always contains only a single category of data events.

An example of an SNS notification message, containing a single climate data event:
```
{
    "Type" : "Notification",
    "MessageId" : "920b758a-165f-5905-9bdd-232addf57ae7",
    "TopicArn" : "arn:aws:sns:eu-central-1:951137801000:push-api-data-events-test",
    "Subject" : "iotspot data events",
    "Message" : "[{\"timestamp_utc\":\"2020-01-21T09:46:50.000Z\",\"device_id\":\"8931088217011846857\",\"sensor_id\":\"4191\",\"source\":\"climate sensor\",\"temperature\":20.04,\"pressure\":1042.91,\"humidity\":38.675,\"gas_voc\":15441,\"iaq\":\"159\",\"iaq_accuracy\":3,\"voc\":\"2.437\",\"co2\":\"1297.760\",\"workplace_id\":4738,\"location_id\":3,\"time_zone\":\"Europe/Amsterdam\"}]",
    "Timestamp" : "2020-01-21T09:50:34.828Z",
    "SignatureVersion" : "1",
    "Signature" : "EbwwdypRVQYZMRfqCnZnx081aSBb6qY7qTjfu7rgh4LThT+YSMKvb9EnLfJ+V+kWIDviHhtHAzd76QNYiF5OgwgZu6A0qH8MJytDnLlYjie4w4Jw7DqGxPzEP2LjUMVjP0Ya4nliPW/bkbOrWZNURuPMf5myfhboUxDeCgNQEr+10LV6bUbzbt00Y9A12Sga+88j336fyJwJf7aQ1hdreTAi4NBKymaokVUXt+1cBZYPJG1c6UmOo4XnewPGG1ZbxlaXIos8qLWe2r2/0Ct7CWlKBhLyOI6CdKjrjND0hmMszOsAwvCo7RhNnRIbL/zGsCorFNxdpDDTE6KjZcuH6Q==",
    "SigningCertURL" : "https://sns.eu-central-1.amazonaws.com/SimpleNotificationService-a86cb10b4e1f29c941702d737128f7b6.pem",
    "UnsubscribeURL" : "https://sns.eu-central-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:eu-central-1:951137801000:push-api-data-events-test:e21fe936-6da4-4169-bf12-4252f1478980",
    "MessageAttributes" : {
        "organization_id" : {"Type":"String","Value":"3"},
        "category" : {"Type":"String","Value":"climate"}
    }
}
```


## Message structure and example

The `Message` field in the SNS notifcation contains a JSON string with the actual data events (as an array).

#### Fields always included

A data event contain the following fields for all categories:
* `timestamp_utc`  
   an _ISO 8601 string_ with the timestamp of original event (sensor message or booking event)
* `source`  
   a _string_ describing the source of the event, typically a type of sensor or a reservation (booking)
* `workplace_id`  
   an _integer_ identifying the workspace (ie, desk or room)
* `location_id`  
   an _integer_ identitying the location (ie, office building)
* `time_zone`  
   a _tz database string_ describing the time zone that the workspace/location is in

#### Fields included in sensor data events 

For data events originating from a sensor, it also contains:
* `device_id`\
a _string_ identifying the iotspot device that the sensor is connected to
* `sensor_id`\
a _string_ identitying the sensor

#### Fields included in _climate_ sensor data events 

For data events originating from a climate sensor, it also contains:
* `temperature`\
a _float_ representing the temperature (in Celsius)
* `humidity`\
a _float_ representing the relative humidity (in percent)
* `pressure`\
a _float_ representing the barometric pressure (in hPa, or mbar)
* `iaq`\
an _integer_ (on a scake from 1-500) representing Interior Air Quality
* `voc`\
a _float_ representing estimated breath volatile organic compounds (in ppm)
* `co2`\
a _float_ representing estimated carbon dioxide (in ppm)

An example of an "unpacked" occupancies data event:
```
[
    {    
        "timestamp_utc": "2020-01-16T13:42:42.000Z”,
        "device_id": "8931088417068457075",
        "sensor_id": "1000005",
        "source": “reservation",
        "occupied": false,
        "workplace_id": 5174,
        "location_id": 61,
        "time_zone": "Europe/Amsterdam",
        "reserved": false
    }
]
```

In this event, the `occupied` field reflects the status as measured by an occupancy sensor (if any). The `reserved` field describes the bookings made by end users.


## Message verification

Subscribing customers are encouraged to verify the signature of notification messages.

The steps to verify the signature are described in: https://docs.aws.amazon.com/sns/latest/dg/sns-verify-signature-of-message.html.
