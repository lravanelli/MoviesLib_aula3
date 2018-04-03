//
//  TheatersMapViewController.swift
//  MoviesLib
//
//  Created by Usuário Convidado on 02/04/18.
//  Copyright © 2018 EricBrito. All rights reserved.
//

import UIKit
import MapKit //Importar para utiliar mapas.

class TheatersMapViewController: UIViewController {
    //mark = a marcadores e organizadores, com - cria uma separação
    
    // MARK: - IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    
    
    // MARK: - Properties
    var currentElement: String!
    var theater: Theater!
    var theaters: [Theater] = []
    lazy var locationManager = CLLocationManager() //lazy é para definir que seja instanciado apenas quando a variavel for utilizada.
    var poiAnnotation: [MKPointAnnotation] = []
    
    // MARK: - Super Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        loadXML()
        
        requestUserLocationAuthorization()
        
    }
    
    
    // MARK: - Methods
    func loadXML() {
        guard let xml = Bundle.main.url(forResource: "theaters", withExtension: "xml"), let xmlParser = XMLParser(contentsOf: xml) else {return}
        
        xmlParser.delegate = self
        xmlParser.parse()
    }
    
    func addTheaters() {
        for theater in theaters {
            let coordinate = CLLocationCoordinate2D(latitude: theater.latitude, longitude: theater.longitude)
            let annotation = TheaterAnnotation(coordinate: coordinate, title: theater.name, subtitle: theater.address)
            
            mapView.addAnnotation(annotation)
        }
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    func requestUserLocationAuthorization() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            //locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = true
            
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                print("já autorizado")
            case .denied:
                print("Negado") //solicitar a autorização
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .restricted:
                print("restrito")
            }
        }
    }
}

//Implementando o Delegate do XMLParser
// MARK: - XML Delegate
extension TheatersMapViewController : XMLParserDelegate {
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        currentElement = elementName
        
        if elementName == "Theater" {
            theater = Theater()
            
        }
        
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let content = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !content.isEmpty {
            switch currentElement {
            case "name": theater.name = content
            case "latitude": theater.latitude = Double(content)!
            case "address": theater.address = content
            case "longitude": theater.longitude = Double(content)!
            case "url": theater.url = content
            default: break
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Theater" {
            theaters.append(theater)
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        addTheaters()
    }
}

extension TheatersMapViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annotationView: MKAnnotationView!
        
        if annotation is TheaterAnnotation {
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Theater")
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Theater")
                annotationView.image = UIImage(named: "theaterIcon")
                annotationView.canShowCallout = true
            } else {
                annotationView.annotation = annotation
            }
            
        }
        return annotationView
    }
}

extension TheatersMapViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
        default:
            break
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("Velocidade do usuário:  \(userLocation.location?.speed ?? 0)")
        
        //let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 500, 500) //acompanhar a localização do usuário
        //mapView.setRegion(region, animated: true)
    }
}

extension TheatersMapViewController : UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBar.text!
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if error == nil {
                self.mapView.removeAnnotations(self.poiAnnotation)
                self.poiAnnotation.removeAll()
                guard let response = response else {return}
                for item in response.mapItems {
                    let place = MKPointAnnotation()
                    place.coordinate = item.placemark.coordinate
                    place.title = item.name
                    place.subtitle = item.phoneNumber
                    self.poiAnnotation.append(place)
                }
                self.mapView.addAnnotations(self.poiAnnotation)
            }
        }
    }
}

