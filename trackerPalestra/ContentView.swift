//
//  ContentView.swift
//  trackerPalestra
//
//  Created by Tommaso Prandini on 26/01/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel: MainViewModel

    var body: some View {
        TabView {
            HomeView() // la tua schermata principale
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            WorkoutCalendarView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Calendario", systemImage: "calendar")
                }
        }
    }
}
