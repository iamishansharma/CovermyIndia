//
//  Data.swift
//  CovermyIndia
//
//  Created by Ishan Sharma on 20/08/20.
//  Copyright © 2020 Ishan Sharma. All rights reserved.
//

import UIKit
import MapmyIndiaAPIKit
import MapmyIndiaMaps

struct RealData
{
    var carrier : Int // 0 - Jio 1 - Airtel 2 - Vodafone Idea 3 - BSNL
    var coordinates : CLLocationCoordinate2D
    var spectrum : Int // 0 - No Signal 1 - 2G 2 - 3G 3 - 4G 4 - 4G+ 5 - 5G
    var date : String
    var alpha : Int // AlphaIndex
    var color : Int // ColorIndex

    // CSV order ->

    // Carrier    Latitude    Longitude    Spectrum    Date    Alpha    Color
}
