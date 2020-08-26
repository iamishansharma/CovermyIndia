//
//  MapVC.swift
//  CovermyIndia
//
//  Created by Ishan Sharma on 09/08/20.
//  Copyright © 2020 Ishan Sharma. All rights reserved.
//

import UIKit
import MapmyIndiaAPIKit
import MapmyIndiaMaps
import CoreTelephony
import Firebase

class CustomPolygon: MGLPolygon
{
    var polygonColor = UIColor.red
    var opacity: CGFloat = 0
}

class MapVC: UIViewController, MapmyIndiaMapViewDelegate
{
    private var db = Firestore.firestore()

    @IBOutlet weak var myView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var internetButton: UIButton!
    @IBOutlet weak var internetLabel: UILabel!
    @IBOutlet weak var showCoverage: UIButton!
    @IBOutlet weak var navigateButton: UIButton!
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var sendDataLabel: UIButton!
    @IBOutlet weak var table: UITableView!

    var pickerData: [String] = [String]()
    var mapView: MapmyIndiaMapView!
    var mapViewOnly: MGLMapView!
    var overlay: CustomPolygon?
    var point = MGLPointAnnotation();
    var colarr: [UIColor] = []
    var alphaarr: [CGFloat] = []
    var colorindex: Int = 0
    var aplhaindex: Int = 0
    var bestCarrierIndex = 0; // 0 - Jio 1 - Airtel 2 - Vodafone Idea 3 - BSNL
    var suggestiondata = [MapmyIndiaAtlasSuggestion]()
    var userLocation : CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 28.550834, longitude: 77.268918)
    var timeLeft = 6;
    var timer = Timer();

    // Speed Test Variables

    typealias speedTestCompletionHandler = (_ megabytesPerSecond: Double? , _ error: Error?) -> Void
    var speedTestCompletionBlock : speedTestCompletionHandler?
    var startTime: CFAbsoluteTime!
    var stopTime: CFAbsoluteTime!
    var bytesReceived: Int!

    // Cellular network variables

    var carrierName: String = "";
    var internetSpeed: Double? = 0;
    var timeDate = Date();
    
    // Final User Data

    var realData : [RealData] = [RealData]()
    var allPolygons : [CustomPolygon] = [CustomPolygon]()

    override func viewDidLoad()
    {
        super.viewDidLoad()
        table.isHidden = true;

        /*let userdata = readDataFromCSV(fileName: "UserData", fileType: "csv")
        var uD = csv(data: userdata!)
        uD.remove(at: uD.count-1);

        convertStringtoRealData(uD);*/

        internetButton.layer.cornerRadius = 15;
        internetLabel.layer.cornerRadius = 15;
        showCoverage.layer.cornerRadius = 15;
        navigateButton.layer.cornerRadius = 15;
        internetLabel.layer.masksToBounds = true;
        searchTextField.layer.cornerRadius = 15;
        searchTextField.textColor = UIColor.white;
        searchTextField.attributedPlaceholder = NSAttributedString(string: "Enter area or city. Eg. Kandivali East, Mumbai", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])

        pickerData = ["Jio", "Airtel", "Vodafone Idea", "BSNL"];
        colarr = [UIColor.cyan, UIColor.red, UIColor.orange, UIColor.green, UIColor.yellow, UIColor.gray];
        alphaarr = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.8, 1];

        point.coordinate.latitude = 0;
        point.coordinate.longitude = 0;

        self.picker.delegate = self
        self.picker.dataSource = self
        self.searchTextField.delegate = self
        self.table.delegate = self;
        self.table.dataSource = self;

        searchTextField.addTarget(self, action: #selector(MapVC.textFieldDidChange(_:)), for: .editingChanged)

        mapView = MapmyIndiaMapView(frame: myView.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        myView.addSubview(mapView)

        mapView.delegate = self

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(tap:)))
        mapView.addGestureRecognizer(longPress)
    }

    // MARK:- Buttons Pressed

    @IBAction func coveragePressed(_ sender: UIButton)
    {
        getDataFromFirestore()
    }

    @IBAction func internetPressed(_ sender: UIButton)
    {
        if(point.coordinate.latitude == 0 && point.coordinate.longitude == 0)
        {
            bestCarrierIndex = getBest(userLocation);
        }
        else
        {
            bestCarrierIndex = getBest(point.coordinate)
        }

        if(bestCarrierIndex == -1)
        {
            self.showAlert(title: "No Carrier Found!", message: "No Carrier is available in your location.",
                handlerOK:
                {
                    action in
            },
                handlerCancle:
                {
                    actionCanel in
            })

        }
        else if(bestCarrierIndex == -2)
        {

        }
        else
        {
            let carcol : [UIColor] = [UIColor.blue, UIColor.red, UIColor.red, UIColor.gray];
            let cartext : [String] = ["Jio", "Airtel", "Vodafone", "BSNL"];

            self.internetLabel.text = cartext[bestCarrierIndex];
            self.internetLabel.backgroundColor = carcol[bestCarrierIndex];
        }
    }

    @IBAction func navigatePressed(_ sender: Any)
    {
        let nvc = NavigateVC();
        nvc.userLocation = self.userLocation;
        self.performSegue(withIdentifier: "navigateMap", sender: self);
    }

    @IBAction func ULPressed(_ sender: UIButton)
    {
        mapView.showsUserLocation = true;
        mapView.userTrackingMode = .follow

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25)
        {
            self.goToLocation(cc: self.userLocation);
        }
    }

    @objc func didLongPress(tap: UILongPressGestureRecognizer)
    {
        if tap.state == .began
        {
            let touchPoint = tap.location(in: mapView)
            let newCoordinate: CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)

            // remove old marker
            mapView.removeAnnotation(point);

            point.coordinate = newCoordinate
            point.title = "Custom Location"
            mapView.addAnnotation(point)

            let reverseGeocodeManager = MapmyIndiaReverseGeocodeManager.shared

            let revOptions = MapmyIndiaReverseGeocodeOptions(coordinate:
                point.coordinate, withRegion: .india)
            reverseGeocodeManager.reverseGeocode(revOptions)
            {
                (placemarks,attribution, error) in
                if let error = error
                {
                    NSLog("%@", error)
                }
                else if let placemarks = placemarks, !placemarks.isEmpty
                {
                    self.point.title = placemarks[0].formattedAddress
                }
            }
        }
    }

    @IBAction func deleteMarker(_ sender: UIButton)
    {
        mapView.removeAnnotation(point);

        point.coordinate.latitude = 0;
        point.coordinate.longitude = 0;
    }

    @IBAction func searchButtonPressed(_ sender: Any)
    {
        self.performSegue(withIdentifier: "searchSegway", sender: self)
    }

    @IBAction func sendDataPressed(_ sender: UIButton)
    {
        self.checkForSpeedTest();

        DispatchQueue.main.async
        {
            self.timeLeft = 6;

            self.timer.invalidate();
            self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateTimer), userInfo: nil, repeats: true)
        }
    }

    @objc func updateTimer()
    {
        if timeLeft > 0
        {
            self.sendDataLabel.titleLabel?.text = "\(timeLeft)";
            timeLeft -= 1;
        }
        else if timeLeft == 0
        {
            self.sendDataLabel.titleLabel?.text = "Send Data";

            self.showAlert(title: "Data sent", message: "Your data was sent to our servers safely.", endmessage: "OK",
                handlerOK:
                {
                    action in
            },
                handlerCancle:
                {
                    actionCanel in
            })

            self.timer.invalidate();
        }
    }
}


