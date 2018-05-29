Imgur Starter
-------------

### Description

An iOS App written in Swift that provides a user interface and displays a user’s
Imgur account images using the Imgur API Service.

### This app provides the following Imgur functionality:

-   Allows a user to login to thier Imgur account using OAuth2 Authorization

-   Display up to 100 of the user's images (maximum allowed per page).

-   Upload images from the user's Photo library - with the ability to cancel the
    upload at any time

-   Delete images from the user's Imgur account - prompting the user to confirm
    deletion


### To build the app

1.  clone this repo git clone git@github.com:stulevine/ImgurStarter.git

2.  open the project file in Xcode 9.x

3.  build and run


### App Structure and Design

-   MVC and some MVVM

-   Network Engine - provides asynchronous API calls, image downloads/uploads
    using URLSessionDataTask and URLSessionDataDelegate with a serial based
    background OperationQueue

-   ImgurClient - the main API engine for the app

-   Several models utilize the *Codable* protocol to provide seamless
    consumption of the Imgur API JSON model responses and request objects

-   Provided keychain wrapper framework KeychainSwift (via Cocoa Pods)

-   Utilize the Apple Keychain to store user information including the user id,
    auth token, refresh token, auth token expiry and username.  All of which are
    required to make authenticated Imgur API calls.

-   Applied a custom URL scheme to allow the Imgur callback url to return to the
    app and consume the user authorization.  Instead of opening Safari to allow
    the user to authenticate and authorize, I utilize the SFSafariViewController
    so the user never actually leaves the application.

-   Added several class extensions to provide additional functionality to
    existing Foundation and UIKit frameworks

-   Provided network availability monitoring using the Reachability framework
    (via CocoaPods)

-   Used the Main storyboard for the initial view controller instantiation from
    the AppDelegate.  However, all views within the initial view controller, and
    all other view controllers, are setup programmatically using layout anchors

-   Provided a couple of Unit tests for the Image and Photo upload models

-   Used keyframe animation in places for better UI experience with keyed
    animation components

-   Cocoa Pods dependency manager used to include third party frameworks


### App Features

-   *UICollectionView* used to display thumbnails for the user images

-   *UIToolBar* at the bottom of the screen for actionable items related to
    Imgur

-   Photo display when selecting an item from the collection view - includes
    image scrolling and zooming, as well as the ability to delete a photo and
    export it using the *UIDocumentInteractionController* using an action menu
    from the *UINavigationBar*.

-   3D Touch (Force touch) allows a user to preview and pop from a photo
    selected from the images collection view.

-   Image loading progress provided when downloading an image for a cell

-   Provided upload progress and the ability to cancel a stalled upload.

-   Allow a user to pick a photo from the Photo Library to upload to their Imgur
    account using the *UIImagePickerController* and delegate

-   Provided a slide up auto-dismissing alert view when network availability
    changes.  User can tap the view to dismiss it prior to the auto-dismiss time
    (5s)

-   Provided pull-to-refresh


### What Features/Designs were not provided in the app?  If only I had more time...

-   Infinite scrolling and paging of a user’s Imgur images in the collection
    view.

-   A model/class for the collection view data source - to load photos from the
    API server.  This is currently handled by the view controller.

-   A bit more error checking and handling of request timeouts.

-   The ability to view other content types - currently the app only supports
    still images.

-   Image caching, either using *Cache*, files or *CoreData*

-   Model caching via *CoreData*

-   Provide all sizes for assets (only 3x provided)

-   Provide an AppIcon image set

-   Provide a lauch acreen with launch animation

