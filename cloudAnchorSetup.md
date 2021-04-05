# Getting Started with Cloud Anchors

The usual method of authentication is setting an API key. However, this authentication method only allows to host anchors with a maximum lifetime of 24 hours, so OAUTH2 authentication needs to be set up.
* Note: Read https://cocoapods.org/pods/ARCore/changelog

## Set up Google Cloud Service
* Follow this: https://support.google.com/cloud/answer/6158849#zippy= and set up an application of type WEB
* (In case you need to get the debug keystore key, use: ```keytool -keystore ~/.android/debug.keystore -list -v```=
* Activate Cloud anchors api: https://console.cloud.google.com/apis/api/arcorecloudanchor.googleapis.com
## Set up your app

## Initialize the plugin
* The cloudanchorexample in the example app loads to the client ID from a json file which is ignored by git. To use the sample, create a JSON file named ```cloudanchorcredentials.json```in the folder ```./example/Credentials```and add ```{"clientID" : "<YOUR GOOGLE CLOUD OAUTH2 WEB APPLICATION CLIENT ID>}"```as a top-level entry. In your own app, you can also add the credentials in a different way.

## Minimal Example