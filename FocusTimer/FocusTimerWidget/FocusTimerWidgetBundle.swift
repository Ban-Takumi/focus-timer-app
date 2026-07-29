//
//  FocusTimerWidgetBundle.swift
//  FocusTimerWidget
//
//  Created by Takumi Ban on 2026/06/25.
//

import WidgetKit
import SwiftUI

@main
struct FocusTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusTimerWidget()
        FocusGoalWidget()
    }
}
