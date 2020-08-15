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

class NavigateVC: UIViewController
{
    var mapView: MapmyIndiaMapView!
    @IBOutlet weak var myView: UIView!
    var routes = [Route]()
    var selectedRoute:Route?
    var selectRoute:Route?
    @IBOutlet weak var footer: UIView!
    @IBOutlet weak var DDlabel: UILabel!
    @IBOutlet weak var ETALabel: UILabel!

    override func viewDidLoad() -> Void
    {
        super.viewDidLoad()

        DDlabel.layer.cornerRadius = 15;
        ETALabel.layer.cornerRadius = 15;
        DDlabel.layer.masksToBounds = true;
        ETALabel.layer.masksToBounds = true;

        // Nearby Location

        let nearByManager = MapmyIndiaNearByManager(restKey:
            MapmyIndiaAccountManager.restAPIKey(), clientId:
            MapmyIndiaAccountManager.atlasClientId(), clientSecret:
            MapmyIndiaAccountManager.atlasClientSecret(), grantType:
            MapmyIndiaAccountManager.atlasGrantType())

        let nearByOptions = MapmyIndiaNearbyAtlasOptions(query: "Airtel Store", location: CLLocation(latitude: 28.543014, longitude: 77.242342), withRegion: .india)
        nearByManager.getNearBySuggestions(nearByOptions)
        {
            (suggestions,error) in
            if let error = error
            {
                NSLog("%@", error)
            }
            else if let suggestions = suggestions, !suggestions.isEmpty
            {
                print("\n\n\n\n\n");
                print(suggestions[0].placeAddress ?? "No Results");
                print("Near by: \(suggestions[0].latitude ?? 0),\(suggestions[0].longitude ?? 0)")
                print("\n\n\n\n\n");
            }
            else
            {

            }
        }

        mapView = MapmyIndiaMapView(frame: myView.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        myView.addSubview(mapView)

        // Setting Camera

        let point1 = MGLPointAnnotation()
        point1.coordinate = CLLocationCoordinate2D(latitude: 28.5415090000001, longitude:
            77.2478590000001)
        point1.title = "Current Location"
        mapView.addAnnotation(point1)

        let point2 = MGLPointAnnotation()
        point2.coordinate = CLLocationCoordinate2D(latitude: 28.550834, longitude:
            77.268918)
        point2.title = "Airtel Store"
        mapView.addAnnotation(point2)

        let shapeCam = mapView.cameraThatFitsCoordinateBounds(MGLCoordinateBounds(sw: CLLocationCoordinate2DMake(28.5415090000001,77.2478590000001), ne: CLLocationCoordinate2DMake(28.550834, 77.268918)), edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40))

        mapView.setCamera(shapeCam, animated: true);

        // Routing

        mapView.showsUserLocation = true;
        callRouteUsingDirectionsFramework(isETA : true);
    }

    func callRouteUsingDirectionsFramework(isETA: Bool)
    {
        let origin = MapmyIndiaDirections.Waypoint(coordinate: CLLocationCoordinate2D(latitude: 28.550834, longitude: 77.268918), name: "MapmyIndia")
        let destination = MapmyIndiaDirections.Waypoint(coordinate: CLLocationCoordinate2D(latitude: 28.541509, longitude: 77.247859), name: "Airtel Store")
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
            for i in 0...self.routes.count - 1
            {
                let route = self.routes[i]
                if let routeCoordinates = route.coordinates
                {
                    let myPolyline = CustomPolyline(coordinates: routeCoordinates, count: UInt(routeCoordinates.count))
                    myPolyline.routeIndex = i
                    polylines.append(myPolyline)
                    if i == routeIndex {
                        myPolyline.isSelected = true
                        self.selectedRoute = route
                    } else {
                        self.mapView.addAnnotation(myPolyline)
                    }
                    DispatchQueue.main.async
                    {
                        self.DDlabel.text = String(format: "Driving Distance: %d m", (Int(route.distance)));
                        self.ETALabel.text = String(format: "ETA: %d mins",Int(route.expectedTravelTime))
                    }
                }
            }

            self.mapView.addAnnotation(polylines[routeIndex])
            //self.mapView.showAnnotations(polylines, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: false)
            //self.selectRoute(route: self.routes[0])
        }
    }
}

class CustomPolyline: MGLPolyline
{
    var routeIndex:Int = -1
    var isSelected:Bool = true
}
