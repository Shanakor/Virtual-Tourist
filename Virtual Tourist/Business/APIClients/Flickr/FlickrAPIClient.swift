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

    func getPhotoMetadata(for travelLocation: TransientTravelLocation, page: Int32,
                          completionHandler: @escaping (TransientPhotoAlbum?, [TransientPhoto]?, APIClientError?) -> Void){

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
                completionHandler(nil, nil, error)
                return
            }

            guard let stat = result![ResponseKeys.Status] else{
                completionHandler(nil, nil, APIClientError.parseError(description: "Could not find key '\(ResponseKeys.Status)' in \(result!)"))
                return
            }

            guard let statString = stat as? String, statString == JSONValues.OKStatus else {
                completionHandler(nil, nil, APIClientError.serverError(description: "The server returned a non-ok status!"))
                return
            }

            guard let photosDictionary = result![ResponseKeys.Photos] as? [String: AnyObject] else{
                completionHandler(nil, nil, APIClientError.parseError(description: "Could not find key '\(ResponseKeys.Photos)' in \(result!)"))
                return
            }

            var photoAlbum: TransientPhotoAlbum!
            self.parsePhotoAlbumMetadata(from: photosDictionary){
                album, error in

                guard error == nil else{
                    completionHandler(nil, nil, error)
                    return
                }

                photoAlbum = album
            }

            var photos: [TransientPhoto]!
            self.parsePhotoMetadata(from: photosDictionary){
                photosResult, error in

                guard error == nil else{
                    completionHandler(photoAlbum!, nil, error)
                    return
                }

                photos = photosResult
            }
            
            completionHandler(photoAlbum, photos, nil)
        }
    }

    private func parsePhotoMetadata(from photosDictionary: [String: AnyObject], completionHandler: ([TransientPhoto]?, APIClientError?) -> Void){
        var photos = [TransientPhoto]()

        guard let photoArray = photosDictionary[ResponseKeys.Photo] as? [[String: AnyObject]] else{
            completionHandler(nil, APIClientError.parseError(description: "Could not find key '\(ResponseKeys.Photo)' in \(photosDictionary)"))
            return
        }

        for (i, photoMetadata) in photoArray.enumerated(){
            guard let url = photoMetadata[ResponseKeys.MediumURL] as? String else{
                completionHandler(nil, APIClientError.parseError(description: "Could not find key '\(ResponseKeys.MediumURL)' in \(photoMetadata) at index \(i) of \(photoArray)"))
                return
            }

            photos.append(TransientPhoto(url: url, imageData: nil))
        }

        completionHandler(photos, nil)
    }

    private func parsePhotoAlbumMetadata(from photosDictionary: [String: AnyObject], completionHandler: (TransientPhotoAlbum?, APIClientError?) -> Void){
        guard let page = photosDictionary[ResponseKeys.Page] else{
            completionHandler(nil, APIClientError.parseError(description: "Could not find key '\(ResponseKeys.Page)' in \(photosDictionary)"))
            return
        }

        guard let pageValue = page as? Int32 else{
            completionHandler(nil, APIClientError.parseError(description: "Could not convert \(page) to Integer"))
            return
        }

        guard let pages = photosDictionary[ResponseKeys.Pages] else{
            completionHandler(nil, APIClientError.parseError(description: "Could not find key '\(ResponseKeys.Pages)' in \(photosDictionary)"))
            return
        }

        guard let pagesValue = pages as? Int32 else{
            completionHandler(nil, APIClientError.parseError(description: "Could not convert \(pages) to Integer"))
            return
        }

        completionHandler(TransientPhotoAlbum(page: pageValue, pageCount: pagesValue), nil)
    }

    private func createBBoxString(lat: Double, lon: Double) -> String {
        let validatedMinLon = validate(number: lon - Constants.SearchBBoxHalfWidth, inside: Constants.SearchLonRange)
        let validatedMinLat = validate(number: lat - Constants.SearchBBoxHalfHeight, inside: Constants.SearchLatRange)
        let validatedMaxLon = validate(number: lon + Constants.SearchBBoxHalfWidth, inside: Constants.SearchLonRange)
        let validatedMaxLat = validate(number: lat + Constants.SearchBBoxHalfHeight, inside: Constants.SearchLatRange)

        let bboxArray: [String] = [String(validatedMinLon), String(validatedMinLat), String(validatedMaxLon), String(validatedMaxLat)]

        return bboxArray.joined(separator: ",")
    }

    private func validate(number: Double, inside cyclicRange: (Double, Double)) -> Double {
        if number < cyclicRange.0{
            return cyclicRange.1 - (abs(max(number, cyclicRange.0)) - abs(min(number, cyclicRange.0)))
        }
        else if number > cyclicRange.1{
            return cyclicRange.0 + (abs(max(number, cyclicRange.0)) - abs(min(number, cyclicRange.0)))
        }

        return number
    }

    func downloadPhotoData(of transientPhotos: [TransientPhoto], progressHandler: @escaping (TransientPhoto, APIClientError?) -> Void,
                           completionHandler: @escaping (APIClientError?) -> Void){

        for (i, photo) in transientPhotos.enumerated(){

            guard let url = URL(string: photo.url) else{
                progressHandler(photo, .parseError(description: "The url '\(photo.url)' was invalid!"))
                continue
            }

            taskForData(with: url){
                data, error in

                guard error == nil else{
                    completionHandler(error)
                    return
                }

                progressHandler(TransientPhoto(url: photo.url, imageData: NSData(data: data!)), nil)

                if i == transientPhotos.count - 1{
                    completionHandler(nil)
                }
            }
        }
    }
}
