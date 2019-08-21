# [api](../..)/[admin](..)/user/* actions with _Nexudus_


## Assumptions

The integration is based on the assumption that access to iotspot is available with one or more specific plans. See [plans](https://platform.nexudus.com/billing/tariffs?Tariff_Archived=false){:target="_blank"} in the Nexudus dashboard. 

Once a user (_coworker_ in Nexudus terminology) adds such a plan and it is activated, the corresponding iotspot account will be _activated_ giving access within iotspot to the relevant iotspot locations and workspaces. If there is no corresponding iotspot account yet, it will be created. Note that the activation may happen immediately or be scheduled for a specific date. If the latter, the iotspot account will be activated at that date.

If the user cancels the plan/contract, the iotspot account will be _deactivated_ on the scheduled cancellation date (or immediately, if canceled immediately). When deactivated, the iotspot account can still be used but access to the relevant locations and workspaces will be removed, and only access to a set of demo offices is available.

#### Important

A Nexudus user should, at any given time, at most have one plan that allows iotspot access.

If a user can have more than one plan, the most recent action determines iotspot access, which will give results that will be unexpected for the user. For example, if a user has two plans and then deletes one, the iotspot account will be deactivated, even though the user still has another plan with iotspot access.

If a user is deleted, the assumption is that active plans will be canceled prior to deleting the user. If not, iotspot access will not be deactivated.


## Mapping _Nexudus_ locations and plans to _iotspot_ organizations and locations

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
navigate to [Settings → General](https://platform.nexudus.com/settings/general){:target="_blank"} in the Nexudus dashboard, see **Location #**
* the _plan id_ of each plan that allows iotspot:<br/>
navigate to [Inventory → Plans](https://platform.nexudus.com/billing/tariffs?Tariff_Archived=false){:target="_blank"}, then click the relevant plan and find the plan id at the end of the URL; eg, `https://platform.nexudus.com/billing/tariffs/1082164083`, the plan id is `1082164083`.

## Setting up Nexudus integration with iotspot

The integration with iotspot for a Nexudus location is done via _webhooks_. Navigate to [Settings → Integrations → Webhooks](https://platform.nexudus.com/settings/integrations/options/webhooks){:target="_blank"} in the Nexudus dashboard.

Enter the **Shared secret** for the iotspot API integration (obtained in a secure manner from iotspot) and click **Manage webhooks**, then click **Add webhook**.

Then add webhooks for the following events:
* **Action**: Activate coworker contract
  * **Name** (suggested): `Activate/update iotspot for coworker`
  * **URL**:
    * for testing: `https://api.iotspot.co/test/admin/user/activate`
    * for production: `https://api.iotspot.co/v1/admin/user/activate`
  * **Description** (suggested): `Allows the iotspot account for this coworker access to this Lendlease location, according to the activated contract. A new iotspot account will be created if this coworker does not have one.`
  * **Active**: set to enabled
* **Action**: Cancel coworker contract
  * **Name** (suggested): `Deactivate iotspot for coworker`
  * **URL**: 
    * for testing: `https://api.iotspot.co/test/admin/user/deactivate`
    * for production: `https://api.iotspot.co/v1/admin/user/deactivate`
  * **Description** (suggested): `Removes access to this Lendlease location for this iotspot account, according to the cancelled contract. (The iotspot account will remain active but only have access to a demo set of offices.)`
  * **Active**: set to enabled


## Supported Nexudus actions

The following actions are supported for any location that allows iotspot access.

The corresponding Nexudus webhook event will fire within about 1 minute from an action's completion if the action is set to take place immediately. If the action has a scheduled contract date, the event will fire when the action is completed on that date.

Actions triggering a Nexudus `Activate coworker contract` webhook event:
* a new user is created with a plan that allows iotspot access  
* an existing user purchases a plan that allows iotspot access
* an existing user changes to a plan that allows iotspot access

Actions triggering a Nexudus `Cancel coworker contract` webhook event:
* an existing user cancels a plan that allows iotspot access
* an existing user changes to a plan that does not allow iotspot access

**Important**: If an existing user is deleted while still having an active plan that allows iotspot access, then this will not **not** trigger a Nexudus `Cancel coworker contract` webhook event, and iotspot access will not be deactivated. The assumption is that active plans will be canceled prior to deleting the user.

Also note that deleting an entire location in Nexudus will not deactivate iotspot users. If an entire location is deleted, the corresponding location(s) in iotspot should be removed as well by iotspot.


#### Corresponding iotspot app behavior

If a user is newly activated and has not used the iotspot app before, the user can start the app and sign in with same email address as used in Nexedus. The app will show appropriate location(s)/workspaces immediately.

For existing users that have already used the iotspot app before, any changes in accessible locations will be reflected when the app is opened (brought to the foreground). If the user happens to be using the app while the change takes place, then the app will not reflect this immediately. Once the user switches to another app (or the homescreen) and then back to the iotspot app, the location changes will be reflected.

If a user was activated or deactivated, and the app is reopened, it will also show a dialog box saying `Company not allowed` and the user can tap `OK`. The app will then show the appropriate locations (if an account was deactivated, these locations will be demo locations).


#### Identifying users in iotspot with existing accounts prior to Nexudus activation

Users that already have a iotspot account before their Nexudus account is activated for iotspot will be identified based on their email address. If the email address matches an account in iotspot, that iotspot account will be used for this Nexudus account. From this point on, the Nexudus user id (`CoworkerId` in the webhook request) will be used to match the Nexudus account to the iotspot account, so even if the user changes email address in either Nexudus or iotspot, the accounts remain linked.


## Background: How the iotspot API processes Nexudus webhook requests

#### Nexudus `Activate coworker contract` webhook

A iotspot activation (new user or contract change) request from the Nexudus `Activate coworker contract` webhook is processed as follows:
* the user is identified by Nexudus user id (`CoworkerId` in the webhook request), with email (`CoworkerEmail`) as fallback if the user id is not found
* the organization and locations are indirectly identified by the combination of the Nexudus _location id_  (`IssuedById`) and _plan id_  (`TariffId`) 

If the user account did not yet exist, the `CoworkerFullName` in the webhook request will be used as the name in iotspot.


#### Nexudus `Cancel coworker contract` webhook

A iotspot deactivation (contract change) request from the Nexudus `Cancel coworker contract` webhook is processed as follows:
* the user is identified by Nexudus user id (`CoworkerId` in the webhook request), with email (`CoworkerEmail`) as fallback if the user id is not found
* the organization is indirectly identified by the Nexudus _location id_  (`IssuedById`)
