//
//  LocationDetailsViewController.swift
//  MyLocations
//
//  Created by Yavor Dimov on 2/21/19.
//  Copyright © 2019 Yavor Dimov. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

class LocationDetailsViewController: UITableViewController {
    
    var observer: Any!
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: CLPlacemark?
    var categoryName = "No Category"
    var managedObjectContext: NSManagedObjectContext!
    var date = Date()
    var descriptionText = ""
    var image: UIImage? { //Value itself is set in the extension for UIImagePickerControllerDelegate
        didSet {
            if let anImage = image {
                imageView.image = anImage
                imageView.isHidden = false
                imageHeightConstraint.constant = 260 //Once we have an image resize the cell for better fit
                photoLabel.text = "" //Removing label string here should allow the auto layout constrainst placed on the imageView to fill the whole cell up
                tableView.reloadData() //Needed to resize the cell
            }
        }
    }
    var locationToEdit: Location? {
        didSet {
            if let location = locationToEdit {
                descriptionText = location.locationDescription
                categoryName = location.category
                date = location.date
                placemark = location.placemark
                coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
            }
        }
    }
    
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var photoLabel: UILabel!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let location = locationToEdit {
            title = "Edit Location"
            
            if location.hasPhoto {
                if let theImage = location.photoImage {
                    show(image: theImage)
                }
            }
        }
        
        descriptionTextView.text = descriptionText
        categoryLabel.text = categoryName
        
        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        
        if let placemark = placemark {
            addressLabel.text = string(from: placemark)
        } else {
            addressLabel.text = "No address found"
        }
        
        dateLabel.text = format(date: date)
        
        //Hide keyboard
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
        
        //Hide action sheet if present when app enters background
        listenForBackgroundNotification()
    }
    
    //MARK: - Actions
    @IBAction func done() {
        let hudView = HudView.hud(inView: navigationController!.view, animated: true)
        
        let location: Location
        if let temp = locationToEdit {
            hudView.text = "Updated!"
            location = temp
        } else {
            hudView.text = "Tagged!"
            location = Location(context: managedObjectContext) //If we don't have an item to edit instantiate location
            location.photoID = nil
        }
        //Set location object properties
        location.locationDescription = descriptionTextView.text
        location.category = categoryName
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        location.date = date
        location.placemark = placemark
        
        //Save Image
        if let image = image {
            if !location.hasPhoto { //otherwise we'll just overwrite existing photo
                location.photoID = Location.nextPhotoID() as NSNumber
            }
            if let data = image.jpegData(compressionQuality: 0.5){
                do {
                    try data.write(to: location.photoURL, options: .atomic)
                } catch {
                    print("Error writing to file: \(error)")
                }
            }
        }
        
        do {
            try managedObjectContext.save()
            afterDelay(0.6) {
                hudView.hide()
                self.navigationController?.popViewController(animated: true)
            }
            
        } catch {
            fatalCoreDataError(error)
        }
    }
    
    @IBAction func cancel() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func categoryPickerDidSelectCategory(_ segue: UIStoryboardSegue) {
        let controller = segue.source as! CategoryPickerViewController
        categoryName = controller.selectedCategoryName
        categoryLabel.text = categoryName
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 || indexPath.section == 1 {
            return indexPath
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            descriptionTextView.becomeFirstResponder()
        } else if indexPath.section == 1 && indexPath.row == 0 {
            pickPhoto()
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    //MARK: - Helper Methods
    
    func string(from placemark: CLPlacemark) -> String {
        var text = ""
        
        if let s = placemark.subThoroughfare {
            //subThoroughfare = house number
            text += s + " "
        }
        if let s = placemark.thoroughfare {
            //thoroughfare = street name
            text += s + ", "
        }
        if let s = placemark.locality {
            //locality = city
            text += s + ", "
        }
        if let s = placemark.administrativeArea {
            //adminArea = state/province
            text += s + " "
        }
        if let s = placemark.postalCode {
            text += s + ", "
        }
        if let s = placemark.country {
            text += s
        }
        
        return text
    }
    
    func format(date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    @objc func hideKeyboard(_ gestureRecognizer: UIGestureRecognizer) {
        let point = gestureRecognizer.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 0{
            return //If user is tapping inside the descriptionTextView we don't want to hide the keyboard
        }
        descriptionTextView.resignFirstResponder() //hide keyboard when user taps anwywhere but the descriptionTextView
    }
    
    func show(image: UIImage) {
        imageView.image = image
        imageView.isHidden = false
        imageHeightConstraint.constant = 260
        photoLabel.text = ""
    }
    
    //Used to dismiss the action sheet if it's shown when app is sent to the background
    func listenForBackgroundNotification() {
        observer = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: OperationQueue.main) {
            [weak self] _ in //Must use weak self reference if we want the deinit method to succeed
            if let weakSelf = self { //a weak self object can be nil, thus must be unwrapped
                if weakSelf.presentedViewController != nil {
                    weakSelf.dismiss(animated: false, completion: nil)
                }
                weakSelf.descriptionTextView.resignFirstResponder()
            }
        }
    }
    
    deinit {
        //As of iOS 9 the deinit here is taken care of by the system. It is used here as proof that LocationDetailsViewController object really is destroyed upon closing the screen, the use of the listenForBackgroundNotification() method without the use of "weak self" would have caused the object to be retained due to the strong reference to "self".
        print("*** deinit \(self)")
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickCategory" {
            let controller = segue.destination as! CategoryPickerViewController
            controller.selectedCategoryName = categoryName
        }
    }
    
}

//MARK: - UIImagePickerController Delegate Extension
extension LocationDetailsViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    //MARK: - Image Helper Methods
    func takePhotoWithCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func choosePhotoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func pickPhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showPhotoMenu()
        } else {
            choosePhotoFromLibrary()
        }
    }
    
    func showPhotoMenu() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let actCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let actPhoto = UIAlertAction(title: "Take Photo", style: .default,
                                     handler: { _ in self.takePhotoWithCamera()})
        let actLibrary = UIAlertAction(title: "Choose From Library", style: .default,
                                       handler: { _ in self.choosePhotoFromLibrary()})
        alert.addAction(actCancel)
        alert.addAction(actPhoto)
        alert.addAction(actLibrary)
        
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: Image Picker Delegates
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        
        if let theImage = image {
            show(image: theImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
