//
//  TrackerPalestraWidgetBundle.swift
//  TrackerPalestraWidget
//
//  Created by Tommaso Prandini on 28/01/26.
//

import WidgetKit
import SwiftUI

@main
struct TrackerPalestraWidgetBundle: WidgetBundle {
    var body: some Widget {
        TrackerPalestraWidget()
        TrackerPalestraWidgetControl()
        TrackerPalestraWidgetLiveActivity()
    }
}
