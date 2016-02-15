//
//  LoginViewController.swift
//  MyFavoriteMovies
//
//  Created by Jarrod Parkes on 1/23/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import UIKit

// MARK: - LoginViewController: UIViewController

class LoginViewController: UIViewController {
    
    // MARK: Properties
    
    var appDelegate: AppDelegate!
    var keyboardOnScreen = false
    
    // MARK: Outlets
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: BorderedButton!
    @IBOutlet weak var debugTextLabel: UILabel!
        
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get the app delegate
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate                        
        
        configureUI()
        
        subscribeToNotification(UIKeyboardWillShowNotification, selector: Constants.Selectors.KeyboardWillShow)
        subscribeToNotification(UIKeyboardWillHideNotification, selector: Constants.Selectors.KeyboardWillHide)
        subscribeToNotification(UIKeyboardDidShowNotification, selector: Constants.Selectors.KeyboardDidShow)
        subscribeToNotification(UIKeyboardDidHideNotification, selector: Constants.Selectors.KeyboardDidHide)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }
    
    // MARK: Login
    
    @IBAction func loginPressed(sender: AnyObject) {
        
        userDidTapView(self)
        
       // if usernameTextField.text!.isEmpty || passwordTextField.text!.isEmpty {
         //   debugTextLabel.text = "Username or Password Empty."
        //} else {
          //  setUIEnabled(false)
            
            /*
                Steps for Authentication...
                https://www.themoviedb.org/documentation/api/sessions
                
                Step 1: Create a request token
                Step 2: Ask the user for permission via the API ("login")
                Step 3: Create a session ID
                
                Extra Steps...
                Step 4: Get the user id ;)
                Step 5: Go to the next view!            
            */
            getRequestToken()
        //}
    }
    
    private func completeLogin() {
        performUIUpdatesOnMain {
            self.debugTextLabel.text = ""
            self.setUIEnabled(true)
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("MoviesTabBarController") as! UITabBarController
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    // MARK: TheMovieDB
    
    private func getRequestToken() {
        
        /* TASK: Get a request token, then store it 
         * (appDelegate.requestToken) and login with the token 
        */
        
        /* 1. Set the parameters */
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey
        ]
        
        /* 2/3. Build the URL, Configure the request */
        let request = NSURLRequest(URL: appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/authentication/token/new"))
        
        
        /* 4. Make the request */
        let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
            
            // create an small function
            func displayError(error:String)
            {
             print(error)
             performUIUpdatesOnMain{
                    self.debugTextLabel.text = error
                    self.setUIEnabled(true)
                }
                
            }
            
            // do we have an error?
            guard (error == nil) else {
             displayError("getRequestToken: Error :  \(error)")
             return
            }

            // Did we get a successful 2XX response?
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {

                    displayError(" getRequestToken: Invalid Response Code ")
                    return
            }
            
            // Do we have any data?
            guard ((data) != nil) else {
                displayError("getRequestToken: No Request Data")
                return
            }
                
            // All good. Parse the data
            let parsedResult: AnyObject!

            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                
            } catch {
                parsedResult = nil
                self.debugTextLabel.text = "getRequestToken : could not parse the data as JSON: \(data)"
                return
            }
            
            
            /*
            * GUARD: Was the operation successful
            * The guard statement puts the emphasis on the error condition.
            * In this case, if there is no value, you can clearly see what will be done
            * to deal with it.
            * https://www.natashatherobot.com/swift-guard-better-than-if/
            */
            
            guard let stat = parsedResult[Constants.TMDBResponseKeys.Success] as? Int where stat == 1 else {
                self.debugTextLabel.text = "getRequestToken : Parsed result was not successful. See error code and message in:  \(parsedResult)"
                return
            }
            
            /* 6. Use the data */
            if  let token  = parsedResult[Constants.TMDBResponseKeys.RequestToken] as? String {
                
                self.appDelegate.requestToken = token
                self.loginWithToken(token)
                
            }
            else {
                self.debugTextLabel.text = "getRequestToken : Cannot find key 'request_token' in \(parsedResult)"
                return
            }
        
        }

        /* 7. Start the request */
        task.resume()
    }
    
    private func loginWithToken(requestToken: String) {
        
        /* TASK: Login, then get a session id */
        
        
        /* 1. Set the parameters */
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey
            ,Constants.TMDBParameterKeys.RequestToken: requestToken
            ,Constants.TMDBParameterKeys.Username: usernameTextField.text!
            ,Constants.TMDBParameterKeys.Password: passwordTextField.text!
        ]
        
        /* 2/3. Build the URL, Configure the request */
        let request = NSURLRequest(URL: appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/authentication/token/validate_with_login"))
       
        /* 4. Make the request */
        let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
            
            // create an small function
            func displayError(error:String)
            {
                print(error)
                performUIUpdatesOnMain{
                    self.debugTextLabel.text = error
                    self.setUIEnabled(true)
                }
                
            }
            
            // do we have an error?
            guard (error == nil) else {
                print("loginWithToken: Error :  \(error)")
                displayError(" loginWithToken: Error :  \(error)")
                return
            }
            
            // Did we get a successful 2XX response?
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                
                displayError(" loginWithToken: Invalid Response Code ")
                return
            }
            
            // Do we have any data?
            guard ((data) != nil) else {
                displayError("loginWithToken: No Request Data")
                return
            }
            
            // All good. Parse the data
            let parsedResult: AnyObject!
            
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                
            } catch {
                parsedResult = nil
                displayError("loginWithToken : could not parse the data as JSON: \(data)")
                return
            }
            
            
            /*
            * GUARD: Was the operation successful
            * The guard statement puts the emphasis on the error condition.
            * In this case, if there is no value, you can clearly see what will be done
            * to deal with it.
            * https://www.natashatherobot.com/swift-guard-better-than-if/
            */
            
            guard let stat = parsedResult[Constants.TMDBResponseKeys.Success] as? Int where stat == 1 else {
                displayError("loginWithToken : Parsed result was not successful. See error code and message in:  \(parsedResult)")
                return
            }
            
            /* 6. Use the data */
            if  let token  = parsedResult[Constants.TMDBResponseKeys.RequestToken] as? String {
                
                //self.appDelegate.requestToken = token
                self.getSessionID(token)
                
            }
            else {
                displayError("loginWithToken : Cannot find key 'request_token' in \(parsedResult)")
                return
            }
            
        }
        
        /* 7. Start the request */
        task.resume()
        

    }
    
    private func getSessionID(requestToken: String) {
        
        /* TASK: Get a session ID, then store it (appDelegate.sessionID) and get the user's id */
        
        /* 1. Set the parameters */
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey
            ,Constants.TMDBParameterKeys.RequestToken: requestToken
        ]
        
        /* 2/3. Build the URL, Configure the request */
        let request = NSURLRequest(URL: appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/authentication/session/new"))
        
        /* 4. Make the request */
        let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
            
            // create an small function
            func displayError(error:String)
            {
                print(error)
                performUIUpdatesOnMain{
                    self.debugTextLabel.text = error
                    self.setUIEnabled(true)
                }
                
            }
            
            // do we have an error?
            guard (error == nil) else {
                print("getSessionID: Error :  \(error)")
                displayError(" getSessionID: Error :  \(error)")
                return
            }
            
            // Did we get a successful 2XX response?
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                
                displayError(" getSessionID: Invalid Response Code ")
                return
            }
            
            // Do we have any data?
            guard ((data) != nil) else {
                displayError("getSessionID: No Request Data")
                return
            }
            
            // All good. Parse the data
            let parsedResult: AnyObject!
            
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                
            } catch {
                parsedResult = nil
                displayError("getSessionID : could not parse the data as JSON: \(data)")
                return
            }
            
            
            /*
            * GUARD: Was the operation successful
            * The guard statement puts the emphasis on the error condition.
            * In this case, if there is no value, you can clearly see what will be done
            * to deal with it.
            * https://www.natashatherobot.com/swift-guard-better-than-if/
            */
            
            guard let stat = parsedResult[Constants.TMDBResponseKeys.Success] as? Int where stat == 1 else {
                displayError("getSessionID : Parsed result was not successful. See error code and message in:  \(parsedResult)")
                return
            }
            
            /* 6. Use the data */
            if  let session_id  = parsedResult[Constants.TMDBResponseKeys.SessionID] as? String {
                
                self.getUserID(session_id)
                self.appDelegate.sessionID = session_id
                
            }
            else {
                displayError("getSessionID : Cannot find key 'session_id' in \(parsedResult)")
                return
            }
            
        }
        
        /* 7. Start the request */
        task.resume()

    }
    
    private func getUserID(sessionID: String) {
        
        /* TASK: Get the user's ID, then store it (appDelegate.userID) 
         * for future use and go to next view! 
        */
        
        /* 1. Set the parameters */
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey
            ,Constants.TMDBParameterKeys.SessionID: sessionID
        ]
        
        /* 2/3. Build the URL, Configure the request */
        let request = NSURLRequest(URL: appDelegate.tmdbURLFromParameters(methodParameters, withPathExtension: "/account"))
        
        /* 4. Make the request */
        let task = appDelegate.sharedSession.dataTaskWithRequest(request) { (data, response, error) in
            
            // create an small function
            func displayError(error:String)
            {
                print(error)
                performUIUpdatesOnMain{
                    self.debugTextLabel.text = error
                    self.setUIEnabled(true)
                }
                
            }
            
            // do we have an error?
            guard (error == nil) else {
                displayError(" getUserID: Error :  \(error)")
                return
            }
            
            // Did we get a successful 2XX response?
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                
                displayError(" getUserID: Invalid Response Code ")
                return
            }
            
            // Do we have any data?
            guard ((data) != nil) else {
                displayError("getUserID: No Request Data")
                return
            }
            
            // All good. Parse the data
            let parsedResult: AnyObject!
            
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                
            } catch {
                parsedResult = nil
                displayError("getUserID : could not parse the data as JSON: \(data)")
                return
            }
            
            
            
            /* 6. Use the data */
            if  let user_id  = parsedResult[Constants.TMDBResponseKeys.UserID] as? Int {
                
                self.appDelegate.userID = user_id
                self.completeLogin()
                
            }
            else {
                displayError("getUserID : Cannot find key 'id' in \(parsedResult)")
                return
            }
            
        }
        
        /* 7. Start the request */
        task.resume()
    }
}

