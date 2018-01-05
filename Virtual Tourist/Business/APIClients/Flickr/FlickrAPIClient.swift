//
// Created by Niklas Rammerstorfer on 25.11.17.
// Copyright (c) 2017 Niklas Rammerstorfer. All rights reserved.
//

import Foundation

class FlickrAPIClient: APIClient {

    // MARK: Properties

    static let shared = FlickrAPIClient()

    // MARK: APIClient members

    override func createURL(method: String?, withPathExtension pathExtension: String?, methodParameters: [String: String]?) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = Constants.APIScheme
        urlComponents.host = Constants.APIHost
        urlComponents.path = Constants.APIPath + (method ?? "") + (pathExtension ?? "")

        // Construct the query.
        if let methodParameters = methodParameters,
           methodParameters.count != 0{
            var queryItems = [URLQueryItem]()

            for (key, value) in methodParameters{
                queryItems.append(URLQueryItem(name: key, value: value))
            }

            urlComponents.queryItems = queryItems
        }

        return urlComponents.url
    }

    override func createGETRequest(URL: URL) -> URLRequest {
        return URLRequest(url: URL)
    }

    // MARK: Convenience methods

    func getPhotoAlbumInformation(photoAlbum: PhotoAlbum,  page: Int = 1, completionHandler: @escaping ([AnyObject]?, APIClientError?) -> Void){
        guard let travelLocation = photoAlbum.travelLocation else{
            fatalError("The passed photoAlbum has to be assigned to a travel location!")
        }

        // Construct method parameters.
        let methodParameters = [
            QueryKeys.Method: QueryValues.SearchMethod,
            QueryKeys.APIKey: QueryValues.APIKey,
            QueryKeys.SafeSearch: QueryValues.UseSafeSearch,
            QueryKeys.Extras: QueryValues.MediumURL,
            QueryKeys.Format: QueryValues.ResponseFormat,
            QueryKeys.NoJSONCallback: QueryValues.DisableJSONCallback,
            QueryKeys.PerPage: QueryValues.PerPage,
            QueryKeys.Page: String(page),
            QueryKeys.BoundingBox: createBBoxString(lat: travelLocation.latitude, lon: travelLocation.longitude)
        ]

        // Make the request.
        taskForGETMethod(method: nil, withPathExtension: nil, methodParameters: methodParameters){
            (result, error) in

            guard error == nil else{
                completionHandler(nil, error)
                return
            }

            photoAlbum = parsePhotoAlbumInformation(result!, photoAlbum: photoAlbum)
            
            completionHandler(result!, error)
        }
    }

//    private func parseImageURLs(_ imagesDictionary: [String: AnyObject], completionHandler: @escaping ([URL]?, APIClientError?) -> Void){
//        let urls = [URL]()
//
//        guard let stat = imagesDictionary[ResponseKeys.Status],
//              let statString = stat as? String,
//              statString == JSONValues.OKStatus else {
//
//            completionHandler(nil, APIClientError.serverError(description: "The server returned a non-ok status!"))
//            return
//        }
//    }

    private func parsePhotoAlbumInformation(_ dictionary: [String: AnyObject], photoAlbum: PhotoAlbum) -> PhotoAlbum {
    }

    private func createBBoxString(lat: Double, lon: Double) -> String {
        let validatedMinLon = validate(lon - Constants.SearchBBoxHalfWidth, cyclicRange: Constants.SearchLonRange)
        let validatedMinLat = validate(lat - Constants.SearchBBoxHalfHeight, cyclicRange: Constants.SearchLatRange)
        let validatedMaxLon = validate(lon + Constants.SearchBBoxHalfWidth, cyclicRange: Constants.SearchLonRange)
        let validatedMaxLat = validate(lat + Constants.SearchBBoxHalfHeight, cyclicRange: Constants.SearchLatRange)

        let bboxArray: [String] = [String(validatedMinLon), String(validatedMinLat), String(validatedMaxLon), String(validatedMaxLat)]

        return bboxArray.joined(separator: ",")
    }

    private func validate(_ number: Double, cyclicRange: (Double, Double)) -> Double {
        if number < cyclicRange.0{
            return cyclicRange.1 - (abs(max(number, cyclicRange.0)) - abs(min(number, cyclicRange.0)))
        }
        else if number > cyclicRange.1{
            return cyclicRange.0 + (abs(max(number, cyclicRange.0)) - abs(min(number, cyclicRange.0)))
        }

        return number
    }

//    private func parseImagesData(_ parsedResult: [String: AnyObject], completionHandler: @escaping ([StudentInformation]?, APIClientError?) -> Void){
//        guard let resultArray = parsedResult[JSONKeys.Results] as? [[String: AnyObject]] else{
//            completionHandler(nil, APIClientError.parseError(description: "Cannot find key '\(JSONKeys.Results)' in \(parsedResult)"))
//            return
//        }
//
//        let studentInformations = StudentInformation.studentInformations(from: resultArray)
//        completionHandler(studentInformations, nil)
//    }
}