// MARK: - UIPicker Functions

extension MapVC: UIPickerViewDelegate, UIPickerViewDataSource
{
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
}

// MARK:- TextFieldDelegate functions

extension MapVC: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        searchTextField.endEditing(true)
        table.isHidden = true;

        let autoSuggestManager = MapmyIndiaAutoSuggestManager.shared

        let autoSuggestOptions = MapmyIndiaAutoSearchAtlasOptions(query: textField.text ?? "New Delhi", withRegion: .india)

        autoSuggestOptions.zoom = 5
        autoSuggestManager.getAutoSuggestions(autoSuggestOptions)
        {
            (suggestions,error) in
            if error != nil
            {
                self.showAlert(title: "Location not found!", message: "'\(textField.text ?? "nil")' not found.",
                    handlerOK:
                    {
                        action in
                },
                    handlerCancle:
                    {
                        actionCanel in
                })
            }
            else if let suggestions = suggestions, !suggestions.isEmpty
            {
                let newCoordinate = CLLocationCoordinate2DMake(suggestions[0].latitude as! CLLocationDegrees, suggestions[0].longitude as! CLLocationDegrees)

                self.point.coordinate = newCoordinate
                self.point.title = self.searchTextField.text;
                self.mapView.addAnnotation(self.point)

                self.goToLocation(cc: CLLocationCoordinate2DMake(suggestions[0].latitude as! CLLocationDegrees, suggestions[0].longitude as! CLLocationDegrees));
            }
            else
            {
                self.showAlert(title: "Location not found!", message: "'\(textField.text ?? "nil")' not found.",
                    handlerOK:
                    {
                        action in
                },
                    handlerCancle:
                    {
                        actionCanel in
                })
            }
        }
        return true
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool
    {
        return true;
    }

    func showAlert(title: String, message: String, handlerOK:((UIAlertAction) -> Void)?, handlerCancle: ((UIAlertAction) -> Void)?)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Try Again", style: .destructive, handler: handlerOK)
        alert.addAction(action)
        DispatchQueue.main.async
            {
                self.present(alert, animated: true, completion: nil)
        }
    }

    func showAlert(title: String, message: String, endmessage: String, handlerOK:((UIAlertAction) -> Void)?, handlerCancle: ((UIAlertAction) -> Void)?)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: endmessage, style: .destructive, handler: handlerOK)
        alert.addAction(action)
        DispatchQueue.main.async
            {
                self.present(alert, animated: true, completion: nil)
        }
    }

    @objc func textFieldDidChange(_ searchText: UITextField)
    {
        let autoSuggestManager = MapmyIndiaAutoSuggestManager.shared

        let autoSuggestOptions = MapmyIndiaAutoSearchAtlasOptions(query: searchText.text ?? "nil", withRegion: .india)

        autoSuggestOptions.zoom = 5
        autoSuggestManager.getAutoSuggestions(autoSuggestOptions)
        {
            (suggestions,error) in
            if error != nil
            {

            }
            else if let suggestions = suggestions, !suggestions.isEmpty
            {
                let n = suggestions.count;

                self.suggestiondata.removeAll();

                for i in 0...n-1
                {
                    self.suggestiondata.append(suggestions[i]);
                }

                self.table.reloadData();
            }
            else
            {

            }
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField)
    {
        self.table.isHidden = false;
    }
}


