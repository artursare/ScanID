# ScanID
Homework iOS project to scan IDs MRZ code

## Requirements for mobile application


1. Create app for ID document photo capturing, just the side with MRZ (https://en.wikipedia.org/wiki/Machine-readable_passport)
2. Pass photo to API, You can use your own document or take pictures from the internet. Use "data" information from api call response.
3. Present received information in a tidy manner.
4. Briefly describe your process and how the app works.

Special focus should be on solving one of these problematic areas:

 - quality of photo (detect blur, glare, darkness, ...)
 - not readable information (try to read some data from document)
 - document not in frame

Optional, but it would be good to address these requirements:
  Use one of MVVM/MVP design patterns.
  Write some unit tests.


Main purpose of this task is to check your logical thinking and code writing, not on completely solving these problems, so do not take too much time if it doesn't work 100%.


## Brief description on my process

The project consists of main app target ScanID and inner module DocummentScanner, supports iOS 14.1+ and uses SPM as dependency manager.
ScanID app was developed as an experimental SwiftUI-MVVM project while learning basics and features of Swift Combine framework.

I started with the special focus section which was creating basic MRZ reader by using 3rd party framework MRZSccanner and reusing UIKit ViewController from provided sample app by adjusting few parts with 'quick and dirty' a.k.a prototype approach, then I wrapped it into a SwiftUI view (here I lost a day or so, thats why mentioned ViewController is a singleton now) and it became a module which is decoupled from the app and can be replaced with any other scanner implementation. 

DocumentScanner module solves the problematic areas like quality of photo, blur, glare, darkness etc. since it continuously reads MRZ and emits a Boolean whether document is readable well. This emitter is tied to a button on UI not allowing user take photos when MRZ is not in frame or unreadable.

Furthermore, I continued with main app by creating API layer using a lightweight swift networking library and which also resulted in some work in Scanner viewmodel to consume mentioned API - at this stage requirement #2 is complete.
After this some more tinkering with combine to pass the API response down to another view and we are complete with point #3, data is presented. #4 Brief description is above and #1 is creating the app, see below...


## How the app works

After accepting the Camera permission app displays camera preview and user can try scanning an LT or LV ID card back side, until its done properly, app will display text "try finding better angle". Or try this [dummy ID](ttps://images.app.goo.gl/N4NwtcFBknKjDNay9).

Once user aligns document with camera frame or at least in a distance camera can read it, text on the button will change to "Take photo" until user moves away from the acceptable capture. If user was able to capture the ID, an image preview will appear below, the camera feed will keep running, user can retake pictures, that will overwrite previous capture. 

By tapping on "Use this photo" modal sheet is brought up and photo data is sent to the API for validation, once response comes back, the loading text is replaced either with error or list of validated API data, yumm.


## Improvement areas:

- That messy ViewController for camera preview 
- Error handling
- Tests for JSON parsing
- Tests for ViewModel reactions on various inputs
- Auto detect document type and map it to API type
- Test on various doc types - aspect ratios are hardcoded :|
