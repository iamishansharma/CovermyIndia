//
//  NavigationVC.swift
//  CovermyIndia
//
//  Created by Ishan Sharma on 11/08/20.
//  Copyright © 2020 Ishan Sharma. All rights reserved.
//

import UIKit
import MapmyIndiaAPIKit
import MapmyIndiaMaps
import MapmyIndiaDirections

class NavigateVC: UIViewController, MapmyIndiaMapViewDelegate
{
    var mapView: MapmyIndiaMapView!
    @IBOutlet weak var myView: UIView!
    var routes = [Route]()
    var selectedRoute : Route?
    var selectRoute : Route?
    @IBOutlet weak var footer: UIView!
    @IBOutlet weak var DDlabel: UILabel!
    @IBOutlet weak var ETALabel: UILabel!
    var nearbyStore: CLLocationCoordinate2D = CLLocationCoordinate2DMake(28.550834, 77.268918)
    var store : Int = 0
    var userLocation : CLLocationCoordinate2D = CLLocationCoordinate2DMake(28.550834, 77.268918)

    override func viewDidLoad() -> Void
    {
        super.viewDidLoad()

        DDlabel.layer.cornerRadius = 15;
        ETALabel.layer.cornerRadius = 15;
        DDlabel.layer.masksToBounds = true;
        ETALabel.layer.masksToBounds = true;

        self.store = MapVC().bestCarrierIndex;

        self.getNearby()

        mapView = MapmyIndiaMapView(frame: myView.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        myView.addSubview(mapView)

        mapView.delegate = self;
    }

    func getNearby()
    {
        let nearByManager = MapmyIndiaNearByManager(restKey:
            MapmyIndiaAccountManager.restAPIKey(), clientId:
            MapmyIndiaAccountManager.atlasClientId(), clientSecret:
            MapmyIndiaAccountManager.atlasClientSecret(), grantType:
            MapmyIndiaAccountManager.atlasGrantType())

        var whichStore : String = "null";

        switch store
        {
            case 0: whichStore = "Jio";
                    break;

            case 1: whichStore = "Airtel";
                    break;

            case 2: whichStore = "Vodafone";
                    break;

            case 3: whichStore = "BSNL";
                    break;

            default:
                    return;
        }

        let nearByOptions = MapmyIndiaNearbyAtlasOptions(query: whichStore, location: CLLocation(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude), withRegion: .india)
        nearByManager.getNearBySuggestions(nearByOptions)
        {
            (suggestions,error) in
            if let error = error
            {
                NSLog("%@", error)
            }
            else if let suggestions = suggestions, !suggestions.isEmpty
            {
                self.nearbyStore.latitude = suggestions[0].latitude as! CLLocationDegrees;
                self.nearbyStore.longitude = suggestions[0].longitude as! CLLocationDegrees;

                // Setting Camera

                let point1 = MGLPointAnnotation()
                point1.coordinate = CLLocationCoordinate2D(latitude: self.nearbyStore.latitude, longitude: self.nearbyStore.longitude)

                let cartext : [String] = ["Jio Store", "Airtel Store", "Vodafone Store", "BSNL Store"];
                
                point1.title = cartext[self.store];
                self.mapView.addAnnotation(point1)

                let point2 = MGLPointAnnotation()
                point2.coordinate = self.userLocation;
                point2.title = "Current Location"
                self.mapView.addAnnotation(point2)

                let shapeCam = self.mapView.cameraThatFitsCoordinateBounds(MGLCoordinateBounds(sw: CLLocationCoordinate2DMake(self.nearbyStore.latitude,self.nearbyStore.longitude), ne: self.userLocation), edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40))

                self.mapView.setCamera(shapeCam, animated: true);

                // Routing

                self.callRouteUsingDirectionsFramework(isETA : true);

            }
            else
            {
                
            }
        }
    }

    func callRouteUsingDirectionsFramework(isETA: Bool)
    {
        mapView.userTrackingMode = .followWithCourse
        self.mapView.showsUserLocation = true;

        let origin = MapmyIndiaDirections.Waypoint(coordinate: self.userLocation, name: "Current Location")
        let destination = MapmyIndiaDirections.Waypoint(coordinate: CLLocationCoordinate2D(latitude: nearbyStore.latitude, longitude: nearbyStore.longitude), name: "Nearby Store")
        origin.allowsArrivingOnOppositeSide = false
        destination.allowsArrivingOnOppositeSide = false

        let options = MapmyIndiaDirections.RouteOptions(waypoints: [origin, destination])
        options.routeShapeResolution = .full
        options.includesAlternativeRoutes = true

        if isETA
        {
            options.resourceIdentifier = .routeETA
        }

        Directions(restKey: MapmyIndiaAccountManager.restAPIKey()).calculate(options)
        {
            (waypoints, routes, error) in
            if let _ = error
            {
                return
            }

            guard let allRoutes = routes, allRoutes.count > 0
                else
            {
                return
            }

            self.routes = allRoutes
            DispatchQueue.main.async
            {
                self.plotRouteOnMap(routeIndex: 0)
            }
        }
    }

    func plotRouteOnMap(routeIndex: Int)
    {
        var polylines = [CustomPolyline]()
        if self.routes.count > 0
        {
            for i in 0...0
            {
                let route = self.routes[i]
                if let routeCoordinates = route.coordinates
                {
                    let myPolyline = CustomPolyline(coordinates: routeCoordinates, count: UInt(routeCoordinates.count))
                    myPolyline.routeIndex = i
                    polylines.append(myPolyline)
                    if i == routeIndex
                    {
                        myPolyline.isSelected = true
                        self.selectedRoute = route
                    } else {
                        self.mapView.addAnnotation(myPolyline)
                    }
                    DispatchQueue.main.async
                    {
                        let dist = Int(route.distance);
                        let time = Int(route.expectedTravelTime)

                        let kms = dist/1000;
                        let met = dist%1000;

                        let min = time/60;
                        let sec = time%60;

                        self.DDlabel.text = String(format: "Driving Distance: \(kms) km \(met) m");
                        self.ETALabel.text = String(format: "ETA: \(min) mins \(sec) secs")
                    }
                }
            }

            self.mapView.addAnnotation(polylines[routeIndex])
        }
    }

    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor
    {
        return UIColor.red;
    }

    func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat
    {
        return 2.5
    }

    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool
    {
        return true
    }
}

class CustomPolyline: MGLPolyline
{
    var routeIndex:Int = -1
    var isSelected:Bool = true
}
