## The iotspot Dashboard

#### Introduction

iotspot offers management information as part of its Smart Workspace Platform by means of dashboards. These dashboards are web-based, require user authorisation, and provide data selection capabilities. They run on the QuickSight platform in Amazon Web Services.

Authorised users are provided with information about the availability or occupancy rate of your workspaces, i.e. desks and/or rooms. In case you have activated monitoring services, the dashboards will also show you the actual utilisation of desks, rooms and/or the interior climate of designated areas.

The below sections of this page explain:
* [Authorising dashboard access](#authorising-dashboard-access)
* [Activating your user account](#activating-your-user-account)
* [Revisiting the iotspot dashboard](#revisiting-the-iotspot-dashboard)
* [Resetting your password](#resetting-your-password)


#### Authorising dashboard access

In order to access our dashboards, your organisation needs to specify the email addresses of the employees that are granted access. Optionally, to limit an employee's access to specific locations, you can also specify one or more office locations. If no office location is specified, the employee is granted access to data on all locations where the iotspot service is activated for your organisation.

To authorise users, or request access to the dashboards, please send an e-mail to <a href="mailto:dashboard@iotspot.co?subject=access%20request">support@iotspot.co</a> with the subject line: `access request` and include:
* a list of one or more authorised users, with for each user:
  * first and last name
  * email address, and
  * (optionally) the iotspot office locations for which the user is authorised to view the dashboards.

> NOTE  
> Email addresses containing a "+" character are not allowed in QuickSight.

Within 24 hours, each authorised user will be invited to activate his or her QuickSight user account.


#### Activating your user account

Each user will be invited with an email from **QuickSight team** (noreply@quicksight.aws.amazon.com) with subject **Invitation to Join QuickSight**:

![screenshot invitation email](images/QuickSight_invitation.png)

In the email, click the blue `Click to accept invitation` button. This opens a web page in your browser that starts with `signin.aws.amazon.com`.

> **IMPORTANT**  
> On this page, we recommend that you **do not change** the pre-filled Email address.  
> The pre-filled QuickSight account name (`iotspot`) and Username fields are read-only and cannot be altered.

![screenshot activation page](images/QuickSight_To_access.png)

Enter and confirm a password, then click `Create account and sign in`.

Finally, click `Continue` to access the iotspot dashboards.



#### Revisiting the iotspot dashboard

 To revisit the dashboards in QuickSight, go to: [quicksight.aws.amazon.com](https://quicksight.aws.amazon.com){:target="_blank"}.

If you are using the _same browser_ as before, it will remember your QuickSight account (`iotspot`). Enter you email address and password and click `Sign in`.

If you are signing in with a _different browser_, then enter QuickSight account: `iotspot` and click `Continue`. On the next page, enter you email address and password and click `Sign in`.

> IMPORTANT  
> The QuickSight **account name** is always `iotspot`; do not use your email address here.  
> In QuickSight, your email address is used as the **username**. 


#### Resetting your password

In case a user has access to the iotspot account in QuickSight and knows the designated email address but has forgotten the password, the user can click `Forgot Password?` at the bottom of the **Sign in to QuickSight** page.

This opens the **Password Assistance** page:

![screenshot of Password Assistance page](images/QuickSight_Password_Assistance.png)

On this page:  
* verify that the QuickSight account name is `iotspot`
* enter your email address
* enter the characters in the image
* click `Continue`.

You will then see this confirmation page:

![screenshot of confirmation page](images/QuickSight_We_emailed_you_instructions.png)

After you receive the email (check your spam folder if needed), click the reset link to open the **Reset password** page in your browser.

Enter and confirm the new password, then click `Continue`.

Now continue to sign in with the new password (see [Revisiting the iotspot dashboard](#revisiting-the-iotspot-dashboard) above for details).
