//
//  MapVC.swift
//  CovermyIndia
//
//  Created by Ishan Sharma on 09/08/20.
//  Copyright © 2020 Ishan Sharma. All rights reserved.
//

/*

    1. Customised Location / Area - DONE
    2. Opacity - Done
    3. Route Demo - DONE

 */

import UIKit
import MapmyIndiaAPIKit
import MapmyIndiaMaps

class CustomPolygon: MGLPolygon
{
    var polygonColor = UIColor.red
    var opacity:CGFloat = 0
}

class MapVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, MapmyIndiaMapViewDelegate
{
    @IBOutlet weak var myView: UIView!
    @IBOutlet weak var searchTextField: UITextField!

    @IBOutlet weak var internetButton: UIButton!
    @IBOutlet weak var internetLabel: UILabel!
    @IBOutlet weak var showCoverage: UIButton!
    @IBOutlet weak var navigateButton: UIButton!
    @IBOutlet weak var picker: UIPickerView!

    var pickerData: [String] = [String]()
    var mapView: MapmyIndiaMapView!
    var mapViewOnly: MGLMapView!
    var overlay: CustomPolygon?
    var point = MGLPointAnnotation();
    var colarr: [UIColor] = []
    var alphaarr: [CGFloat] = []
    var colorindex: Int = 0
    var aplhaindex: Int = 0

    override func viewDidLoad()
    {
        super.viewDidLoad()

        internetButton.layer.cornerRadius = 15;
        internetLabel.layer.cornerRadius = 15;
        showCoverage.layer.cornerRadius = 15;
        navigateButton.layer.cornerRadius = 15;
        internetLabel.layer.masksToBounds = true;

        pickerData = ["Jio", "Airtel", "Vodafone Idea", "BSNL"];
        colarr = [UIColor.cyan, UIColor(red: 0.72, green: 0.00, blue: 0.00, alpha: 1.00), UIColor.red, UIColor.orange, UIColor.yellow, UIColor.gray];
        alphaarr = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.8, 1];

        self.picker.delegate = self
        self.picker.dataSource = self
        searchTextField.delegate = self

        // Load Map ->

        mapView = MapmyIndiaMapView(frame: myView.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        myView.addSubview(mapView)

        mapView.delegate = self

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(tap:)))
        mapView.addGestureRecognizer(longPress)
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1;
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return pickerData.count;
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        return pickerData[row];
    }

    @IBAction func coveragePressed(_ sender: UIButton)
    {
        mapView.showsUserLocation = true;

        var circleCoordinates = MapVC.polygonCircleForCoordinate(coordinate: CLLocationCoordinate2D(latitude: 28.550834, longitude:
            77.268918), withMeterRadius: 100)

        colorindex = 1;
        aplhaindex = 4;
        var overlay = CustomPolygon(coordinates: circleCoordinates, count: UInt(circleCoordinates.count))
        
        mapView.addAnnotation(overlay)

        let shapeCam = mapView.cameraThatFitsShape(overlay, direction: CLLocationDirection(0), edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))

        mapView.setCamera(shapeCam, animated: false)

        circleCoordinates = MapVC.polygonCircleForCoordinate(coordinate: CLLocationCoordinate2D(latitude: 28.550701373033704, longitude:
            77.26615426925696), withMeterRadius: 100)

        colorindex = 3;
        aplhaindex = 4;

        overlay = CustomPolygon(coordinates: circleCoordinates, count: UInt(circleCoordinates.count))

        mapView.addAnnotation(overlay)

        circleCoordinates = MapVC.polygonCircleForCoordinate(coordinate: CLLocationCoordinate2D(latitude: 28.55284207935074, longitude:
            77.26890953818997), withMeterRadius: 100)

        colorindex = 0;
        aplhaindex = 4;

        overlay = CustomPolygon(coordinates: circleCoordinates, count: UInt(circleCoordinates.count))

        mapView.addAnnotation(overlay)
    }

    @IBAction func networkPressed(_ sender: UIButton)
    {

    }

    @IBAction func internetPressed(_ sender: UIButton)
    {

    }

    @IBAction func navigatePressed(_ sender: Any)
    {
        self.performSegue(withIdentifier: "navigateMap", sender: self);
    }

    class func polygonCircleForCoordinate(coordinate: CLLocationCoordinate2D, withMeterRadius: Double) -> [CLLocationCoordinate2D]
    {
        let degreesBetweenPoints = 8.0
        //45 sides
        let numberOfPoints = floor(360.0 / degreesBetweenPoints)
        let distRadians: Double = withMeterRadius / 6371000.0
        // earth radius in meters
        let centerLatRadians: Double = coordinate.latitude * Double.pi / 180
        let centerLonRadians: Double = coordinate.longitude * Double.pi / 180
        var coordinates = [CLLocationCoordinate2D]()
        //array to hold all the points
        for index in 0 ..< Int(numberOfPoints)
        {
            let degrees: Double = Double(index) * Double(degreesBetweenPoints)
            let degreeRadians: Double = degrees * Double.pi / 180
            let pointLatRadians: Double = asin(sin(centerLatRadians) * cos(distRadians) + cos(centerLatRadians) * sin(distRadians) * cos(degreeRadians))
            let pointLonRadians: Double = centerLonRadians + atan2(sin(degreeRadians) * sin(distRadians) * cos(centerLatRadians), cos(distRadians) - sin(centerLatRadians) * sin(pointLatRadians))
            let pointLat: Double = pointLatRadians * 180 / Double.pi
            let pointLon: Double = pointLonRadians * 180 / Double.pi
            let point: CLLocationCoordinate2D = CLLocationCoordinate2DMake(pointLat, pointLon)
            coordinates.append(point)
        }
        return coordinates
    }
    @IBAction func ULPressed(_ sender: UIButton)
    {
        mapView.showsUserLocation = true;

        let circleCoordinates = MapVC.polygonCircleForCoordinate(coordinate: CLLocationCoordinate2D(latitude: 28.550834, longitude:
            77.268918), withMeterRadius: 100)

        let overlay = CustomPolygon(coordinates: circleCoordinates, count: UInt(circleCoordinates.count))

        mapView.addAnnotation(overlay)

        let shapeCam = mapView.cameraThatFitsShape(overlay, direction: CLLocationDirection(0), edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))

        mapView.setCamera(shapeCam, animated: true)
    }

    @objc func didLongPress(tap: UILongPressGestureRecognizer)
    {
        if tap.state == .began
        {
            let touchPoint = tap.location(in: mapView)
            let newCoordinate: CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)

            print("\n\n\n\n\n");
            print(newCoordinate.latitude);
            print(newCoordinate.longitude);
            print("\n\n\n\n\n");

            // remove old marker
            mapView.removeAnnotation(point);

            point.coordinate = newCoordinate
            point.title = "Point"
            mapView.addAnnotation(point)
        }
    }

    func mapView(_ mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor
    {
        return colarr[colorindex];
    }

    func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat
    {
        // Set the alpha for all shape annotations to 1 (full opacity)
        return alphaarr[aplhaindex];
    }
}

extension MapVC: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        searchTextField.endEditing(true)
        return true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool
    {
        return true;
    }

    func textFieldDidEndEditing(_ textField: UITextField)
    {

    }
}
