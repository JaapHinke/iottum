## The iotspot Dashboard

#### Introduction

iotspot offers management information as part of its Smart Workspace Platform by means of dashboards. These dashboards are web-based, require user authorisation, and provide data selection capabilities. They run on the QuickSight platform in Amazon Web Services.

Authorised users are provided with information about the availability or occupancy rate of your workspaces, i.e. desks and/or rooms. In case you have activated monitoring services, the dashboards will also show you the actual utilisation of desks, rooms and/or the interior climate of designated areas.

This dashboard manual provides you with information and guidelines for your use of the iotspot dashboard services.

#### User authorisation

In order to access our dashboards, your organisation needs to specify the email addresses of the employees that are granted access. Optionally, to limit an employee's access to specific locations, you can also specify one or more office locations. If no office location is specified, the employee is granted access to data on all locations where the iotspot service is activated for your organisation.

To authorise users, or request access to the dashboards, please send an e-mail to <html><a href="mailto:support@iotspot.co?subject=dashbaord">support@iotspot.co</a></html> with the subject line: `iotspot dashboard access` and include:
* a list of one or more authorised users, with for each user:
  * first and last name
  * email address, and
  * (optionally) the iotspot office locations for which the user is authorised to view the dashboards.


#### User activation

Each user will receive an email from **QuickSight Team** (noreply@quicksight.aws.amazon.com) with subject **Invitation to Join QuickSight**:

![screenshot email](QuickSight_invitation.png | width=500)

In the email, click the blue `Click to accept invitation` button. This opens a web page in your browser that starts with `signin.aws.amazon.com`.

![screenshot sign-up page](QuickSight_signup.png){:height="50%" width="50%"}

> **IMPORTANT**  
> On this page, do **not** alter the prefilled QuickSight account name (`iotspot`), Email address, or Username fields.

Enter a password, then click `Create account and sign in`.

Finally, click `Continue` to access the iotspot dashboards.
