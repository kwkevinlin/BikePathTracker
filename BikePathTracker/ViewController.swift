//
//  ViewController.swift
//  BikePathTracker
//
//  Created by 1834 Software on 3/3/16.
//  Copyright © 2016 Kevin Lin. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps
import MobileCoreServices


/*
    To Do:
    Check camera
    Weird thing beside current location

    Do:
    Ask geotag ("tag"?)
    DOCUMENT how program works, all 4 use cases.

    Program Description:
    This program has been tested with the simulator GPS service set to "City Bicycle Ride". When "start" is pressed, the app records and displays, via polylines, the route that has been taken by the biker. When stop is pressed, the route stops recording and continues to display the user's travelled path. The GPS tracker also continues to run so new movements by the user will be reflected on the map, just not recorded.
    Along the path if the user wants to take a picture, the user can press the "Camera" button, and the camera will pop up. If a photo is taken, a marker will be displayed on the mapView math on the coordinate that the photo was taken on. This was implemented since geotagging of photos is enabled by default on iOS systems, unless it was intentionally disabled by the user. With a marker, the user will be able to know exactly where on the map the photo was taken.
    After an image is taken, a popup will appear to confirm that the image was successfully saved in the camera roll. Additionally, an UI View will pop up on the top of the screen for 7 seconds for the user to preview the image previously taken.
    When "start" is pressed again, both the previous route, polylines, and markers will be reset, allowing the user to record another path without having to exit and re-enter the app.

*/

//Check: UINavigationControllerDelegate required?

class ViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var locationManager = CLLocationManager()
    var path = GMSMutablePath() //Array of CLLocationCoordinate2D
    var polyline = GMSPolyline()
    var markerArr = [GMSMarker]()
    
    @IBOutlet weak var previewImg: UIImageView!
    var imagePicker: UIImagePickerController! = UIImagePickerController()
    @IBOutlet weak var previewLabel: UILabel!
    
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    var oldLat = 0.0, oldLong = 0.0, coorLat = 0.0, coorLong = 0.0, boolRecording = 0, camMarkerCount = 0
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation() //Do it once to get user's current location
        
        let camera = GMSCameraPosition.cameraWithLatitude(coorLat, longitude: coorLong, zoom: 16.5)
        mapView.camera = camera
        mapView.myLocationEnabled = true
        
        polyline.strokeColor = UIColor.blueColor()
        polyline.strokeWidth = 5.0
        polyline.map = mapView
        
        imagePicker.delegate = self
        
        //Bringing both to front so they're not hidden by map and buttons
        view.bringSubviewToFront(self.previewImg)
        view.bringSubviewToFront(self.previewLabel)
        
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let latestLocation = locations[locations.count - 1]
        
        coorLat = latestLocation.coordinate.latitude
        coorLong = latestLocation.coordinate.longitude

        
        if (boolRecording == 1) { //First time here, so update some settings
            
            print("Updating")
            
            //If GPS coordinates changed, ie. person is moving
            if (coorLat != oldLat && coorLong != oldLong) {
                oldLat = coorLat
                oldLong = coorLong
            
                //Set camera to current coordinates
                let camera = GMSCameraPosition.cameraWithLatitude(latestLocation.coordinate.latitude, longitude: latestLocation.coordinate.longitude, zoom: 16.5)
                mapView.camera = camera
            
                path.addCoordinate(latestLocation.coordinate) //Add coordinates to array, then:
                polyline.path = path //Update polyline to display updated path list
            
            }
        }
        //Else, just update location
        else {
            let camera = GMSCameraPosition.cameraWithLatitude(latestLocation.coordinate.latitude, longitude: latestLocation.coordinate.longitude, zoom: 16.5)
            mapView.camera = camera
        }
        
        /*
            For this section:
            Google Maps SDK documentation 
            https://www.pubnub.com/blog/2015-05-07-streaming-displaying-ios-location-data-w-swift-programming-language-google-maps-api/
        */
        
    }
    
    @IBAction func funcStartButton(sender: AnyObject) {
        print("Start Pressed!")
        path.removeAllCoordinates() //Clears all coordinates so start anew
        boolRecording = 1 //Read "Else" statement in locationManager
        stopButton.enabled = true
        startButton.enabled = false
        shareButton.enabled = false
        cameraButton.enabled = true
        
        for (var i = 0; i < camMarkerCount; i++) {
            markerArr[i].map = nil //Clears markers
        }
        
        camMarkerCount = 0 //How many camera markers are there (pictures taken)
        markerArr.removeAll() //Removes all markers on array to start anew
        
        locationManager.startUpdatingLocation()
        
    }
    
    
    @IBAction func funcStopButton(sender: AnyObject) {
        print("Stop Pressed!")
        boolRecording = 0
        startButton.enabled = true
        stopButton.enabled = false
        shareButton.enabled = true
        cameraButton.enabled = false
        
    }
 
    @IBAction func funcCameraButton(sender: AnyObject) {
        print("Camera Pressed!")
        
        //Images are geotagged automatically in iOS unless setting turned off, so to show that an image has been taken while riding, I'll generate and put a marker (annotation) on the map so looking back we can see that we've stopped to take a photo at this coordinate
        
        //Adds a marker to the map if you took a photo there
        let position = CLLocationCoordinate2DMake(coorLat, coorLong)

        //Store markers in array so we can delete later
        markerArr.append(GMSMarker(position: position))
        markerArr[camMarkerCount].title = "Photo Taken"
        markerArr[camMarkerCount].map = mapView
        camMarkerCount++
        
        print("Camera marker added")
  
        //Camera tutorial from: http://hubpages.com/technology/Access-Photo-Camera-and-Library-in-Swift (with some modifications)
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera;
            imagePicker.allowsEditing = false
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        
        
    }
    
    //After taking image, calls "savePhoto()" func to save photo to camera roll
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        previewImg.hidden = false
        previewLabel.hidden = false
        previewImg.image = image
        savePhoto()
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    //Saves photo to camera roll
    func savePhoto() {
        let imageData = UIImageJPEGRepresentation(previewImg.image!, 0.6)
        let compressedJPGImage = UIImage(data: imageData!)
        UIImageWriteToSavedPhotosAlbum(compressedJPGImage!, nil, nil, nil)
        
        let alert = UIAlertView(title: "Saved!",
            message: "Your image has been saved to Photo Library!",
            delegate: nil,
            cancelButtonTitle: "Ok")
        alert.show()
        
        delay(7) {
            self.previewImg.hidden = true
            self.previewLabel.hidden = true
        }
    }
    
    
    @IBAction func funcShareButton(sender: AnyObject) {
        print("Share Pressed!")
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

