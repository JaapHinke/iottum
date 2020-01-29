# push-api


## Release status

The iotspot Push API is currently available to select customers on a Proof of Concept basis.

To start using the Push API, contact iotspot and provide one or more endpoints that fulfil the requirements below.

iotspot reserves the right to make changes to the Push API, but will take care to limit the impact on existing Push API subscribers.


## Introduction

The iotspot Push API enables customers to _subscribe_ to a iotspot stream of _data events_.

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
* a `MessageAttributes` field that describes the _organization\_id_, _location\_id_ and _category_ of the message's data events
* an `UnsubscribeURL` to unsubscribe from the stream
* a `Signature` and `SigningCertURL` for message verification (see **Message verification** section below)

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
        "location_id" : {"Type":"String","Value":"83"},
        "category" : {"Type":"String","Value":"climate"}
    }
}
```


## Message structure and example

The `Message` field in the SNS notifcation payload contains a JSON string with the actual data events (as an array).

### Fields included in all events

Data events for all categories contain:
* `timestamp_utc`  
   an _ISO 8601 string_ with the timestamp of the original event (sensor message or booking event)
* `source`  
   a _string_ describing the source of the event, typically a type of sensor or a reservation (booking)
* `workplace_id`  
   an _integer_ identifying the workplace (ie, desk or room)
* `location_id`  
   an _integer_ identifying the location (ie, office building)
* `time_zone`  
   a _tz database string_ describing the time zone that the workplace/location is in

### Fields included in all sensor data events 

Data events originating from a sensor furthermore contain:
* `device_id`  
   a _string_ identifying the iotspot device that the sensor is connected to
* `sensor_id`  
   a _string_ identifying the sensor

#### _climate_ sensor data events 

Data events originating from a climate sensor specifically contain:
* `temperature`  
   a _decimal (with 2 decimal places)_ representing the temperature (in Celsius)
* `humidity`  
   a _decimal (with 2 decimal places)_ representing the relative humidity (in percent)
* `pressure`  
   a _decimal (with 2 decimal places)_ representing the barometric pressure (in hPa, or mbar)
* `iaq`  
   an _integer (on a scale from 1-500)_ representing Interior Air Quality
* `voc`  
   a _decimal (with 3 decimal places)_ representing estimated breath volatile organic compounds (in ppm)
* `co2`  
   a _decimal (with 3 decimal places)_ representing estimated carbon dioxide (in ppm)

These events occur at regular intervals, typically every 10 minutes.

#### _occupancies_ sensor data events 

Data events originating from an occupancy sensor specifically contain:
* `occupied`  
   a _boolean_ representing whether the workplace is occupied 
* `reserved`  
   a _boolean_ representing whether the workplace is reserved by an end user

These events occur whenever an occupancy sensor detects a change from not occupied to occupied, or vice versa.


#### _headcount_ sensor data events 

Data events originating from a headcount sensor specifically contain:
* `peak`  
   an _integer_ representing the highest headcount in the period capped by the timestamp 
* `average`  
   a _decimal (with 1 decimal places)_ representing the average headcount in the period capped by the timestamp

These events occur at regular intervals, typically every 10 minutes.

### Fields included in _occupancies_ booking-originated data events

Data events originating from bookings specifically contain:
* `reserved`  
   a _boolean_ representing whether the workplace is reserved (booked) by an end user

These events occur whenever a booking starts or ends.

### Example

An example of an _occupancies_ booking-originated data event as found in the `Message` attribute of the notification payload ("unpacked" from the JSON encapsulation):
```
[
    {    
        "timestamp_utc": "2020-01-16T13:42:42.000Z”,
        "device_id": "8931088417068457075",
        "sensor_id": "1000005",
        "source": “reservation",
        "workplace_id": 5174,
        "location_id": 61,
        "time_zone": "Europe/Amsterdam",
        "reserved": false
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

For _reservations_ data events that originate from a reservation (booking) that starts or ends, data events are sent in realtime.

From this logic it follows that, for this type of data, the SNS notification payload normally contains an array with just a single data event.


## Message verification

Subscribing customers are encouraged to verify the signature of notification messages.

The steps to verify the signature are described in: [Verifying the Signatures of Amazon SNS Messages](https://docs.aws.amazon.com/sns/latest/dg/sns-verify-signature-of-message.html).


##### Copyright &copy; 2020 iotspot BV. All rights reserved. 
