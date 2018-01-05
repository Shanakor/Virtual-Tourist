//
// Created by Niklas Rammerstorfer on 26.11.17.
// Copyright (c) 2017 Niklas Rammerstorfer. All rights reserved.
//

import Foundation

class APIClient {

    // MARK: Abstract request methods

    public func taskForHTTPMethod(method: String?, withPathExtension pathExtension: String?, methodParameters: [String: String]?, jsonBody: Data?,
                                  createRequest: (URL, Data?) -> URLRequest,
                                  completionHandler: @escaping ([String: AnyObject]?, APIClientError?) -> Void = { _, _ in }){

        guard let URL = createURL(method: method, withPathExtension: pathExtension, methodParameters: methodParameters) else{
            completionHandler(nil, .initializationError(description: "Cannot form a valid URL with the given parameters!"))
            return
        }

        let request = createRequest(URL, jsonBody)

        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in

            // GUARD: Did the request fail?
            guard error == nil else {
                completionHandler(nil, .connectionError(description: "Request failed. Request: \(request)"))
                return
            }

            // GUARD: Did the request return status code OK?
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode >= 200 || httpResponse.statusCode <= 299 else {
                completionHandler(nil, .connectionError(description: "Status code was other than 2XX!"))
                return
            }

            // GUARD: Did the request return actual data?
            guard let data = data else {
                completionHandler(nil, .connectionError(description: "No data was returned!"))
                return
            }

            self.parseData(data, completionHandler: completionHandler)
        }

        task.resume()
    }

    func parseData(_ data: Data, completionHandler: @escaping ([String: AnyObject]?, APIClientError?) -> Void) {

        let parsedResult: [String: AnyObject]!

        do{
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
        }
        catch{
            completionHandler(nil, .parseError(description: "Could not convert to JSON from \(data)"))
            return
        }

        completionHandler(parsedResult, nil)
    }

    public func taskForGETMethod(method: String?, withPathExtension pathExtension: String?, methodParameters: [String: String]?, completionHandlerForGET: @escaping ([String: AnyObject]?, APIClientError?) -> Void = { _, _ in }){

        let createParseAPIRequest = {(URL: URL, jsonBody: Data?) in
            self.createGETRequest(URL: URL)
        }

        taskForHTTPMethod(method: method, withPathExtension: pathExtension, methodParameters: methodParameters, jsonBody: nil,
                createRequest: createParseAPIRequest,
                completionHandler: completionHandlerForGET)
    }

    public func taskForPOSTMethod(method: String?, withPathExtension pathExtension: String?, methodParameters: [String: String]?, jsonBody: Data?, completionHandlerForPOST: @escaping ([String: AnyObject]?, APIClientError?) -> Void = { _, _ in }){

        taskForHTTPMethod(method: method, withPathExtension: pathExtension, methodParameters: methodParameters, jsonBody: jsonBody,
                createRequest: createPOSTRequest, completionHandler: completionHandlerForPOST)
    }

    public func taskForPUTMethod(method: String?, withPathExtension pathExtension: String?, methodParameters: [String: String]?, jsonBody: Data?, completionHandlerForPUT: @escaping ([String: AnyObject]?, APIClientError?) -> Void = { _, _ in }){

        taskForHTTPMethod(method: method, withPathExtension: pathExtension, methodParameters: methodParameters, jsonBody: jsonBody,
                createRequest: createPUTRequest, completionHandler: completionHandlerForPUT)
    }

    public func taskForDELETEMethod(method: String?, withPathExtension pathExtension: String?, methodParameters: [String: String]?, jsonBody: Data?, completionHandlerForDELETE: @escaping ([String: AnyObject]?, APIClientError?) -> Void = { _, _ in }){

        taskForHTTPMethod(method: method, withPathExtension: pathExtension, methodParameters: methodParameters, jsonBody: jsonBody,
                createRequest: createDELETERequest, completionHandler: completionHandlerForDELETE)
    }

    // MARK: Methods to be overridden by subclasses

    func createURL(method: String?, withPathExtension pathExtension: String?, methodParameters: [String: String]?) -> URL? {
        preconditionFailure("This method must be overridden")
    }

    func createGETRequest(URL: URL) -> URLRequest{
        preconditionFailure("This method must be overridden")
    }

    func createPOSTRequest(URL: URL, jsonBody: Data?) -> URLRequest{
        preconditionFailure("This method must be overridden")
    }

    func createPUTRequest(URL: URL, jsonBody: Data?) -> URLRequest{
        preconditionFailure("This method must be overridden")
    }

    func createDELETERequest(URL: URL, jsonBody: Data?) -> URLRequest{
        preconditionFailure("This method must be overridden")
    }

    // MARK: Error definitions

    enum APIClientError: CustomStringConvertible, Error{
        case initializationError(description: String)
        case connectionError(description: String)
        case parseError(description: String)
        case serverError(description: String)

        var description: String {
            switch self {
            case .initializationError(let description):
                return "Initialization error: \(description)"
            case .connectionError(let description):
                return "Connection failure: \(description)"
            case .parseError(let description):
                return "Parse failure: \(description)"
            case .serverError(let description):
                return "Server returned error: \(description)"
            }
        }
    }
}
