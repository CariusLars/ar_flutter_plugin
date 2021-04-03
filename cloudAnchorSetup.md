# Getting Started with Cloud Anchors

The usual method of authentication is setting an API key. However, this authentication method only allows to host anchors with a maximum lifetime of 24 hours.
* Note: Read https://cocoapods.org/pods/ARCore/changelog

## Set up Google Cloud Service
* Follow this: https://support.google.com/cloud/answer/6158849#zippy=
* "A client ID is used to identify a single app to Google's OAuth servers. If your app runs on multiple platforms, each will need its own client ID."
* To get the debug keystore key, use: ```keytool -keystore ~/.android/debug.keystore -list -v```
* Activate Cloud anchors api: https://console.cloud.google.com/apis/api/arcorecloudanchor.googleapis.com
## Set up your app

## Initialize the plugin

## Minimal Example