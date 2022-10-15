//
//  ViewController.swift
//  MapApp (coredata)
//
//  Created by Ferhat Adiyeke on 26.09.2022.
//
import UIKit
import MapKit
import CoreLocation
import CoreData

class MapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var isimTextField: UITextField!
    @IBOutlet weak var notTextField: UITextField!
    //konum ve harita
    
    @IBOutlet var MapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var requestCLLocation = CLLocation()

    var secilenLatitude = Double()
    var secilenLongitude = Double()
    
    
    
 
    
    var annotationTitle = ""
    var annotationSubTitle = ""
    var annotationLatitude : Double = 0
    var annotationLongitude : Double = 0

    var secilenIsim = ""
     var secilenId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //delegasyonları yaptık
        
        
        MapView.delegate = self
        locationManager.delegate = self

        // ne kadar kesin konum istiyorsun
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //kullanıcıdan izin istemek
        locationManager.requestWhenInUseAuthorization()
        //konumu güncellemeye başla
        locationManager.startUpdatingLocation()

        
        // dokunulan konumu seçmek için
        
        
        
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(konumSec(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        MapView.addGestureRecognizer(gestureRecognizer)
        
        
        if annotationTitle != "" {
            // CORE DATA DAN VERİLERİ ÇEK
            
            if let uuidString = secilenId?.uuidString {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                
                
                do {
                    let sonuclar =  try context.fetch(fetchRequest)
                    
                    
                    if sonuclar.count > 0 {
                        for sonuc in  sonuclar as! [NSManagedObject] {
                            if let  isim = sonuc.value(forKey: "isim") as? String {
                                annotationTitle = isim
                                if let  not = sonuc.value(forKey: "not") as? String {
                                    annotationSubTitle = not
                                    
                                      if let  latitude = sonuc.value(forKey: "latitude") as? Double {
                                          annotationLatitude = latitude
                                          
                                          if let  longitude = sonuc.value(forKey: "longitude") as? Double {
                                              annotationLongitude = longitude
                                              
                                              
                                              
                                              let annotation = MKPointAnnotation()
                                              
                                              
                                              annotation.title = annotationTitle
                                              annotation.subtitle = annotationSubTitle
                                              let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                              annotation.coordinate = coordinate
                                              
                                              MapView.addAnnotation(annotation)
                                              isimTextField.text = annotationTitle
                                              notTextField.text = annotationSubTitle
                                              
                                              locationManager.startUpdatingLocation()
                                              
                                              let span = MKCoordinateSpan(latitudeDelta: 0.9, longitudeDelta: 0.9)
                                              let region = MKCoordinateRegion(center: coordinate, span: span)
                                              MapView.setRegion(region, animated: true)
                                              
                                          }
                                      }
                                }
                            }
                          
                        }
                    }
                 } catch {
                    print("hata")
                }
            }
        } else {
            // yeni veri eklemeye geldi
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "benimAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .red
            
            let button =  UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else  {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if secilenIsim != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarkDizisi, hata) in
                
                if let placemarks = placemarkDizisi {
                    if placemarks.count > 0 {
                        let yeniPlaceMark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: yeniPlaceMark)
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
                
            }
            
        }
    }
    
    
    @objc func  konumSec(gestureRecognizer:
                         UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .began {
            let dokunulaNokta = gestureRecognizer.location(in: MapView)
            let dokunulanKoordinat = MapView.convert(dokunulaNokta, toCoordinateFrom: MapView)
            
            secilenLatitude = dokunulanKoordinat.latitude
            secilenLongitude = dokunulanKoordinat.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = dokunulanKoordinat
            annotation.title = isimTextField.text
            annotation.subtitle = notTextField.text
            MapView.addAnnotation(annotation)
        }
    }
    
    
    //konumları güncellemek için fonksiyon güncelllendikçe konumu veriyor ve bizi o konumla işlem yapabilirz
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
      //  koordinat verir
        //print(locations[0].coordinate.latitude)
      //  print(locations[0].coordinate.longitude)
        // konum oluşturma
        if secilenIsim == "" {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        
        //harıtada konumu değiştirmek içn
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1) //konumun yükseklik seviyesi
        let region = MKCoordinateRegion(center: location, span: span)
        MapView.setRegion(region, animated: true)
        
        }
            
    }


    @IBAction func kaydetTiklandi(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let yeniYer = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: context)
        
        
        yeniYer.setValue(isimTextField.text, forKey: "isim")
        yeniYer.setValue(notTextField.text, forKey: "not")
        yeniYer.setValue(secilenLatitude, forKey: "latitude")
        yeniYer.setValue(secilenLongitude, forKey: "longitude")
        yeniYer.setValue(UUID(), forKey: "id")
        
        
        do {
            try context.save()
            print("Kayıt Edildi")
        }catch {
            print("hata")
        }
            
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "yeniYerOlusturuldu"), object: nil)
        navigationController?.popViewController(animated: true)
        



        
        
    }
}