// MARK:- Main Functions to go to location and calculate the bubble

extension MapVC
{
    func goToLocation(cc coordinates:CLLocationCoordinate2D)
    {
        mapView.setCenter(coordinates, zoomLevel: 15, animated: true)
    }

    func optionCoverage(op option: Int)
    {
        /*
         Option 1: No Marker, User Location
         Option 2: Marker
         */

        switch option
        {
            case 1:
                mapView.showsUserLocation = true;
                goToLocation(cc: self.userLocation);
                getCoverage(self.userLocation);


                break;

            case 2:
                let userLocation1 = CLLocationCoordinate2D(latitude: point.coordinate.latitude, longitude: point.coordinate.longitude);
                goToLocation(cc: userLocation1);
                getCoverage(userLocation1);

                break;

            default:
                break;
        }
    }

    func getCoverage(_ coordinates:CLLocationCoordinate2D)
    {
        //self.checkForSpeedTest();

        //let delay = 5.1;
        // Literally do nothing to gather data
        /*DispatchQueue.main.asyncAfter(deadline: .now() + delay)
         {

         }*/

        let selRow = picker.selectedRow(inComponent: 0);
        self.plotData(car: selRow, co: coordinates);
    }
}

// MARK: - Extra Functions

extension MapVC
{
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool
    {
        // Always allow callouts to popup when annotations are tapped.
        return true
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

    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }

    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?)
    {
        self.userLocation.latitude = userLocation?.coordinate.latitude as! CLLocationDegrees
        self.userLocation.longitude = userLocation?.coordinate.longitude as! CLLocationDegrees
    }
}