// MARK: - LoginViewController: UITextFieldDelegate

extension LoginViewController: UITextFieldDelegate {
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: Show/Hide Keyboard
    
    func keyboardWillShow(notification: NSNotification) {
        if !keyboardOnScreen {
            view.frame.origin.y -= keyboardHeight(notification)
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if keyboardOnScreen {
            view.frame.origin.y += keyboardHeight(notification)
        }
    }
    
    func keyboardDidShow(notification: NSNotification) {
        keyboardOnScreen = true
    }
    
    func keyboardDidHide(notification: NSNotification) {
        keyboardOnScreen = false
    }
    
    private func keyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    
    private func resignIfFirstResponder(textField: UITextField) {
        if textField.isFirstResponder() {
            textField.resignFirstResponder()
        }
    }
    
    @IBAction func userDidTapView(sender: AnyObject) {
        resignIfFirstResponder(usernameTextField)
        resignIfFirstResponder(passwordTextField)
    }
}

// MARK: - LoginViewController (Configure UI)

extension LoginViewController {
    
    private func setUIEnabled(enabled: Bool) {
        usernameTextField.enabled = enabled
        passwordTextField.enabled = enabled
        loginButton.enabled = enabled
        debugTextLabel.text = ""
        debugTextLabel.enabled = enabled
        
        // adjust login button alpha
        if enabled {
            loginButton.alpha = 1.0
        } else {
            loginButton.alpha = 0.5
        }
    }
    
    private func configureUI() {
        
        // configure background gradient
        let backgroundGradient = CAGradientLayer()
        backgroundGradient.colors = [Constants.UI.LoginColorTop, Constants.UI.LoginColorBottom]
        backgroundGradient.locations = [0.0, 1.0]
        backgroundGradient.frame = view.frame
        view.layer.insertSublayer(backgroundGradient, atIndex: 0)
        
        configureTextField(usernameTextField)
        configureTextField(passwordTextField)
    }
    
    private func configureTextField(textField: UITextField) {
        let textFieldPaddingViewFrame = CGRectMake(0.0, 0.0, 13.0, 0.0)
        let textFieldPaddingView = UIView(frame: textFieldPaddingViewFrame)
        textField.leftView = textFieldPaddingView
        textField.leftViewMode = .Always
        textField.backgroundColor = Constants.UI.GreyColor
        textField.textColor = Constants.UI.BlueColor
        textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
        textField.tintColor = Constants.UI.BlueColor
        textField.delegate = self
    }
}

// MARK: - LoginViewController (Notifications)

extension LoginViewController {
    
    private func subscribeToNotification(notification: String, selector: Selector) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: selector, name: notification, object: nil)
    }
    
    private func unsubscribeFromAllNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}