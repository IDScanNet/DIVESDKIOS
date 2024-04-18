# DIVE SDK for iOS

The DIVE iOS SDK the library integrates the component of capturing the documents and faces from a video to your iOS applications.
Here is a [Demo project](https://github.com/IDScanNet/DIVE-SDK-Demo-iOS)

## Overview

Upon being switched on, the library integrates the component of capturing the documents and faces from a video to your Ionic Capacitor App.

## Use cases

- Capture and determination of the document type
- Capture of pdf417
- Capture of MRZ
- Capture of faces

## Recommendations

Use a modern phone with a good camera having the definition of not less than 8 megapixels.
The capture must be made in a well-lighted room. A document must be located at the uniform background.

## Limitations

Only iOS platform
Minimum deployment target of iOS 13.0

## Request a DIVE Online Username and Password from IDScan.net

Email [support@idscan.net](mailto:support@idscan.net) for a DIVE Online Username and Password

## Installation

### Adding **DIVE-SDK-iOS** to a `Package.swift`

To install the DIVE iOS SDK using Swift Package Manager (SPM):

Add the DIVE-SDK-iOS package to your `Package.swift` file:

```swift
// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "YourProjectName",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/IDScanNet/DIVE-SDK-iOS.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourProjectName",
            dependencies: [
                .product(name: "DIVE-SDK-iOS", package: "DIVE-SDK-iOS")
            ]
        ),
        ...
    ]
)
```

---

### Installing from Xcode (relevant for both Swift and Objective-C projects)

Add the package by selecting `Your project name` → `Package Dependencies` → `+`.

<img src="Docs/resources/addPackage1.png">

Search for the **IDScanIDDetector** using the repo's URL:

```console
https://github.com/IDScanNet/DIVE-SDK-iOS
```

Next, set the `Dependency Rule` to be `Up to Next Major Version` and specify the latest version of the package as the lower bound.

Then, select `Add Package`.

<img src="Docs/resources/addPackage2.png">


Choose the detectors that you want to add to your project.

<img src="Docs/resources/addPackage3.png">

---

## Usage DIVE SDK Online

Using the [web portal](https://diveonline.idscan.net/) or [DIVE API](https://docs.idscan.net/dive/dive-online/api-manual.html) you can create Applicant and use applicant id for check their documents. Use [Create applicant request](https://docs.idscan.net/dive/dive-online/swagger.html#/Applicants/post_api_v2_private_Applicants) by API

In the context of the DIVE Online Web API, the term "applicant" typically refers to the person who is submitting their identification documents for validation. The applicant is the individual whose data is being extracted from the submitted documents, such as their name, date of birth, address, etc.

When making a new validation request using the API, you can provide information about the applicant in the request body, including their first name, last name, phone number, email address, and any additional metadata you want to store. This information is associated with the validation request and can be used to identify the applicant and their submitted documents.

Once you are logged in to the DIVE Online Web Portal create both secret and public tokens, use `public tokens` in your application.

Create `your_integration_id` in [Bundles page](https://diveonline.idscan.net/bundles) of the DIVE Online portal
click `+ Add Bundle` named it and click `add`. Use `Token` from Bundles table as `your_integration_id`

### Swift

```swift
import UIKit
import DIVEOnlineSDK

class ViewController: UIViewController, DIVESDKDelegate {
    let sdk: DIVEOnlineSDK?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sdk = DIVEOnlineSDK(applicantID: "your_applicant_id", integrationID: "your_integration_id", token: "your_public_token", baseURL: "https://api-dvsonline.idscan.net/api/v2/public")
        sdk?.delegate = self
    }
    
    func diveSDKResult(sdk: Any, result: [String: Any]) {
        print("DIVE SDK Result: \(result)")
    }
    
    func diveSDKError(sdk: Any, error: Error) {
        print("DIVE SDK Error: \(error.localizedDescription)")
    }
}
```

### Objective-C

```objc
@import DIVEOnlineSDK;

@interface ViewController () <DIVESDKDelegate>

@property (nonatomic, strong) DIVEOnlineSDK *sdk;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sdk = [[DIVEOnlineSDK alloc] initWithApplicantID:@"your_applicant_id"
                                              integrationID:@"your_integration_id"
                                                    token:@"your_public_token"
                                                   baseURL:@"https://api-dvsonline.idscan.net/api/v2/public"];
    self.sdk.delegate = self;
}

- (void)diveSDKResult:(DIVEOnlineSDK *)sdk result:(NSDictionary *)result {
    NSLog(@"DIVE SDK Result: %@", result);
}

- (void)diveSDKError:(DIVEOnlineSDK *)sdk error:(NSError *)error {
    NSLog(@"DIVE SDK Error: %@", error.localizedDescription);
}

@end
```

## Result explaining

 Here's a table explaining the key-value pairs in the `result` dictionary returned by the `diveSDKResult` method:

| Key | Value Type | Description |
| --- | --- | --- |
| `validationRequestId` | `String` | The unique ID of the validation request. |
| `document` | `NSDictionary` | A dictionary containing the identified document's data. |
| `documentFailStatusReasons` | `NSArray<String>` | An array of reasons if the document validation failed. |
| `faceFailStatusReasons` | `NSArray<String>` | An array of reasons if the face validation failed. |
| `invalidDataErrors` | `NSArray<NSDictionary>` | An array of dictionaries containing the code and message for any invalid data errors. |
| `validationResponseId` | `NSInteger` | The unique ID of the validation response. |
| `created` | `NSString` | The date and time when the validation response was created |
| `documentType` | `NSString` | The type of the identified document (e.g., "passport", "driverLicense"). |
| `documentTypeInt` | `NSInteger` | The integer representation of the document type. |
| `status` | `NSInteger` | The validation status of the document (0: valid, 1: fake, 2: data error, 3: server error). |
| `validationStatus` | `NSDictionary` | A dictionary containing the validation status of the document and face. |
| `validationStatus.expired` | `BOOL` | A boolean indicating whether the document is expired or not. |
| `validationStatus.documentIsValid` | `BOOL` | A boolean indicating whether the document is valid or not. |
| `validationStatus.faceIsValid` | `BOOL` | A boolean indicating whether the face in the document matches the user's face or not. |

Listed below are the possible values and descriptions:

*   **- status** - possible values: 0, 1, 2, 3

    `0` - document is valid

    `1` - document is fake

    `2` - data error. If a document is of poor quality and we are not able to identify it, this status will be shown. Also in the field "InvalidDataErrors" there will be a list of problems related to the code and to the message.

    `3` - server error during the document identification

*   **- validationStatus** - list of meanings for validation steps.

   `expired` - whether the license is valid at the moment of validation or not

   `documentIsValid` - whether a document is valid or not

   `faceIsValid` - whether the face in the document coincides with the face of the user.

> [!NOTE]
> `expired` - does not influence the final decision with respect to the validity of the document and only serves as a guideline.
You can access the values in the `result` dictionary using the keys listed above. For example, to get the validation request ID, you can use:

```swift
if let validationRequestId = result["validationRequestId"] as? String {
    print("Validation Request ID: \(validationRequestId)")
}
```

In Objective-C:

```objc
NSString *validationRequestId = result[@"validationRequestId"];
NSLog(@"Validation Request ID: %@", validationRequestId);
```

## Request a DIVE Online Username and Password from IDScan.net

Email [support@idscan.net](mailto:support@idscan.net) for a DIVE Online Username and Password