// MARK: - Speed Test Delegates

extension MapVC: URLSessionDelegate, URLSessionDataDelegate
{
    func checkForSpeedTest()
    {
        testDownloadSpeedWithTimout(timeout: 5.0)
        {
            (speed, error) in
            self.internetSpeed = speed;

            let networkInfo = CTTelephonyNetworkInfo()
            let carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value
            self.carrierName = carrier?.carrierName ?? "NONE"

            self.putDataToFirestore(spd: self.internetSpeed ?? 0.0, name: self.carrierName, co: self.userLocation)
        }
    }

    func testDownloadSpeedWithTimout(timeout: TimeInterval, withCompletionBlock: @escaping speedTestCompletionHandler)
    {

        guard let url = URL(string: "https://images.apple.com/v/imac-with-retina/a/images/overview/5k_image.jpg") else { return }

        startTime = CFAbsoluteTimeGetCurrent()
        stopTime = startTime
        bytesReceived = 0

        speedTestCompletionBlock = withCompletionBlock

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession.init(configuration: configuration, delegate: self, delegateQueue: nil)
        session.dataTask(with: url).resume()

    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    {
        bytesReceived! += data.count
        stopTime = CFAbsoluteTimeGetCurrent()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {

        let elapsed = stopTime - startTime

        if let aTempError = error as NSError?, aTempError.domain != NSURLErrorDomain && aTempError.code != NSURLErrorTimedOut && elapsed == 0
        {
            speedTestCompletionBlock?(nil, error)
            return
        }

        let speed = elapsed != 0 ? (Double(bytesReceived)*Double(8) / elapsed / 1024.0 / 1024.0) : -1
        speedTestCompletionBlock?(speed, nil)
    }
}

// MARK:- Functions to process real data

extension MapVC
{
    /*func readDataFromCSV(fileName:String, fileType: String)-> String!
    {
        guard let filepath = Bundle.main.path(forResource: fileName, ofType: fileType)
            else
        {
            return nil
        }
        do
        {
            var contents = try String(contentsOfFile: filepath, encoding: .utf8)
            contents = cleanRows(file: contents)
            return contents
        }
        catch
        {
            print("File Read Error for file \(filepath)")
            return nil
        }
    }


    func cleanRows(file:String)->String
    {
        var cleanFile = file
        cleanFile = cleanFile.replacingOccurrences(of: "\r", with: "\n")
        cleanFile = cleanFile.replacingOccurrences(of: "\n\n", with: "\n")
        return cleanFile
    }

    func csv(data: String) -> [[String]]
    {
        var result: [[String]] = []
        let rows = data.components(separatedBy: "\n")
        for row in rows
        {
            let columns = row.components(separatedBy: ",")
            result.append(columns)
        }
        return result
    }

    func convertStringtoRealData(_ data : [[String]])
    {
        let n : Int = data.count-1;

        for i in 0...n
        {
            let c1 = Int(data[i][0]) ?? 0;
            let c2 = CLLocationCoordinate2DMake(CLLocationDegrees(Float(data[i][1]) ?? 0.0), CLLocationDegrees(Float(data[i][2]) ?? 0.0))
            let c3 = Int(data[i][3]) ?? 0;
            let c4 = data[i][4];
            let c5 = Int(data[i][5]) ?? 0;
            let c6 = Int(data[i][6]) ?? 0;

            let temp : RealData = RealData(carrier: c1, coordinates: c2, spectrum: c3, date: c4, alpha: c5, color: c6)

            realData.append(temp);
        }

        //InitialDataUpload()
    }*/

    func plotData(car carrier: Int, co coordinates : CLLocationCoordinate2D)
    {
        let n : Int = realData.count-1;

        removePreviousPolygons()

        for i in 0...n
        {
            if(realData[i].carrier == carrier)
            {
                let leftlat = coordinates.latitude - 0.1;
                let rightlat = coordinates.latitude + 0.1;
                let uplong = coordinates.longitude + 0.1;
                let downlong = coordinates.longitude - 0.1;

                if(shouldPlot(realData[i].coordinates, leftlat, rightlat, uplong, downlong))
                {
                    let circleCoordinates = MapVC.polygonCircleForCoordinate(coordinate: realData[i].coordinates, withMeterRadius: 30);

                    colorindex = realData[i].color;
                    aplhaindex = realData[i].alpha;

                    let overlay = CustomPolygon(coordinates: circleCoordinates, count: UInt(circleCoordinates.count))

                    self.allPolygons.append(overlay);

                     mapView.addAnnotation(overlay)
                }
            }
        }

        if(allPolygons.count == 0)
        {
            self.showAlert(title: "Data not found!", message: "Not enough data available for your location.",
                handlerOK:
                {
                    action in
            },
                handlerCancle:
                {
                    actionCanel in
            })
        }
    }

    func shouldPlot(_ coordinates : CLLocationCoordinate2D, _ leftlat : CLLocationDegrees, _ rightlat : CLLocationDegrees, _ uplong : CLLocationDegrees, _ downlong : CLLocationDegrees) -> Bool
    {
        if(coordinates.latitude <= rightlat && coordinates.latitude >= leftlat && coordinates.longitude <= uplong && coordinates.longitude >= downlong)
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    func removePreviousPolygons()
    {
        let n = self.allPolygons.count-1;

        if(n == -1)
        {
            return;
        }
        else
        {
            for i in 0...n
            {
                self.mapView.removeAnnotation(allPolygons[i]);
            }

            self.allPolygons.removeAll();
        }
    }

    func getBest(_ coordinates : CLLocationCoordinate2D) -> Int
    {

        if(realData.count == 0)
        {
            self.showAlert(title: "Data not recieved!", message: "Please choose Show Coverage first to get data from servers.",
                handlerOK:
                {
                    action in
            },
                handlerCancle:
                {
                    actionCanel in
            })

            return -2;
        }

        let n : Int = realData.count-1;

        var countArray : [Int] = [0,0,0,0] // Jio, Airtel, Vodafone, BSNL

        for i in 0...n
        {
            let leftlat = coordinates.latitude - 0.1;
            let rightlat = coordinates.latitude + 0.1;
            let uplong = coordinates.longitude + 0.1;
            let downlong = coordinates.longitude - 0.1;

            if(shouldPlot(realData[i].coordinates, leftlat, rightlat, uplong, downlong))
            {
                countArray[realData[i].carrier] += realData[i].spectrum;
            }
        }

        let maxVal = countArray.max();

        if(maxVal == 0)
        {
            return -1;
        }
        else
        {
            let maxIndex = countArray.firstIndex(of: maxVal!) ?? -1
            return maxIndex;
        }
    }
}

// MARK:- Table View Functions

extension MapVC: UITableViewDataSource, UITableViewDelegate
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return suggestiondata.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = suggestiondata[indexPath.row].placeName
        cell.detailTextLabel?.text = suggestiondata[indexPath.row].placeAddress
        cell.textLabel?.textColor = UIColor.white
        cell.detailTextLabel?.textColor = UIColor.white
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let newCoordinate = CLLocationCoordinate2DMake(suggestiondata[indexPath.row].latitude as! CLLocationDegrees, suggestiondata[indexPath.row].longitude as! CLLocationDegrees)

        self.point.coordinate = newCoordinate
        self.point.title = self.searchTextField.text;
        self.mapView.addAnnotation(self.point)

        self.goToLocation(cc: CLLocationCoordinate2DMake(suggestiondata[indexPath.row].latitude as! CLLocationDegrees, suggestiondata[indexPath.row].longitude as! CLLocationDegrees));

        searchTextField.text = suggestiondata[indexPath.row].placeName;

        self.table.isHidden = true;
        searchTextField.endEditing(true)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        self.dismiss(animated: true, completion: nil);
    }
}

// MARK:- Firebase Functions

extension MapVC
{
    /*func InitialDataUpload()
     {
     let n = realData.count-1;

     for i in 0...n
     {
     db.collection("UserData").document("data\(i+1)").setData(["Carrier":realData[i].carrier, "Latitude":realData[i].coordinates.latitude, "Longitude":realData[i].coordinates.longitude, "Spectrum":realData[i].spectrum, "Date":realData[i].date, "Alpha":realData[i].alpha, "Color":realData[i].color])
     }
     }*/

