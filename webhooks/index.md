# Data Events Webhook

(formerly: push-api)


## Release status

The iotspot webhook for data events is currently available to select customers on a Proof of Concept basis.

To start using this webhook, contact iotspot and provide one or more endpoints that fulfil the requirements below.

iotspot reserves the right to make changes to the data events webhook, but will take care to limit the impact on existing subscribers.


## Introduction

The data events webhook enables customers to _subscribe_ to a stream of iotspot _data events_.

Data events are incoming sensor messages or user-driven events (specifically, the start or end of a booking). The following _categories_ of data events are available:
* occupancies (originating from occupancy sensors or from booking start/end events)
* climate
* headcount

iotspot uses SNS to push these data events to subscribing _endpoints_, typically an HTTPS REST API.

The SNS notification message contains the following data and meta data:
* an array with one or more data events
* ids describing the _organization_ and _location_
* the _category_ of the data events


## Customer endpoint for a subscription

An endpoint subscribing to a iotspot data events stream is typically an HTTPS REST API.  Authentication can be done with Basic or Digest Authentication. There is no option to include an Authorization header, eg, with an API key,

The requirements for such an endpoint are described in:
[Using Amazon SNS for System-to-System Messaging with an HTTP/S Endpoint as a Subscriber](https://docs.aws.amazon.com/sns/latest/dg/sns-http-https-endpoint-as-subscriber.html).

As described in that document, an endpoint always needs to _confirm_ a subscription for messages to start flowing.


## Payload structure and example

The SNS notification's payload contains (among others):
* a `Message` field that contains a JSON representation of the data events
* a `MessageAttributes` field that contains a structure with key data about the data events
  * `organization_id`  
    a _string_ identifying the organization
  * `location_id`  
    a _string_ containing an array of strings identifying the locations (ie, office buildings)
  * `category`  
    a _string_ identifying the type of data (`climate` | `occupancies` | `headcount`)

* an `UnsubscribeURL` to unsubscribe from the stream
* a `Signature` and `SigningCertURL` for message verification (see **Message verification** section below)

A message always contains only a single category of data events.

An example of an SNS notification message, containing a single climate data event:
```
{
    "Type" : "Notification",
    "MessageId" : "920b758a-165f-5905-9bdd-232addf57ae7",
    "TopicArn" : "arn:aws:sns:eu-central-1:951137801000:iotspot-webhooks-data-events-v1",
    "Subject" : "iotspot data events",
    "Message" : "[{\"timestamp_utc\":\"2020-01-21T09:46:50.000Z\",\"device_id\":\"8931088217011846857\",\"sensor_id\":\"4191\",\"source\":\"climate sensor\",\"temperature\":20.04,\"pressure\":1042.91,\"humidity\":38.675,\"gas_voc\":15441,\"iaq\":\"159\",\"iaq_accuracy\":3,\"voc\":\"2.437\",\"co2\":\"1297.760\",\"workplace_id\":4738,\"location_id\":13,\"organization_id\":3,\"time_zone\":\"Europe/Amsterdam\"}]",
    "Timestamp" : "2020-01-21T09:50:34.828Z",
    "SignatureVersion" : "1",
    "Signature" : "EbwwdypRVQYZMRfqCnZnx081aSBb6qY7qTjfu7rgh4LThT+YSMKvb9EnLfJ+V+kWIDviHhtHAzd76QNYiF5OgwgZu6A0qH8MJytDnLlYjie4w4Jw7DqGxPzEP2LjUMVjP0Ya4nliPW/bkbOrWZNURuPMf5myfhboUxDeCgNQEr+10LV6bUbzbt00Y9A12Sga+88j336fyJwJf7aQ1hdreTAi4NBKymaokVUXt+1cBZYPJG1c6UmOo4XnewPGG1ZbxlaXIos8qLWe2r2/0Ct7CWlKBhLyOI6CdKjrjND0hmMszOsAwvCo7RhNnRIbL/zGsCorFNxdpDDTE6KjZcuH6Q==",
    "SigningCertURL" : "https://sns.eu-central-1.amazonaws.com/SimpleNotificationService-a86cb10b4e1f29c941702d737128f7b6.pem",
    "UnsubscribeURL" : "https://sns.eu-central-1.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:eu-central-1:951137801000:push-api-data-events-test:e21fe936-6da4-4169-bf12-4252f1478980",
    "MessageAttributes" : {
        "organization_id" : {"Type":"String","Value":"3"},
        "location_id" : {"Type":"String","Value":"[\"47\"]"},
        "category" : {"Type":"String","Value":"climate"}
    }
}
```


## Message structure and example

The `Message` field in the SNS notifcation payload contains a JSON string with the actual data events (as an array).

### generic fields

Data events for all categories contain these generic fields:
* `timestamp_utc`  
   an _ISO 8601 string_ with the timestamp of the original event (sensor message or booking event)
* `source`  
   a _string_ describing the source of the event, typically a type of sensor or a reservation (booking)
* `workplace_id`  
   an _integer_ identifying the workplace (ie, desk or room)
* `location_id`  
   an _integer_ identifying the location (ie, office building)
* `organization_id`  
   an _integer_ identifying the organization
* `time_zone`  
   a _tz database string_ describing the time zone that the workplace/location is in

Data events *that originate from a sensor* furthermore contain these generic fields:
* `device_id`  
   a _string_ identifying the iotspot device that the sensor is connected to
* `sensor_id`  
   a _string_ identifying the sensor

### climate fields 

Data events *that originate from a climate sensor* contain these specific fields:
* `temperature`  
   a _decimal (with 2 decimal places)_ representing the temperature (in Celsius)
* `humidity`  
   a _decimal (with 2 decimal places)_ representing the relative humidity (in percent)
* `pressure`  
   a _decimal (with 2 decimal places)_ representing the barometric pressure (in hPa, or mbar)
* `iaq`  
   an _integer (on a scale from 1-500)_ representing estimated Interior Air Quality
* `iaq_accuracy`  
   an _integer (0 | 1 | 2 | 3)_ representing accuracy of the IAQ, CO<sub>2</sub>, and VOC estimates, see note below  
* `voc`  
   a _decimal (with 3 decimal places)_ representing estimated breath volatile organic compounds (in ppm)
* `co2`  
   a _decimal (with 3 decimal places)_ representing estimated carbon dioxide (in ppm)

These events occur at regular intervals, typically every 5 minutes.

##### values for `iaq_accuracy` field

{:start="0"}
0. Stabilization / run-in ongoing  
1. Low accuracy  
to accelarate auto-trimming you can expose a sensor once to good air (eg, outdoor air) and bad air (eg, box with exhaled breath)
2. Medium accuracy: auto-trimming ongoing
3. High accuracy

##### example

An example of the data as found in the `Message` attribute of the notification payload:
```
[
    {    
        "timestamp_utc": "2020-01-16T13:42:42.000Z???,
        "device_id": "8931088417068457075",
        "sensor_id": "1000005",
        "source": "climate sensor",
        "workplace_id": 5174,
        "location_id": 61,
        "organization_id": 31,
        "time_zone": "Europe/Amsterdam",
        "temperature": 20.12,
        "humidity": 43.21,
        "pressure": 1014.78,
        "iaq": 124,
        "iaq_accuracy": 3,
        "voc": 23.225,
        "co2": 655.322
    }
]
```

### occupancies fields 

Data events *that originate from an occupancy sensor* contain these specific fields:
* `occupied`  
   a _boolean_ representing whether the workplace is occupied 
* `reserved`  
   a _boolean_ representing whether the workplace is reserved (booked) _at this moment_ by an end user

These events occur whenever an occupancy sensor detects a change from not occupied to occupied, or vice versa.

Data events *that originate from a booking* contain this specific field:
* `reserved`  
   a _boolean_ representing whether the workplace is reserved (booked)_at this moment_ by an end user

These events occur whenever a booking starts or ends.


##### example

An example of the data (for an event *originating from an occupancy sensor*) as found in the `Message` attribute of the notification payload:
```
[
    {    
        "timestamp_utc": "2020-01-16T13:42:42.000Z???,
        "device_id": "8931088417068457075",
        "sensor_id": "1000005",
        "source": "occupancy sensor",
        "workplace_id": 5174,
        "location_id": 61,
        "organization_id": 31,
        "time_zone": "Europe/Amsterdam",
        "occupied": true,
        "reserved": true
    }
]
```


### headcount fields 

Data events *that originate from a headcount sensor* contain these specific fields:
* `peak`  
   an _integer_ representing the highest headcount in the period capped by the timestamp 
* `average`  
   a _decimal (with 1 decimal places)_ representing the average headcount in the period capped by the timestamp

These events occur at regular intervals, typically every 10 minutes.

##### example

An example of the data as found in the `Message` attribute of the notification payload:
```
[
    {    
        "timestamp_utc": "2020-01-16T13:42:42.000Z???,
        "device_id": "8931088417068457075",
        "sensor_id": "1000005",
        "source": headcount sensor",
        "workplace_id": 5174,
        "location_id": 61,
        "organization_id": 31,
        "time_zone": "Europe/Amsterdam",
        "peak": 3,
        "average": 2.3
    }
]
```


## Timeliness of data

### Semi-realtime data

For data that does not have to be realtime, data events are buffered inside iotspot until a certain data size or time period limit is reached.

The buffer time limit is set as follows:
* occupancies: 1 minute
* climate: 5 minutes
* headcount: 5 minutes

In practice this means that the age of a data event in the occupancies category is _on average_ ~30 seconds. For a climate or headcount data event, the age is _on average_ ~ 2.5 minutes.

From this logic it follows that, for this type of data, the SNS notification payload typically contains an array of data events.

### Realtime data

For _occupancies_ data events that originate from a reservation (booking) that starts or ends, data events are sent in realtime.

From this logic it follows that, for this type of data, the SNS notification payload normally contains an array with just a single data event.


## Message verification

Subscribing customers are encouraged to verify the signature of notification messages.

The steps to verify the signature are described in: [Verifying the Signatures of Amazon SNS Messages](https://docs.aws.amazon.com/sns/latest/dg/sns-verify-signature-of-message.html).


#### Copyright &copy; 2020 iotspot BV. All rights reserved. 
