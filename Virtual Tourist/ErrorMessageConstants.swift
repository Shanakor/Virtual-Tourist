//
// Created by Niklas Rammerstorfer on 07.01.18.
// Copyright (c) 2018 Niklas Rammerstorfer. All rights reserved.
//

import Foundation

class ErrorMessageConstants {
    struct AlertDialogStrings{

        struct ConnectionError {
            static let Title = "Connection failed"
            static let Message = "Please try again or verify that you are connected to the internet."
        }

        struct CredentialError{
            static let Title = "Unauthorized"
            static let Message = "You entered an invalid username or password."
        }

        struct LocationError {
            static let Title = "Invalid location"
            static let Message = "We were unable to find the entered location. Try to be more specific."
        }

        struct OverwriteAlert {
            static let Title = ""
            static let Message = "You have already posted a student location. Would you like to overwrite it?"
            static let PositiveAction = "Overwrite"
            static let NegativeAction = "Cancel"
        }

        struct ParseError{
            static let Title = "Parse error"
            static let Message = "We could not process the data that was returned by the server. We are probably looking" +
                    " into it this very moment."
        }

        struct UploadError{
            static let Title = "Uploading failed"
            static let Message = "We were unable to upload the location."
            static let PositiveAction = "Retry"
            static let NegativeAction = "Discard"
        }
    }
}