    func getDataFromFirestore()
    {
        realData.removeAll();

         db.collection("UserData").getDocuments
         {
             (snapshot, error) in
             if let error = error
             {
                print(error.localizedDescription)
             }
             else
             {
                 if let snapshot = snapshot
                 {
                    for document in snapshot.documents
                    {
                        let rawdata = document.data();

                        let c1 = rawdata["Carrier"] as! Int
                        let c2 = CLLocationCoordinate2DMake(rawdata["Latitude"] as! CLLocationDegrees, rawdata["Longitude"] as! CLLocationDegrees) 
                        let c3 = rawdata["Spectrum"] as! Int
                        let c4 = rawdata["Date"] as! String
                        let c5 = rawdata["Alpha"] as! Int;
                        let c6 = rawdata["Color"] as! Int;

                        let tempdata : RealData = RealData(carrier: c1, coordinates: c2, spectrum: c3, date: c4, alpha: c5, color: c6);

                        self.realData.append(tempdata);
                    }
                 }

                if self.point.coordinate.latitude == 0 && self.point.coordinate.longitude == 0
                {
                    self.optionCoverage(op: 1);
                }
                else
                {
                    self.optionCoverage(op: 2);
                }
             }
         }
    }

    func putDataToFirestore(spd speed : Double, name crname:String, co coordinates:CLLocationCoordinate2D)
    {
        var carrier = -1;
        var spectrum = -1;
        var alp = -1;
        var col = -1;

        switch crname
        {
            case "NONE":
                break;

            case "Jio": carrier = 0;
            break;

            case "Airtel": carrier = 1;
            break;

            case "Vodafone": carrier = 2;
            break;

            case "BSNL": carrier = 3;
            break;

            default: break;
        }

        if(speed == 0.0)
        {
            spectrum = 0
            alp = 4;
            col = 5;
        }
        else if(speed > 0.0 && speed <= 0.1)
        {
            spectrum = 1;
            alp = 4;
            col = 4;
        }
        else if(speed > 0.1 && speed <= 8.0)
        {
            spectrum = 2;
            alp = 4;
            col = 3;
        }
        else if(speed > 8.0 && speed <= 15)
        {
            spectrum = 3;
            alp = 4;
            col = 2;
        }
        else if(speed > 15 && speed <= 100)
        {
            spectrum = 4;
            alp = 4;
            col = 1;
        }
        else if(speed > 100)
        {
            spectrum = 5;
            alp = 4;
            col = 0;
        }

        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy";
        let todaysdate = formatter.string(from: date)

        db.collection("UserData").document().setData(["Carrier":carrier, "Latitude":coordinates.latitude, "Longitude":coordinates.longitude, "Spectrum":spectrum, "Date":todaysdate, "Alpha":alp, "Color":col])
    }
}
