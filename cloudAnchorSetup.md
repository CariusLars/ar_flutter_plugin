# Getting Started with Cloud Anchors

The usual method of authentication is setting an API key. However, this authentication method only allows to host anchors with a maximum lifetime of 24 hours. OAuth 2.0 authentication allows saving uploaded anchors for up to 365 days and needs to be set up to use the plugin.
Follow the steps below to set up your application.

## Set up Google Cloud Anchor Service

The Google Cloud Anchor API is used by the plugin to upload, store and download AR anchors. If your app uses the plugin's shared AR experience features, the following setup steps are required:

1. Activate the [Cloud Anchor API](https://console.cloud.google.com/apis/api/arcorecloudanchor.googleapis.com) in your [Google Cloud Console](https://console.cloud.google.com) for the respective project
2. Register the Android part of your Flutter Application
   * Perform the following steps to create a OAuth2 project (based on the [Android Cloud Anchors Developer Guide](https://developers.google.com/ar/develop/java/cloud-anchors/developer-guide-android?hl=en) and the [Guide for setting up OAuth 2.0](https://support.google.com/cloud/answer/6158849#zippy=)):
     * Go to the [Google Cloud Platform Console](https://console.cloud.google.com).
     * If the APIs & services page isn't already open, open the console left side menu and select APIs & services.
     * On the left, click Credentials.
     * Click New Credentials, then select OAuth client ID.
     * Select "Android" as the Application type
     * Fill in an arbitrary name and make sure the field "Package name" matches the package name in the ```AndroidManifest.xml``` of the Android part of your Flutter application
     * Fill in the SHA-1 certificate fingerprint. If you're still in development, you can get the debug keystore key for the Android app by executing ```keytool -keystore ~/.android/debug.keystore -list -v``` in your terminal
     * Click Create client ID
     * If this is your first time creating a client ID, you have to configure your consent screen by clicking Consent Screen. The following procedure explains how to set up the Consent screen. You won't be prompted to configure the consent screen after you do it the first time.
       * Go to the Google API Console [OAuth consent screen](https://console.cloud.google.com/apis/credentials/consent) page.
       * Add required information like a product name and support email address.
       * Click Add Scope.
       * On the dialog that appears, select the ```ARCore Cloud Anchor API```scopes and any additional ones your project uses. Sensitive scopes display a lock icon next to the API name. (To select scopes for registration, you need to enable the API, like Drive or Gmail, from APIs & Services > API Library. You must select all scopes used by the project.)
       * Finish the remaining steps of the OAuth consent screen setup.
   * Enable keyless authentication in the Android part of your Flutter app (if you use the sample app of this plugin as a starting point, these steps are already done; the following steps are based on the [Android Cloud Anchors Developer Guide](https://developers.google.com/ar/develop/java/cloud-anchors/developer-guide-android?hl=en)):
     * Add the dependency ```implementation 'com.google.android.gms:play-services-auth:16+'``` to the ```build.gradle``` file
     * If you are using [ProGuard](https://www.guardsquare.com/en/products/proguard), add it to your app’s build.gradle file with
  
        ```java
        buildTypes {
          release {
            ...
              proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            }
          }
        ```
     * And add the following to your app’s proguard-rules.pro file:


        ```java
        -keep class com.google.android.gms.common.** { *; }
        -keep class com.google.android.gms.auth.** { *; }
        -keep class com.google.android.gms.tasks.** { *; }
        ```

3. Register the iOS part of your Flutter Application
   * Perform the following steps to create a Google Service account and signing key (based on the [iOS Cloud Anchor Developer Guide](https://developers.google.com/ar/develop/ios/cloud-anchors/developer-guide?hl=en)):
     * In the navigation menu of the Google Cloud Platform console, go to APIs & Services > Credentials.
     * Select the desired project, then click Create Credentials > Service account.
     * Under Service account details, type a name for the new account, then click Create.
     * On the Service account permissions page, go to the Select a role dropdown. Select Service Accounts > Service Account Token Creator, then click Continue.
     * On the Grant users access to this service account page, click Done. This takes you back to APIs & Services > Credentials.
     * On the Credentials page, scroll down to the Service Accounts section and click the name of the account you just created.
     * On the Service account details page, scroll down to the Keys section and select Add Key > Create new key.
     * Select JSON as the key type and click Create. This downloads a JSON file containing the private key to your machine.
   * Add the contents of the JSON file you just downloaded to the iOS part of your Flutter application:
     * Rename the file to ```cloudAnchorKey.json```
     * Move or copy ```cloudAnchorKey.json``` into the example/ios/Runner directory.
     * Open Xcode, then right-click on Runner directory and select Add Files to "Runner".
     * Select ```cloudAnchorKey.json```  from the file manager.
     * A dialog will show up and ask you to select the targets, select the Runner target.

## Set up Firebase

Google's Firebase cloud platform is used by the plugin's sample app to distribute and manage shared anchors and related content. If you want to use the included examples with shared AR experience features (e.g. the ```Cloud Anchors```example), the following setup steps are required (in your own apps, you can implement any method you like to distribute and manage the cloud anchor IDs that the plugin returns after uploading an anchor):

1. Create a new project in the [Firebase console](https://console.firebase.google.com/project/_/overview)
2. Register the Android part of your Flutter Application (based on the [FlutterFire Android Installation Guide](https://firebase.flutter.dev/docs/installation/android/)):
   * Add a new Android app to your project and make sure the ```Android package name``` matches your local project's package name which can be found within the ```AndroidManifest.xml```
   * Fill in the debug signing certificate SHA-1 field. If you're still in development, you can get the debug keystore key for the Android app by executing ```keytool -keystore ~/.android/debug.keystore -list -v``` in your terminal
   * Once your Android app has been registered, download the configuration file from the Firebase Console (the file is called ```google-services.json```). Add this file into the ```android/app``` directory within your Flutter project
   * Add the dependency ```classpath 'com.google.gms:google-services:4.3.3'``` to the top-level ```build.gradle```file of the Android part of your Flutter application
   * Add ```apply plugin: 'com.google.gms.google-services'``` to the app-level ```build.gradle```file of the Android part of your Flutter application
3. Register the iOS part of your Flutter Application (based on the [FlutterFire iOS Installation Guide](https://firebase.flutter.dev/docs/installation/ios/)):
   * Add a new iOS app to your project and make sure the ```iOS bundle ID``` matches your local project bundle ID which can be found within the "General" tab when opening ```ios/Runner.xcworkspace``` with Xcode.
   * Download the file ```GoogleService-Info.plist``` 
   * Move or copy ``` GoogleService-Info.plist``` into the example/ios/Runner directory.
   * Open Xcode, then right-click on Runner directory and select Add Files to "Runner".
   * Select ``` GoogleService-Info.plist```  from the file manager.
   * A dialog will show up and ask you to select the targets, select the Runner target.
4. Enable Cloud Firestore for the project you created in step 1 (head to https://console.firebase.google.com/project/INSERT_YOUR_FIREBASE_PROJECT_NAME_HERE/firestore)

## Set up Location Services

* On the iOS part of your app, add the following to your Info.plist file (located under ios/Runner) in order to access the device's location:
  ```
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>This app needs access to location when open.</string>
  <key>NSLocationAlwaysUsageDescription</key>
  <string>This app needs access to location when in the background.</string>
  ```
   
