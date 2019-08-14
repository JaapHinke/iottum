# [api](../..)/[admin](..)/user/* actions with _Nexudus_

### Mapping _Nexudus_ locations and plans to _iotspot_ organizations and locations

#### Mapping to iotspot organization

Typically, all _locations_ and _plans_ for a single Nexudus integration are associated with single iotspot _organization_. If this is not the case, then the _location_ (possibly combined with a _plan_) needs to be mapped to the desired iotspot _organization_.

#### Mapping to iotspot location(s)

Nexudus locations and iotspot locations are slightly different:
* a Nexudus location is typically a single physical location or office building
* a iotspot location is a collection of workspaces associated with a single physical location or office building.

Therefore, depending on the set-up of both, they may or may not map directly.

A iotspot location can contain _all_ of the workspaces for a physical location or office building, in which case a typical Nexudus _location_ maps directly to a iotspot _location_. But a iotspot location can also contain only _a subset_ of the workspaces, in which case the Nexudus plan is used to help determine the associated iotspot location(s).

Also, because not all plans may include iotspot access, the mapping to iotspot locations always require a Nexudus location and a Nexudus plan.

Finally, because a single plan may provide access to multiple iotspot locations (for example, both standard and premium workspaces in a single location), the combination of Nexudus location and plan may map to either one or multiple iotspot locations.

#### Sample mapping file

The mapping between Nexudus location ids and plan ids on the one hand, and iotspot organization id and location ids on the other hand, is maintained by iotspot. It can currently not be edited in real-time through the iotspot API.

The `description` fields are optional.

A basic example of the mapping: 
```
{
  "9082452071": {                           // Nexudus location id
    "description": "ACME London Office",
    "organization_id": "534342",                // iotspot organization id
    "locations_by_plan": {
      "7083029964": {                           // Nexudus plan id
        "description": "Standard Plan",
        "location_ids": "37536233"                // iotspot location id
      },
      "7114954842": {                           // Nexudus plan id
        "description": "Premium Plan",
        "location_ids": "37536233, 37536234"     // iotspot location ids
      }
    }
  },
  [...]
}
```

#### Determining the Nexudus ids required for mapping

The Nexudus ids used in the above mapping can be determined as follows:
* the _location id_ of each location that allows iotspot access:<br/>
navigate to [Settings → General](https://platform.nexudus.com/settings/general) in the Nexudus dashboard, see **Location #**
* the _plan id_ of each plan that allows iotspot:<br/>
navigate to [Inventory → Plans](https://platform.nexudus.com/billing/tariffs?Tariff_Archived=false), then click the relevant plan and find the plan id at the end of the URL; eg, `https://platform.nexudus.com/billing/tariffs/1082164083`, the plan id is `1082164083`.

### Setting up the integration with iotspot for a given location

The integration with iotspot is done via _webhooks_. Navigate to [Settings → Integrations → Webhooks](https://platform.nexudus.com/settings/integrations/options/webhooks) in the Nexudus dashboard.

Enter the **Shared secret** for the iotspot API integration (obtained in a secure manner from iotspot) and click **Manage webhooks**, then click **Add webhook**.

Then add webhooks for the following events:
* **Action**: Activate coworker contract
  * **Name** (suggested): `Activate iotspot for coworker`
  * **URL**:
    * for testing: `https://yydsgrv0s6.execute-api.eu-central-1.amazonaws.com/test/admin/user/activate`
    * for production: `https://api.iotspot.co/admin/user/activate`
  * **Description** (suggested): `Allows the iotspot account for this coworker access to this Lendlease location, according to the activated contract. A new iotspot account will be created if this coworker does not have one.`
  * **Active**: set to enabled
* **Action**: Cancel coworker contract
  * **Name** (suggested): `Deactivate iotspot for coworker`
  * **URL**: 
    * for testing: `https://yydsgrv0s6.execute-api.eu-central-1.amazonaws.com/test/admin/user/deactivate`
    * for production: `https://api.iotspot.co/admin/user/deactivate`
  * **Description** (suggested): `Removes access to this Lendlease location for this iotspot account, according to the cancelled contract. (The iotspot account will remain active but only have access to a demo set of offices.)`
  * **Active**: set to enabled



### Handling Nexudus webhook requests

#### Nexudus `Activate coworker contract` webhook

A user activation request from the Nexudus `Activate coworker contract` webhook is processed as follows:
* the user is identified by email (`CoworkerEmail` in the webhook request)
* the organization and locations are indirectly identified by the combination of the Nexudus _location id_  (`IssuedById`) and _plan id_  (`TariffId`) 

If the user account did not yet exist, the `CoworkerFullName` in the webhook request will be used as the name in iotspot.


#### Nexudus `Cancel coworker contract` webhook

A user activation request from the Nexudus `Cancel coworker contract` webhook is processed as follows:
* the user is identified by email (`CoworkerEmail` in the webhook request)
* the organization is indirectly identified by the Nexudus _location id_  (`IssuedById`)
