//
//  TrackerPalestraWidgetLiveActivity.swift
//  TrackerPalestraWidget
//
//  Created by Tommaso Prandini on 28/01/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TrackerPalestraWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TrackerPalestraWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrackerPalestraWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TrackerPalestraWidgetAttributes {
    fileprivate static var preview: TrackerPalestraWidgetAttributes {
        TrackerPalestraWidgetAttributes(name: "World")
    }
}

extension TrackerPalestraWidgetAttributes.ContentState {
    fileprivate static var smiley: TrackerPalestraWidgetAttributes.ContentState {
        TrackerPalestraWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TrackerPalestraWidgetAttributes.ContentState {
         TrackerPalestraWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TrackerPalestraWidgetAttributes.preview) {
   TrackerPalestraWidgetLiveActivity()
} contentStates: {
    TrackerPalestraWidgetAttributes.ContentState.smiley
    TrackerPalestraWidgetAttributes.ContentState.starEyes
}
