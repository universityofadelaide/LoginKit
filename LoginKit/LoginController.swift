import UIKit
import SVProgressHUD

/**
 This LoginController displays a configurable login screen that is used by the rest
 of the library.
 */
public class LoginController: UIViewController, UITextFieldDelegate {

    var centerCoords: CGFloat {
        return (self.view.frame.size.width/2) - (235/2)
    }

    var username: UITextField = UITextField()
    var password: UITextField = UITextField()

    var savePasswordButton: UIButton!

    /** 
    This LoginController displays a configurable login screen that is used by the rest
     of the library.
     */
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginController.stopEditing))
        view.addGestureRecognizer(tap)

        let logoHeader = header()
        view.addSubview(logoHeader)

        view.backgroundColor = Appearance.backgroundColor

        self.username = buildField("Username", top: 250)
        self.username.returnKeyType = .Next
        self.password = buildField("Password", top: 320)
        self.password.returnKeyType = .Go

        self.password.secureTextEntry = true
        self.view.addSubview(self.username)
        self.view.addSubview(self.password)

        self.savePasswordButton = UIButton()
        self.savePasswordButton.setTitle("Save login", forState: .Normal)

        // Get bundle image
        let normalImage = UIImage(named: "LoginKit.bundle/images/icon_unchecked", inBundle: LoginKit.bundle(), compatibleWithTraitCollection: nil) ?? UIImage()
        let selectedImage = UIImage(named: "LoginKit.bundle/images/icon_checked", inBundle: LoginKit.bundle(), compatibleWithTraitCollection: nil) ?? UIImage()

        
        self.savePasswordButton.setImage(normalImage, forState: .Normal)
        self.savePasswordButton.setImage(selectedImage, forState: .Selected)
        self.savePasswordButton.imageView?.tintColor = Appearance.whiteColor
        self.savePasswordButton.addTarget(self, action: #selector(LoginController.savePasswordTapped), forControlEvents: .TouchUpInside)
        self.view.addSubview(self.savePasswordButton)
        self.savePasswordButton.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
        self.savePasswordButton.titleLabel?.font = self.password.font
        self.savePasswordButton.frame = CGRect(
            x: self.password.frame.minX,
            y: self.password.frame.maxY + 3,
            width: self.password.frame.width,
            height: self.password.frame.height)
        self.savePasswordButton.imageEdgeInsets = UIEdgeInsets(top: 0.0, left: self.savePasswordButton.frame.width - (normalImage.size.width + 32.0), bottom: 0.0, right: 0.0)
        self.savePasswordButton.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: normalImage.size.width + 30)
        if LoginKitConfig.savedLogin == false {
            self.savePasswordButton.hidden = true
        }

        let login = UIButton(type: UIButtonType.System)
        login.setTitle("Login", forState: UIControlState.Normal)
        login.titleLabel?.font = UIFont.boldSystemFontOfSize(17)
        login.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        login.clipsToBounds = true
        login.layer.cornerRadius = 5
        login.sizeToFit()
        login.layer.borderColor = Appearance.buttonBorderColor.CGColor
        login.layer.borderWidth = 1.0
        login.backgroundColor = Appearance.buttonColor
        if LoginKitConfig.savedLogin == true {
            login.frame = CGRect(x: centerCoords, y: self.savePasswordButton.frame.maxY + 3, width: 235, height: 50)
        } else {
            login.frame = CGRect(x: centerCoords, y: self.password.frame.maxY + 20, width: 235, height: 50)
        }
        login.addTarget(self,
            action: #selector(LoginController.performLogin(_:)),
            forControlEvents: UIControlEvents.TouchUpInside)
        login.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]
        self.view.addSubview(login)
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let user = LoginService.user {
            // Password is saved
            if user.authToken != nil {
                openDestination()
            } else {
                NSLog("ERROR")
            }
        }
        if let password = LoginService.user?.password, let username = LoginService.user?.username
            where password.characters.count > 0 && username.characters.count > 0 {
            openDestination()
        }
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let user = LoginService.user {
            self.username.text = user.username
            self.password.text = user.password
        }
    }

    func header() -> UIView {
        let view: UIView = UIView()
        view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 200)
        let myImage = LoginKitConfig.logoImage
        let imageView = UIImageView(image: myImage)

        var imageFrame = imageView.frame
        imageFrame.size.height = 250
        imageFrame.size.width = self.view.frame.size.width
        imageView.frame = imageFrame
        view.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]

        imageView.contentMode = .ScaleAspectFit
        imageView.bounds = CGRectInset(imageView.frame, 20.0, 25.0)
        view.addSubview(imageView)
        return view
    }

    func buildField(name: String, top: CGFloat) -> UITextField {
        let field = UITextField()
        field.sizeToFit()
        field.delegate = self
        let placeholderText = name
        let attrs = [NSForegroundColorAttributeName: UIColor.grayColor()]
        let placeholderString = NSMutableAttributedString(string: placeholderText, attributes: attrs)
        field.attributedPlaceholder = placeholderString
        let cord: CGFloat = 235
        let width: CGFloat = 50
        field.frame = CGRect(x: centerCoords, y: top, width: cord, height: width)
        field.borderStyle = UITextBorderStyle.RoundedRect

        // Enhancements
        field.autocorrectionType = UITextAutocorrectionType.No
        field.autocapitalizationType = UITextAutocapitalizationType.None
        field.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin]

        return field
    }
    
    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if textField == self.username {
            self.password.becomeFirstResponder()
        }
        
        if textField == self.password {
            self.performLogin(nil)
        }
        
        return false // We do not want UITextField to insert line-breaks.
    }

    func performLogin(sender: UIButton!) {

        if let username = self.username.text, let password = self.password.text
            where username.characters.count > 0 && password.characters.count > 0 {
            
            LoginService.user = User(id: username, username: username)
            LoginService.user?.password = password

                if LoginKitConfig.authType == AuthType.JWT {
                    let parameters: Dictionary<String, AnyObject> = [
                        "email": username,
                        "password": password
                    ]

                    SVProgressHUD.show()
                    LoginService.request(.POST, LoginKitConfig.loginPath, parameters: parameters).validate()
                        .responseJSON() { response in
                            SVProgressHUD.dismiss()


                            if response.result.isSuccess {
                                switch response.response!.statusCode {
                                case 201, 200:
                                    self.saveToken(response.result.value!)

                                default:
                                    print("performLogin action: unknown status code")
                                }
                            }
                    }

                }

                if LoginKitConfig.authType == AuthType.Basic {

                    SVProgressHUD.show()
                    LoginService.request(.GET, LoginKitConfig.loginPath, parameters: nil).validate()
                        .authenticate(user: username, password: password)
                        .responseJSON() { response in
                            SVProgressHUD.dismiss()

                            if response.result.isSuccess {
                                switch response.response!.statusCode {
                                case 201, 200:
                                    self.openDestination()
                                default:
                                    print("performLogin action: unknown status code")
                                }
                            }
                    }
                }


        } else {
            let alert = UIAlertController(title: nil, message: "Please enter your username and password.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func saveToken(result: AnyObject) {
       
        guard let token = result["token"] as? String
        else {
            return;
        }

        let user = User(id: username.text!, username: username.text!)
        user.clearToken()
        user.authToken = token

        LoginService.user = user

        openDestination()
    }
    
    func stopEditing() {
        self.username.resignFirstResponder()
        self.password.resignFirstResponder()
    }

    func openDestination() {
        self.stopEditing()

        //        self.presentViewController(LoginService.destination, animated: true, completion: nil)

        // This could probably be done better - issue with being a framework and not having access to AppDelegate
        // "Application tried to present modally an active controller ios"
        // This also ensures we dont have any memory leaks
        if let window = UIApplication.sharedApplication().keyWindow {
            window.rootViewController = LoginKitConfig.destination()
            window.makeKeyAndVisible()
        }
    }

    func savePasswordTapped() {
        self.savePasswordButton.selected = !self.savePasswordButton.selected
        LoginService.storePassword = self.savePasswordButton.selected
    }
    
    override public func shouldAutorotate() -> Bool {
        return true
    }
    
    override public func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }


}
