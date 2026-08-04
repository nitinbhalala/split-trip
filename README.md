# split_trip

A new Flutter project.

## Getting Started

## 1.debug sha key 
wiondws 
keytool -list -v -alias androiddebugkey -keystore "%USERPROFILE%\.android\debug.keystore" -storepass android -keypass android
mac
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android

## 2. Release (Live) SHA-1 / SHA-256
If your keystore is named upload-keystore.jks:
keytool -list -v -keystore "D:\FlutterProjects\SplitTrip\upload-keystore.jks" -alias splittrip
 
 ## Flutter version : 3.44.6
## dart version : 3.12.2 
