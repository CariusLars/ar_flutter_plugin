# Getting Started with Cloud Anchors

The usual method of authentication is setting an API key. However, this authentication method only allows to host anchors with a maximum lifetime of 24 hours, so OAUTH2 authentication needs to be set up.
* Note: Read https://cocoapods.org/pods/ARCore/changelog

## Set up Google Cloud Service
* Follow this: https://support.google.com/cloud/answer/6158849#zippy= and set up 2 applications: One of type Android and a separate of type iOS.
  * To get the debug keystore key for the Android app, use: ```keytool -keystore ~/.android/debug.keystore -list -v```
* Activate the [Cloud Anchor API](https://console.cloud.google.com/apis/api/arcorecloudanchor.googleapis.com)
* Note your client IDs for the Android and iOS apps

## Set up Firebase
* Create a new project in the Firebase console
* Register 2 apps in this project: One for [Android](https://developers.google.com/mobile/add?platform=android) and [iOS](https://developers.google.com/mobile/add?platform=ios)
  * In the iOS registration process, proceed as follows:
    * Download the file ```GoogleService-Info.plist``` 
    * Move or copy ``` GoogleService-Info.plist``` into the example/ios/Runner directory.
    * Open Xcode, then right-click on Runner directory and select Add Files to "Runner".
    * Select ``` GoogleService-Info.plist```  from the file manager.
    * A dialog will show up and ask you to select the targets, select the Runner target.
    * Go to ```example/iOS/Runner/Info.plist```and exchange the value for ```CFBundleURLSchemes```with your own Google Cloud OAUTH2 iOS client ID in reverse notation
  * In the Android registration process, proceed as follows:
    * TODO: Add explanations here

## Registering Google Cloud Anchor Authentication with the iOS part of the plugin:
Follow these steps to create a Google Service account and signing key:

* In the navigation menu of the Google Cloud Platform console, go to APIs & Services > Credentials.
* Select the desired project, then click Create Credentials > Service account.
* Under Service account details, type a name for the new account, then click Create.
* On the Service account permissions page, go to the Select a role dropdown. Select Service Accounts > Service Account Token Creator, then click Continue.
* On the Grant users access to this service account page, click Done. This takes you back to APIs & Services > Credentials.
* On the Credentials page, scroll down to the Service Accounts section and click the name of the account you just created.
* On the Service account details page, scroll down to the Keys section and select Add Key > Create new key.
* Select JSON as the key type and click Create. This downloads a JSON file containing the private key to your machine. Store the downloaded JSON key file in a secure location.

## Set up your app

## Initialize the plugin
* The cloudanchorexample in the example app loads to the client ID from a json file which is ignored by git. To use the sample, create a JSON file named ```cloudanchorcredentials.json```in the folder ```./example/Credentials```and add ```{"clientID_Android" : "<YOUR GOOGLE CLOUD OAUTH2 Android APPLICATION CLIENT ID>, "clientID_iOS" : "<YOUR GOOGLE CLOUD OAUTH2 iOS APPLICATION CLIENT ID>}"```as a top-level entry. In your own app, you can also add the credentials in a different way.

## Minimal Example