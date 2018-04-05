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
        
        //ativar para caregar os cinemas
        //loadXML()
        
        //recuperar o ponto através do endereco
        showAddress("Avenida Paulista, 1106, São Paulo")
        
        requestUserLocationAuthorization()
        
    }
    
    
    // MARK: - Methods
    func showAddress(_ address: String) {
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address) { (placemarks, error) in
            if error == nil {
                guard let placemarks = placemarks else {return}
                guard let placemark = placemarks.first else {return}
                guard let coordinate = placemark.location?.coordinate else {return}
                
                let annotation = MKPointAnnotation()
                annotation.title = placemark.postalCode ?? "---"
                annotation.coordinate = coordinate
                self.mapView.addAnnotation(annotation)
                
                let region = MKCoordinateRegionMakeWithDistance(coordinate, 400, 400)
                self.mapView.setRegion(region, animated: true)
            }
        }
    }
    
    func loadXML() {
        guard let xml = Bundle.main.url(forResource: "theaters", withExtension: "xml"), let xmlParser = XMLParser(contentsOf: xml) else {return}
        
        xmlParser.delegate = self
        xmlParser.parse()
    }
    
    func addTheaters() {
        for theater in theaters {
            let coordinate = CLLocationCoordinate2D(latitude: theater.latitude, longitude: theater.longitude)
            let annotation = TheaterAnnotation(coordinate: coordinate, title: theater.name, subtitle: theater.url)
            
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
    
    
    
    func getRoute(destination: CLLocationCoordinate2D)  {
        let request = MKDirectionsRequest()
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: locationManager.location!.coordinate))
        
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            if error == nil {
                guard let response = response else {return}
                
                let routes = response.routes.sorted(by: {$0.expectedTravelTime < $1.expectedTravelTime})
                guard let route = routes.first else {return}
                print("Nome", route.name)
                print("Distancia", route.distance)
                print("Duração", route.expectedTravelTime)
                print("Tipo de transporte", route.transportType)
                
                for step in route.steps {
                    print("Em \(step.distance) metros, \(step.instructions)")
                }
                
                self.mapView.removeOverlays(self.mapView.overlays)
                self.mapView.add(route.polyline, level: .aboveRoads) //adicionando a rota no mapa
                self.mapView.showAnnotations(self.mapView.annotations, animated: true)
                
                
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

// MARK: - MapView Delegate
extension TheatersMapViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let camera = MKMapCamera()
        camera.pitch = 80
        camera.altitude = 100
        camera.centerCoordinate = view.annotation!.coordinate
        mapView.setCamera(camera, animated: true)
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            
            let renderer = MKPolylineRenderer(overlay: overlay)
            
            renderer.strokeColor = #colorLiteral(red: 0.1977392788, green: 0.7777704613, blue: 0.8251090819, alpha: 1)
            renderer.lineWidth = 7.0                                 
            
            return renderer
            
        } else {
            return MKOverlayRenderer(overlay: overlay)
        }
        
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annotationView: MKAnnotationView!
        
        if annotation is TheaterAnnotation {
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Theater")
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Theater")
                annotationView.image = UIImage(named: "theaterIcon")
                annotationView.canShowCallout = true
                
                let btLeft = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
                btLeft.setImage(UIImage(named: "car"), for: .normal)
                annotationView.leftCalloutAccessoryView = btLeft
                
                let btRight = UIButton(type: .detailDisclosure)
                annotationView.rightCalloutAccessoryView = btRight
                
            } else {
                annotationView.annotation = annotation
            }
            
        } else if annotation is MKPointAnnotation {
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "POI")
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "POI")
                (annotationView as! MKPinAnnotationView).pinTintColor = .blue
                (annotationView as! MKPinAnnotationView).animatesDrop = true
                annotationView.canShowCallout = true
            } else {
                annotationView.annotation = annotation
            }
            
        }
        
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.leftCalloutAccessoryView {
            //tocamos no botão esquerdo
            
            getRoute(destination: view.annotation!.coordinate)
            
            
        } else {
            //tocamos no botão direito
            
            if let vc = storyboard?.instantiateViewController(withIdentifier: "WebViewController") as? WebViewController {
                
                vc.url = view.annotation!.subtitle!
                present(vc, animated: true, completion: nil)
                
            }
            
        }
        
    }
    
}

// MARK: - CLLocationManager Delegate
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

// MARK: - SearchBar Delegate
extension TheatersMapViewController : UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
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
                //print.
            }
        }
    }
}

